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

include("../src/newparser.jl")
using .parsetxt2

mutable struct Global
    filename::String
    data::Vector{Any}
    is_file_loaded::Bool
    current_item::Vector{Vector{Bool}}
    is_rhytm_selected::Bool
    final::String
    newphrase::String
    collapsingstate::Vector{Bool}
    conclusion::String
    append::Bool
    bans::Vector{String}
    history::String

    function Global()
        filename = ""
        data = []
        is_file_loaded = false
        current_item = []
        is_rhytm_selected = false
        final = ""
        newphrase = ""
        collapsingstate = []
        conclusion = ""
        append = false
        bans = []
        history = ""

        new(filename, data, is_file_loaded, current_item, is_rhytm_selected, final, newphrase, collapsingstate, conclusion, append, bans, history)
    end
end
function bancheck(v::Global, i::Int64, j::Int64)
    for k in 1:length(v.current_item)
        for t in 1:length(v.current_item[k])
            if v.current_item[k][t]
                if k != i || t != j
                    for p in 1:length(v.bans)
                        if typeof(findfirst(x -> x == v.bans[p], v.data[k].children[t].banned_by)) != Nothing
                            v.current_item[k][t] = false
                        end
                    end
                end
            end
        end
    end
end

function ShowHelpMarker(desc)
    CImGui.TextDisabled("Справка")
    if CImGui.IsItemHovered()
        CImGui.BeginTooltip()
        CImGui.PushTextWrapPos(CImGui.GetFontSize() * 100.0)
        CImGui.TextUnformatted(desc)
        CImGui.PopTextWrapPos()
        CImGui.EndTooltip()
    end
end

function foo(full::String)
    @cstatic t="" begin
    t = full*"\0"^(10000-length(full))
    end
end

function makeconclusion(v::Global, i_curr::Int64, j_curr::Int64)
    if !v.append
        v.append = (replace(v.final, "\0" => "", "\n" => "", "    " => "") != v.conclusion)
        if v.append
            for i in 1:length(v.current_item)
                for j in 1:length(v.current_item[i])
                    if i != i_curr | j != j_curr
                        v.current_item[i][j] = false
                    end
                end
            end
            v.conclusion = v.final
        end
    end

    conclusion = " "
    X = "В отведениях "
    Y = " "
    for i in 1:length(v.current_item)
        if  i == 5
            for j in 1:length(v.current_item[i])
                if v.current_item[i][j]
                    X *= v.data[i].children[j].name
                end
            end
        elseif i == 6
            for j in 1:length(v.current_item[i])
                if v.current_item[i][j]
                    Y = v.data[i].children[j].name
                end
            end
            if Y != " " && X != "В отведениях "
                conclusion *= X*" регистрируется "*Y*". "
            elseif Y != " " && X == "В отведениях "
                Y = "Регистрируется "*Y
                conclusion *= Y*". "
            elseif Y == " " && X == "В отведениях "
                conclusion *= ". "
            end
        else
            for j in 1:length(v.current_item[i])
                if v.current_item[i][j]
                    conclusion *= v.data[i].children[j].name*". "
                end
            end
        end
    end

    txt = split(conclusion, "")
    full = "    "
    k = 0
    for i in 1:lastindex(txt)
        if k < 100
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

    if v.append
        full = replace(v.conclusion, "\0" => "") * "\n" *full
    elseif !v.append && i_curr != 1
        v.conclusion = conclusion
        full = full*"\n"*"    "
    elseif !v.append && i_curr == 1
        v.conclusion = conclusion
    end

    final = foo(full)
    
    return final
end

function setcollapsing(v::Global, i::Int)
    for j in 1:length(v.collapsingstate)
        if j == i
            v.collapsingstate[j] = true
        else
            v.collapsingstate[j] = false
        end
    end
end

