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
    history_filename::String
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
    is_text_hovered::Bool
    tab_item::Int64
    all_history::String
    combo_item::String
    isselected::Bool

    function Global()
        filename = "configs/newtxt.txt"
        history_filename = "configs/history.txt"
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
        is_text_hovered = false
        tab_item = 1
        all_history = ""
        combo_item = ""

        new(filename, history_filename, data, is_file_loaded, current_item, 
        is_rhytm_selected, final, newphrase, collapsingstate, conclusion, 
        append, bans, is_text_hovered, tab_item, all_history, combo_item)
    end
end

function CH(v::Global, i::Int64) # Создание каждого раздела с выпадающим списком
    if CImGui.CollapsingHeader(v.data[i].name)
        setcollapsing(v, i)

        if typeof(findfirst(x -> x == true, v.current_item[i])) != Nothing
            CImGui.PushID(v.data[i].name)
                if CImGui.SmallButton("очистить поле")
                    for k in 1:length(v.current_item[i])
                        if v.current_item[i][k]
                            for t in 1:length(v.bans)
                                if v.bans[t] == v.data[i].children[t].will_ban
                                    v.bans[t] = "remove"
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
                    if is_banned break end
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

function ConclusionWindow(v::Global, s::Renderer.GR) # Окно с историей и заключением
    CImGui.SetNextWindowPos(ImVec2(0, s.h/1.75))
    CImGui.SetNextWindowSize(ImVec2(s.w, s.h/1.75))
    CImGui.Begin("Заключение")

        if CImGui.BeginTabBar("MyTabBar", CImGui.ImGuiTabBarFlags_None)
            if CImGui.BeginTabItem("Заключение")

                v.tab_item = 1

                CImGui.EndTabItem()
            end
            if CImGui.BeginTabItem("История")

                v.tab_item = 2

                CImGui.EndTabItem()
            end
            CImGui.EndTabBar()
        end

        CImGui.SameLine(s.w - 750)
        ShowHelpMarker("1. Сформируйте заключение из набора фраз, представленных в меню (на этом этапе заключение динамически изменяется)."*
                    "\n"*"Если необходимо дополнить заключение вручную:"*
                    "\n"*"   1. Проверьте выбр фраз, т.к. после ручной коррекции возможно будет только удаление фраз вручную."*
                    "\n"*"   2. Дополните заключение, вводя текст вручную."*
                    "\n"*"Если после ручной коррекции выбр фраз из меню будет изменен, динамически изменяемый блок дополнительных фраз будет добавлен в конец заключения.")
     
        CImGui.SameLine(s.w - 600)
        if CImGui.Button("Сохранить в историю")
            history = "\n" * replace(v.final, "\0" => "" ) * "\n" * "_"^100 * "\n"
            open(v.history_filename, "a+") do io
                write(io, history)
            end
            v.all_history = parsetxt2.my_txtparser2(v.history_filename,"history")   
        end

        CImGui.SameLine(s.w - 300)
        if CImGui.Button("Копировать заключение")
            clipboard(replace(v.final, "\0" => "", "\n" => "" ))
        end

        if v.tab_item == 2
            CImGui.BeginChild("txt2", ImVec2(CImGui.GetWindowContentRegionWidth(), 600), false)
                CImGui.InputTextMultiline("##2", v.all_history, length(v.all_history)+1, ImVec2(-1.0, CImGui.GetTextLineHeight() * 20), CImGui.ImGuiInputTextFlags_ReadOnly)
            CImGui.EndChild()
        elseif v.tab_item == 1
            CImGui.BeginChild("txt1", ImVec2(CImGui.GetWindowContentRegionWidth(), 600), false)
                CImGui.InputTextMultiline("##1", v.final, 10000, ImVec2(-1.0, CImGui.GetTextLineHeight() * 20), CImGui.ImGuiInputTextFlags_AllowTabInput)
                if CImGui.IsItemClicked()
                    print("yo")
                    v.is_text_hovered = true
                    v.collapsingstate = fill(false, length(v.collapsingstate))
                    v.current_item = []
                    for i in 1:length(v.data)
                        push!(v.current_item, fill(false, length(v.data[i].children)))
                    end
                end
            CImGui.EndChild()
        end

    CImGui.End()
end

function RewriteTXT(v::Global)
end

# function DeletePhraseButton(v::Global)
#     CImGui.SameLine()
#     if CImGui.Button("Удалить фразу")
#         for i in 1:length(v.data[length(v.data)].children)
#             if v.data[length(v.data)].children[i].name == v.combo_item
#                 filter!(x -> x v.data[length(v.data)].children[i].name, a)
#                 break
#             end
#         end
#     end
# end

function AddUserPhrase(v::Global, phrase::String)
    if CImGui.Button("Добавить фразу")
        v.newphrase = phrase
        open(v.filename, "a+") do io
            write(io, "\n"*"    "*replace(v.newphrase, "\0" => ""))
        end   
        phrase = "\0"^500
        warn_dialog("Новая фраза добавлена в раздел `Пользовательские фразы'.")

        v.data = parsetxt2.my_txtparser2(v.filename, "data")
        v.current_item = []
        for i in 1:length(v.data)
            push!(v.current_item, fill(false, length(v.data[i].children)))
        end
    end
