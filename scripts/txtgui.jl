module ConclusionGui
    using CImGui
    using ImPlot
    using JSON
    using CImGui.CSyntax
    using CImGui.CSyntax.CStatic
    using CImGui: ImVec2
    using Gtk
    using Static

    include("../src/Renderer.jl")
    using .Renderer

    include("../src/parsetxt.jl")
    using .parsetxt

    mutable struct Global
        filename::String
        data::Vector{Any}
        is_file_loaded::Bool
        current_item::Vector{String}
        is_group_selected::Bool
        conclusion::String
        isfin::Bool
        final::String

        function Global()
            filename = ""
            data = []
            is_file_loaded = false
            current_item = []
            is_group_selected = false
            conclusion = "nothing"
            isfin = false
            final = ""

            new(filename, data, is_file_loaded, current_item, is_group_selected, conclusion, isfin, final)
        end
    end

    function ui(v::Global)
        function makeconclusion()
            conclusion = ""
            for i in 1:length(v.current_item)
                if v.current_item[i] != ""
                    conclusion *= v.current_item[i]*". "
                end
            end

            txt = split(conclusion, "")
            full = "    "
            k = 0
            for i in 1:length(txt)
                if k < 150
                    full *= txt[i]
                    k += 1
                else
                    if txt[i] == " "
                        full *= "\n"
                        full *= txt[i]
                        k = 0
                    else
                        full *= txt[i]
                        k += 1
                    end
                end
            end
            v.conclusion = full
        end

        CImGui.SetNextWindowPos(ImVec2(0,0))
        CImGui.SetNextWindowSize(ImVec2(2500,760))
        CImGui.Begin("Меню")
            if CImGui.Button("Загрузить файл")
                v.filename = open_dialog_native("Выберите файл", GtkNullContainer(), ("*.txt",))
                if isempty(v.filename)
                    warn_dialog("Файл не выбран!")
                    v.is_file_loaded = false
                else
                    v.data = parsetxt.my_txtparser(v.filename)

                    v.current_item = fill("", length(v.data[2])+1)
                    v.is_file_loaded = true
                end
            end

            if v.is_file_loaded
                if CImGui.BeginCombo("Группы ритмов", v.current_item[1])
                    for i in 1:length(v.data[1])
                        isselected = (v.data[1][i].name == v.current_item[1])
                        if CImGui.Selectable(v.data[1][i].name, isselected)
                            v.current_item[1] = v.data[1][i].name
                            v.is_group_selected = true

                            makeconclusion()
                            function foo()
                                @cstatic t="" begin
                                t = v.conclusion*"\0"^10000
                                end
                            end
                            v.final = foo()
                            
                            for j in 2:length(v.current_item)
                                needclean = false
                                for k in 1:length(v.data[2][j-1].children)
                                    if v.data[2][j-1].children[k].name == v.current_item[j]
                                        needclean = (typeof(findfirst(x -> x == v.data[1][i].code, v.data[2][j-1].children[k].ban)) != Nothing)
                                    end
                                end
                                if needclean
                                    v.current_item[j] = ""
                                end
                            end
                        end
                        if isselected
                            CImGui.SetItemDefaultFocus()
                        end
                    end
                    CImGui.EndCombo()
                end
            end

            if v.is_group_selected
                for i in 1:length(v.data[2])
                    if CImGui.BeginCombo(v.data[2][i].name, v.current_item[i+1])
                        for j in 1:length(v.data[2][i].children)
                            is_banned = false
                            for k in 1:length(v.data[1])
                                if v.data[1][k].name == v.current_item[1]
                                    is_banned = (typeof(findfirst(x -> x == v.data[1][k].code, v.data[2][i].children[j].ban)) != Nothing)
                                end
                            end
                            isselected = (v.data[2][i].children[j].name == v.current_item[i+1])
                            if !is_banned
                                if CImGui.Selectable(v.data[2][i].children[j].name, isselected)
                                    v.current_item[i+1] = v.data[2][i].children[j].name
                                    
                                    makeconclusion()
                                    function foo()
                                        @cstatic t="" begin
                                        t = v.conclusion*"\0"^10000
                                        end
                                    end
                                    v.final = foo()

                                end
                                if isselected
                                    CImGui.SetItemDefaultFocus()
                                end
                            end
                        end
                        CImGui.EndCombo()
                    end
                end
            end
        CImGui.End()

        CImGui.SetNextWindowPos(ImVec2(0, 765))
        CImGui.SetNextWindowSize(ImVec2(2500,650))
        CImGui.Begin("Заключение")
            CImGui.BulletText("Поле с заключением доступно для редактирования.")
            CImGui.BulletText("Если после редактирования заключения выбор фраз будет изменён, результаты корректировки вручную будут утеряны.")
            CImGui.SameLine(2100)
            if CImGui.Button("Сохранить заключение")
                fname=save_dialog_native("Select file", GtkNullContainer(), ("*.txt",))
                write(fname, replace(v.final, "\0" => "" ))
            end

            CImGui.InputTextMultiline("##2", v.final, 10000, ImVec2(-1.0, CImGui.GetTextLineHeight() * 16), CImGui.ImGuiInputTextFlags_AllowTabInput)

        CImGui.End()

    end

    function show_gui()
        state = Global();
        Renderer.render(
            ()->ui(state),
            width=2500,
            height=1400,
            title="",
            hotloading=true
        )
        return state
    end

    # show_gui();
end