function ui(v::Global)
    CImGui.StyleColorsLight()

    CImGui.SetNextWindowPos(ImVec2(0,0))
    CImGui.SetNextWindowSize(ImVec2(3840,955))
    CImGui.Begin("Меню")
        if CImGui.Button("Загрузить файл")
            v.filename = open_dialog_native("Выберите файл", GtkNullContainer(), ("*.txt",))
            if isempty(v.filename)
                warn_dialog("Файл не выбран!")
                v.is_file_loaded = false
            else
                v.data = parsetxt2.my_txtparser2(v.filename)
                v.current_item = []
                for i in 1:length(v.data)
                    push!(v.current_item, fill(false, length(v.data[i].children)))
                end
                v.collapsingstate = fill(false, length(v.current_item))
                v.is_file_loaded = true
            end
        end

        if v.is_file_loaded
            CImGui.SameLine(2450)
            if CImGui.Button("Очистить выбор (новое заключение)")
                v.is_rhytm_selected = false
                v.final = ""
                v.conclusion = ""
                v.current_item = []
                for i in 1:length(v.data)
                    push!(v.current_item, fill(false, length(v.data[i].children)))
                end
            end

            for i in 1:length(v.data)
                CImGui.SetNextTreeNodeOpen(v.collapsingstate[i])
                if CImGui.CollapsingHeader(v.data[i].name)
                    setcollapsing(v, i)

                    if typeof(findfirst(x -> x == true, v.current_item[i])) != Nothing
                        CImGui.PushID(v.data[i].name)
                            if CImGui.SmallButton("очистить поле")
                                for k in 1:length(v.current_item[i])
                                    if v.current_item[i][k]
                                        for k in 1:length(v.bans)
                                            if v.bans[k] == v.data[i].children[k].will_ban
                                                v.bans[k] = "remove"
                                                break
                                            end
                                        end
                                        filter!(e -> e != "remove", v.bans)
                                        v.current_item[i][k] = false
                                    end
                                end
                                v.final = makeconclusion(v, 0, 0)
                            end
                        CImGui.PopID()
                    end

                    CImGui.BeginChild(i, ImVec2(CImGui.GetWindowContentRegionWidth()*0.6, CImGui.GetTextLineHeight() * 5), false, CImGui.ImGuiWindowFlags_HorizontalScrollbar)
                        for j in 1:length(v.data[i].children)
                            is_banned = false
                            for k in 1:length(v.bans)
                                is_banned = (typeof(findfirst(x -> x == v.bans[k], v.data[i].children[j].banned_by)) != Nothing)
                                break
                            end

                            if !is_banned
                                if CImGui.Selectable(v.data[i].children[j].name, pointer(v.current_item[i])+(j-1)*sizeof(Bool))
                                    if v.current_item[i][j]
                                        if v.data[i].children[j].will_ban != ""
                                            push!(v.bans, v.data[i].children[j].will_ban)
                                        end
                                    else
                                        for k in 1:length(v.bans)
                                            if v.bans[k] == v.data[i].children[j].will_ban
                                                v.bans[k] = "remove"
                                                break
                                            end
                                        end
                                        filter!(e -> e != "remove", v.bans)
                                    end
                                    bancheck(v,i,j)
                                    v.final = makeconclusion(v, i, j)
                                end
                            end
                        end
                    CImGui.EndChild()
                end
            end

            CImGui.Separator()
            if CImGui.TreeNode("Поле добавления пользовательских фраз")
                @cstatic phrase="\0"^500 begin
                    @cstatic selection = fill(false, 9) begin
                        CImGui.Text("Введите новую фразу: ")
                        CImGui.InputText("##1", phrase, length(phrase))

                        CImGui.SameLine()
                        if CImGui.Button("Добавить фразу")
                            code = ["A", "B", "C", "D", "E", "F", "G", "H", "I"]
                            for i in 1:lastindex(selection)
                                if !selection[i]
                                    code[i] = "remove"
                                end
                            end
                            filter!(e -> e! = "remove", code)
                            if length(code) == 0
                                ban = ""
                            elseif length(code) == 1
                                ban = code[1]
                            else
                                ban = code[1]
                                for i in 2:lastindex(code)
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
                            window_flags = gCImGui.ImGuiWindowFlags_HorizontalScrollbar
                            CImGui.BeginChild("Child1", ImVec2(CImGui.GetWindowContentReionWidth() * 0.4, 100), false, window_flags)
                                for i in 1:length(v.data[1])
                                    CImGui.Selectable(v.data[1][i].name, pointer(selection)+(i-1)*sizeof(Bool))
                                end
                            CImGui.EndChild()
                        end
                    end
                end
            end
        end

    CImGui.End()

    CImGui.SetNextWindowPos(ImVec2(0, 950))
    CImGui.SetNextWindowSize(ImVec2(3840,720))
    CImGui.Begin("Заключение")

        CImGui.SameLine(CImGui.GetWindowContentRegionWidth() * 0.17)
        CImGui.Text("История")

        CImGui.SameLine(CImGui.GetWindowContentRegionWidth() * 0.54)
        CImGui.Text("Заключение")

        CImGui.SameLine(CImGui.GetWindowContentRegionWidth() * 0.37+30)
        ShowHelpMarker("1. Сформируйте заключение из набора фраз, представленных в меню (на этом этапе заключение динамически изменяется)."*
                    "\n"*"Если необходимо дополнить заключение вручную:"*
                    "\n"*"   1. Проверьте выбр фраз, т.к. после ручной коррекции возможно будет только удаление фраз вручную."*
                    "\n"*"   2. Дополните заключение, вводя текст вручную."*
                    "\n"*"Если после ручной коррекции выбр фраз из меню будет изменен, динамически изменяемый блок дополнительных фраз будет добавлен в конец заключения.")
     

        CImGui.SameLine(2550)
        if CImGui.Button("Копировать заключение")
            clipboard(replace(v.final, "\0" => "", "\n" => "" ))
            v.history *= "\n" * replace(v.final, "\0" => "" ) * "_"^100 * "\n"
        end

        CImGui.BeginChild("txt2", ImVec2(CImGui.GetWindowContentRegionWidth() * 0.37, 600), false)
            CImGui.InputTextMultiline("##2", v.history, length(v.history)+1, ImVec2(-1.0, CImGui.GetTextLineHeight() * 20), CImGui.ImGuiInputTextFlags_AllowTabInput)
        CImGui.EndChild()

        CImGui.SameLine()
        CImGui.BeginChild("txt1", ImVec2(CImGui.GetWindowContentRegionWidth() * 0.37, 600), false)
            CImGui.InputTextMultiline("##1", v.final, 10000, ImVec2(-1.0, CImGui.GetTextLineHeight() * 20), CImGui.ImGuiInputTextFlags_AllowTabInput)
        CImGui.EndChild()
    CImGui.End()

end

function show_gui()
    state = Global();
    Renderer.render(
        ()->ui(state),
        width=500,
        height=500,
        title=""
    )
end

show_gui();