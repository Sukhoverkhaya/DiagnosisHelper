# module ConclusionGui
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

# include(joinpath(pathof(CImGui), "..", "..", "demo", "demo.jl"))

include("../src/parsetxt.jl")
using .parsetxt

struct Node
    name::String
    ban::Vector{String}
end

mutable struct Global
    filename::String
    data::Vector{Any}
    is_file_loaded::Bool
    current_item::Vector{Vector{Bool}}
    is_group_selected::Bool
    final::String
    newphrase::String

    function Global()
        filename = ""
        data = []
        is_file_loaded = false
        current_item = []
        is_group_selected = false
        final = ""
        newphrase = ""

        new(filename, data, is_file_loaded, current_item, is_group_selected, final, newphrase)
    end
end

function foo(full::String)
    @cstatic t="" begin
    t = full*"\0"^(10000-length(full))
    end
end

function makeconclusion(v::Global)
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

    final = foo(full)

    return final
end

function ui(v::Global)
    CImGui.StyleColorsLight()

    CImGui.SetNextWindowPos(ImVec2(0,0))
    CImGui.SetNextWindowSize(ImVec2(2100,955))
    CImGui.Begin("Меню")
        if CImGui.Button("Загрузить файл")
            v.filename = open_dialog_native("Выберите файл", GtkNullContainer(), ("*.txt",))
            if isempty(v.filename)
                warn_dialog("Файл не выбран!")
                v.is_file_loaded = false
            else
                v.data = parsetxt.my_txtparser(v.filename)
                v.current_item = []
                push!(v.current_item, fill(false, length(v.data[1])))
                for i in 1:length(v.data[2])
                    push!(v.current_item, fill(false, length(v.data[2][i].children)))
                end
                v.is_file_loaded = true
            end
        end

        if v.is_file_loaded
            #### перенести на плюсы
            CImGui.SameLine(1664)
            if CImGui.Button("Очистить выбор (новое заключение)")
                # v.current_item = fill("", length(v.data[2])+1)
                v.is_group_selected = false
                v.final = ""
            end
            ####
            if CImGui.CollapsingHeader("Группа ритмов")
                CImGui.BeginChild(1, ImVec2(CImGui.GetWindowContentRegionWidth(), 100), false, CImGui.ImGuiWindowFlags_HorizontalScrollbar)
                    for i in 1:length(v.data[1])-3
                            if CImGui.Selectable(v.data[1][i].name, pointer(v.current_item[1])+(i-1)*sizeof(Bool))
                                v.is_group_selected = true
                                for j in 1:length(v.current_item[1])
                                    if j != i
                                        v.current_item[1][j] = false
                                    end
                                end
                                ### сделать функцией, чтобы можно было юзать в двух местах (для тех трёх диагнозов)
                                # for j in 2:length(v.current_item)
                                #     needclean = false
                                #     for k in 1:length(v.data[2][j-1].children)
                                #         if v.data[2][j-1].children[k].name == v.current_item[j]
                                #             needclean = (typeof(findfirst(x -> x == v.data[1][i].code, v.data[2][j-1].children[k].ban)) != Nothing)
                                #         end
                                #     end
                                #     if needclean
                                #         v.current_item[j] = ""
                                #     end
                                # end
                                # v.final = makeconclusion(v)
                            end
                        if v.current_item[1][i]
                            CImGui.SetItemDefaultFocus()
                        end
                    end
                CImGui.EndChild()
            end
        end

        if v.is_group_selected
            for i in 1:length(v.data[2])
                    if CImGui.CollapsingHeader(v.data[2][i].name)
                        #### перенести на плюсы
                        if typeof(findfirst(x -> x == true, v.current_item[i+1])) != Nothing
                            CImGui.PushID(v.data[2][i].name)
                                if CImGui.SmallButton("очистить поле")
                                    v.current_item[i+1] = fill(false, length(v.current_item[i+1]))
                                end
                            CImGui.PopID()
                        end
                        ####
                        CImGui.BeginChild(i+1, ImVec2(CImGui.GetWindowContentRegionWidth(), 100), false, CImGui.ImGuiWindowFlags_HorizontalScrollbar)
                            for j in 1:length(v.data[2][i].children)
                                not_banned = false
                                for k in 1:length(v.current_item[1])
                                    if v.current_item[1][k]
                                        not_banned = (typeof(findfirst(x -> x == v.data[1][k].code, v.data[2][i].children[j].ban)) != Nothing)
                                    end
                                end
                                
                                if !not_banned
                                    if CImGui.Selectable(v.data[2][i].children[j].name, pointer(v.current_item[i+1])+(j-1)*sizeof(Bool))
                                        # v.final = makeconclusion(v)
                                        for k in length(v.data[1]):-1:length(v.data[1])-2
                                            if v.data[2][i].children[j].name == v.data[1][k].name
                                                v.current_item[1][k] = v.current_item[i+1][j]
                                            end
                                        end
                                    end
                                    if v.current_item[i+1][j]
                                        CImGui.SetItemDefaultFocus()
                                    end
                                end
                            end
                        CImGui.EndChild()
                    end
            end
        end

        #### перенести на плюсы
        if v.is_file_loaded
            CImGui.Separator()
            if CImGui.TreeNode("Поле добавления пользовательских фраз")
                @cstatic phrase="\0"^500 begin
                    @cstatic selection = fill(false, 9) begin
                        CImGui.Text("Введите новую фразу: ")
                        CImGui.InputText("##1", phrase, length(phrase))

                        CImGui.SameLine()
                        if CImGui.Button("Добавить фразу")
                            code = ["A", "B", "C", "D", "E", "F", "G", "H", "I"]
                            for i in 1:length(selection)
                                if !selection[i]
                                    code[i] = "remove"
                                end
                            end
                            filter!(e->e≠"remove", code)
                            if length(code) == 0
                                ban = ""
                            elseif length(code) == 1
                                ban = code[1]
                            else
                                ban = code[1]
                                for i in 2:length(code)
                                    ban *= ", "*code[i]
                                end
                            end
                            if ban == ""
                                v.newphrase = phrase
                            else
                                v.newphrase = phrase*" : "*ban
                            end

                            open(v.filename, "a+") do io
                                write(io, "\n"*"    "*replace(v.newphrase, "\0" => ""))
                            end   
                            phrase = "\0"^500
                            selection = fill(false, 9)
                            warn_dialog("Новая фраза добавлена в раздел `Пользовательские фразы'.")

                            v.data = parsetxt.my_txtparser(v.filename)
                        end

                        if CImGui.TreeNode("Выберите группы ритмов, для которых фраза будет запрещена:")
                            window_flags = CImGui.ImGuiWindowFlags_HorizontalScrollbar
                            CImGui.BeginChild("Child1", ImVec2(CImGui.GetWindowContentRegionWidth() * 0.4, 100), false, window_flags)
                                for i in 1:length(v.data[1])
                                    CImGui.Selectable(v.data[1][i].name, pointer(selection)+(i-1)*sizeof(Bool))
                                end
                            CImGui.EndChild()
                        end
                    end
                end
            end
        end
        ####

    CImGui.End()

    CImGui.SetNextWindowPos(ImVec2(0, 960))
    CImGui.SetNextWindowSize(ImVec2(2100,650))
    CImGui.Begin("Заключение")
        CImGui.BulletText("Поле с заключением доступно для редактирования.")
        CImGui.BulletText("Если после редактирования заключения выбор фраз будет изменён, результаты корректировки вручную будут утеряны.")
        CImGui.SameLine(1816)
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
        width=2100,
        height=1570,
        title=""
    )
end

show_gui();
# end