end

function UserPhraseCombo(v::Global)
    CImGui.NewLine()
    CImGui.Text("Выберите фразу для удаления:")
    if CImGui.BeginCombo("##uf", v.combo_item)
        for i in 1:length(v.data[length(v.data)].children)
            isselected = (v.data[length(v.data)].children[i].name == v.combo_item)
            if CImGui.Selectable(v.data[length(v.data)].children[i].name, isselected)
                v.combo_item = v.data[length(v.data)].children[i].name
            end
        end
        CImGui.EndCombo()
    end

    DeletePhraseButton(v)
end

function UserPhraseInput(v::Global)
    @cstatic phrase="\0"^500 begin
            CImGui.Text("Введите новую фразу: ")
            CImGui.InputText("##3", phrase, length(phrase))
            CImGui.SameLine()

            AddUserPhrase(v, phrase)
        end
end

function AddPhrase(v::Global) # Раздел добавления фраз
    CImGui.Separator()
    if CImGui.TreeNode("Поле добавления пользовательских фраз")
        UserPhraseInput(v)
        UserPhraseCombo(v)
    end
end

function CleanButton(v::Global) # Кнопка полной очистки заключения
    if CImGui.Button("Очистить выбор (новое заключение)")
        v.is_rhytm_selected = false
        v.final = ""
        v.conclusion = ""
        v.append = false
        v.is_text_hovered = false
        v.current_item = []
        for i in 1:length(v.data)
            push!(v.current_item, fill(false, length(v.data[i].children)))
        end
    end
end

function Load(v::Global) # Загрузка файла
    if !v.is_file_loaded
        v.data = parsetxt2.my_txtparser2(v.filename, "data")
        v.current_item = []
        for i in 1:length(v.data)
            push!(v.current_item, fill(false, length(v.data[i].children)))
        end
        v.collapsingstate = fill(false, length(v.current_item))
        v.is_file_loaded = true

        v.all_history = parsetxt2.my_txtparser2(v.history_filename, "history")
    end
end

function Menu(v::Global, s::Renderer.GR) # Окно меню
    CImGui.SetNextWindowPos(ImVec2(0,0))
    CImGui.SetNextWindowSize(ImVec2(s.w, s.h/1.75))
    CImGui.Begin("Меню")
        Load(v)

        if v.is_file_loaded
            CImGui.SameLine(s.w-450)
            CleanButton(v)

            for i in 1:length(v.data)
                CImGui.SetNextTreeNodeOpen(v.collapsingstate[i])
                CH(v, i)
            end

            AddPhrase(v)

        end

    CImGui.End()
end

function bancheck(v::Global, i::Int64, j::Int64) # Отмена выбора уже выбранных забаненных фраз
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

function ShowHelpMarker(desc) # Справка
    CImGui.TextDisabled("Справка")
    if CImGui.IsItemHovered()
        CImGui.BeginTooltip()
        CImGui.PushTextWrapPos(CImGui.GetFontSize() * 100.0)
        CImGui.TextUnformatted(desc)
        CImGui.PopTextWrapPos()
        CImGui.EndTooltip()
    end
end

function foo(full::String) # Текст
    @cstatic t="" begin
    t = full*"\0"^(10000-length(full))
    end
end

function makeconclusion(v::Global, i_curr::Int64, j_curr::Int64) # Создание текста заключения

    if !v.append
        v.append = v.is_text_hovered
        if v.append
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
                    Y = lowercasefirst(v.data[i].children[j].name)
                end
            end
        elseif i == 6
            for j in 1:length(v.current_item[i])
                if v.current_item[i][j]
                    X *= v.data[i].children[j].name
                end
            end
            if Y != " " && X != "В отведениях "
                conclusion *= X*" регистрируется "*Y*". "
            elseif Y != " " && X == "В отведениях "
                Y = "Регистрируется "*Y
                conclusion *= Y*". "
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
        full = replace(v.conclusion, "\0" => "") * "\n" * full
    elseif !v.append && i_curr != 1
        v.conclusion = conclusion
        full = full*"\n"*"    "
    elseif !v.append && i_curr == 1
        v.conclusion = conclusion
    end

    final = foo(full)
    
    return final
end

function setcollapsing(v::Global, i::Int) # Закрытие всех полей меню, кроме выбранного
    for j in 1:length(v.collapsingstate)
        if j == i == 1
            v.collapsingstate[j] = true
        elseif j == i == 6 && sizeof(findall(v.current_item[5])) == 0
            v.collapsingstate[j] = false
        elseif j == i != 1 && sizeof(findall(v.current_item[1])) != 0
            v.collapsingstate[j] = true
        elseif j == i != 1 && sizeof(findall(v.current_item[1])) == 0
            v.collapsingstate[j] = false
        else
            v.collapsingstate[j] = false
        end
    end
end

function ui(v::Global, s::Renderer.GR) # Главная функция
    CImGui.StyleColorsLight()
    Menu(v, s)
    ConclusionWindow(v, s)
end

function show_gui()
    state = Global();
    size = Renderer.GR();
    Renderer.render(
        ()->ui(state, size),
        width=1700,
        height=1750,
        title="",
        v = size
    )
end

show_gui();