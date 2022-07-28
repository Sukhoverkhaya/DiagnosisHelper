using CImGui
using ImPlot
using JSON
using CImGui.CSyntax
using CImGui.CSyntax.CStatic
using CImGui: ImVec2
using Gtk

include(joinpath(pathof(ImPlot),"..","..","demo","Renderer.jl"))
using .Renderer

# include(joinpath(pathof(CImGui), "..", "..", "demo", "demo.jl"))

mutable struct Vars
    names::Vector{Any}
    check::Vector{Vector{Int64}}
    conclusion::String
    
    function Vars()
        names = []
        check = []
        conclusion = ""

        new(names, check, conclusion)
    end
end

mutable struct Vrs
    filename::String
    data::Dict{String, Any}
    newname::String
    newdiagnosis::String
    newban::Vector{Any}
    is_file_loaded::Bool
    current_item::Vector{String}
    buf::Vector{String}
    all_phrases::Vector{Any}
    selected::Vector{Bool}

    function Vrs()
        filename = ""
        data = Dict("" => "")
        newname = ""
        newdiagnosis = ""
        newban = [""]
        is_file_loaded = false
        current_item = fill("",3)
        buf = fill("",3)
        all_phrases = []
        selected = []

        new(filename, data, newname, newdiagnosis, newban, is_file_loaded, current_item, buf, all_phrases, selected)
    end
end

function all_diagnoses(data)
    diagnoses = []
    names = data["groupnames"]
    for i in 1:length(names)
        collect = data[names[i]]
        for j in 1:length(collect)
            push!(diagnoses, collect[j]["diagnosis"])
        end
    end

    return diagnoses
end

function ui(v::Vars, p::Vrs)
    CImGui.Begin("Menu")

    if CImGui.Button("Load file.json")
        p.filename = open_dialog_native("Select file", GtkNullContainer(), ("*.json",))
        if p.filename != ""
            p.data = JSON.parsefile(p.filename, use_mmap=false)

            v.names = p.data["groupnames"]
            v.check = []
            for i in 1:length(v.names)
                n=length(p.data[v.names[i]])
                push!(v.check, fill(0,n))
            end

            p.all_phrases = all_diagnoses(p.data)
            p.is_file_loaded = true
        else
            warn_dialog("File was not selected!")
            p.is_file_loaded = false
        end
    end

    if p.is_file_loaded

        if CImGui.TreeNode(v.names[1])
            groupdata=p.data[v.names[1]]
            for j in 1:length(groupdata)
                CImGui.RadioButton(groupdata[j]["diagnosis"], v.check[1][1] == j) && (v.check[1][1] = j;)
            end
        end

        is_selected = false
        for i in 1:length(v.check[1])
            if v.check[1][i]!=0
                is_selected=true
            end
        end

        if is_selected
            for i in 2:length(v.names)
                if CImGui.TreeNode(v.names[i])
                    groupdata=p.data[v.names[i]]
                    for j in 1:length(groupdata)

                        is_banned = false
                        for t in 1:length(v.names)
                            for u in 1:length(v.check[t])
                                if v.check[t][u]!=0
                                    banned = p.data[v.names[t]][v.check[t][u]]["ban"]
                                    for q in 1:length(banned)      # проверка только по выбранной группе ритмов - нужно добавить такую же по всем выбранным категориям
                                        if groupdata[j]["diagnosis"] == banned[q]
                                            is_banned=true
                                            
                                        end
                                    end
                                end
                            end
                        end

                        if is_banned == false
                            CImGui.RadioButton(groupdata[j]["diagnosis"], v.check[i][j] == j) && (v.check[i][j] = j;)
                            if v.check[i][j] != 0
                                CImGui.PushID(groupdata[j]["diagnosis"])
                                CImGui.SameLine()
                                if CImGui.Button("cansel")
                                    v.check[i][j]=0
                                end
                                CImGui.PopID()
                            end
                        else
                            v.check[i][j] = 0
                        end

                    end
                end
            end
        end

     CImGui.End
    
     CImGui.Begin("Conclusion")
        CImGui.SameLine(600)
        if CImGui.Button("Save conclusion")
            fname=save_dialog_native("Select file", GtkNullContainer(), ("*.doc",))
            write(fname,v.conclusion)
        end

        @cstatic read_only=false (text="\0"^(1024*16-249)) begin
            flags = CImGui.ImGuiInputTextFlags_AllowTabInput
            txt=" "
            for i in 1:length(v.names)
                for j in 1:length(v.check[i])
                    if v.check[i][j]!=0
                        txt*=p.data[v.names[i]][v.check[i][j]]["diagnosis"]*". "
                    end
                end
            end
            CImGui.InputTextMultiline("##source", txt*text, length(text), ImVec2(-1.0, CImGui.GetTextLineHeight() * 16), flags)

            v.conclusion=txt
        end
     CImGui.End

     ################################################3
     CImGui.Begin("Change list")

        # if CImGui.Button("Load file.json")
        #     p.filename = open_dialog_native("Select file", GtkNullContainer(), ("*.json",))
        #     if p.filename != ""
        #         p.data = JSON.parsefile(p.filename, use_mmap=false)
        #         p.all_phrases = all_diagnoses(p.data)
        #         p.is_file_loaded = true
        #     else
        #         warn_dialog("File was not selected!")
        #         p.is_file_loaded = false
        #     end
        # end

        CImGui.SameLine(575)
        if CImGui.Button("Add changes to file.json")
            can_whrite = true
            # сделать возможность добавления вектора из забаненных фраз!!!!!!!!!!!
            if p.newname != "" && p.newdiagnosis != "" && p.newban != "" 

                names = p.data["groupnames"]
                is_new=true

                for i in 1:length(names)
                    if p.newname == names[i]
                        is_new = false
                    end
                end

                if is_new
                    entry = Dict(p.newname => ([Dict("diagnosis" => p.newdiagnosis, "ban" => p.newban)]))
                    newdata = merge(p.data, entry)
                    push!(newdata["groupnames"], p.newname)
                else
                    newdata = p.data
                    group = newdata[p.newname]

                    is_new_diagnosis = true
                    for i in 1:length(group)
                        if group[i]["diagnosis"] == p.newdiagnosis
                            is_new_diagnosis = false
                        end
                    end

                    if is_new_diagnosis
                        push!(newdata[p.newname], Dict("diagnosis" => p.newdiagnosis, "ban" => p.newban))
                    else
                        warn_dialog("The entered phrase is already in this section")
                        can_whrite = false
                    end
                end

                if can_whrite
                    open(p.filename, "w") do f
                        JSON.print(f, newdata)
                    end

                    p.data = JSON.parsefile(p.filename, use_mmap=false)
                    p.all_phrases = all_diagnoses(p.data)
                    p.is_file_loaded = true

                    v.names = p.data["groupnames"]
                    v.check = []
                    for i in 1:length(v.names)
                        n=length(p.data[v.names[i]])
                        push!(v.check, fill(0,n))
                    end

                end

                info_dialog("Changes were added")

            end
        end

        if p.is_file_loaded

            ###############################################################
            function text_and_combo(title::String, name::String, num::Int64, items::Vector{Any})
                CImGui.Text("Enter a new"*name*"or select an existing one")
            
                @cstatic str0 = "Write here"*"\0"^50 begin
                    CImGui.InputText("", str0, length(str0))
                    if p.buf[num] != p.current_item[num]
                        str0 = p.current_item[num]*"\0"^50
                        p.buf[num] = p.current_item[num]
                    end
                    p.newname = replace(str0 ,"\0" => "")
                end
            
                CImGui.SameLine()
                @cstatic item_current="" begin
                    if CImGui.BeginCombo(title, item_current, CImGui.ImGuiComboFlags_NoPreview)
                        for n = 0:length(items)-1
                            is_selected = item_current == items[n+1]
                            CImGui.Selectable(items[n+1], is_selected) && (item_current = items[n+1];)
                            is_selected && CImGui.SetItemDefaultFocus()
                            p.current_item[num] = item_current
                        end
                        CImGui.EndCombo()
                    end
                end
            end
            
            ####################################################

            text_and_combo("Group name", "group name", 1, p.data["groupnames"])
    
            @cstatic str1 = "New phrase"*"\0"^50 begin
                CImGui.InputText("Phrase", str1, length(str1))
                p.newdiagnosis = replace(str1 ,"\0" => "")
            end

            if CImGui.TreeNode("Select a banned phrase(s)")
                CImGui.Text("     *Hold CTRL and click to select multiple items.")
                CImGui.Separator()
                @cstatic selection=fill(false,1000) begin
                    for n = 0:length(p.all_phrases)-1
                        buf = p.all_phrases[n+1]
                        if CImGui.Selectable(buf, selection[n+1])
                               # clear selection when CTRL is not held
                            !CImGui.GetIO().KeyCtrl && fill!(selection, false)
                            selection[n+1] ⊻= 1
                        end
                    end
                    p.newban=p.all_phrases[selection[1:length(p.all_phrases)]]
                end
            end

            #     n = length(v.all_phrases)
            #         for i in 1:n
            #             @cstatic selected=false begin
            #             @c CImGui.Checkbox(v.all_phrases[i], &selected)
            #             # v.selected = selected
            #         end
            #     end
            # end

            # @cstatic str2 = "New banned combination"*"\0"^50 begin
            #     CImGui.InputText("Banned combination", str2, length(str2))
            #     v.newban = replace(str2 ,"\0" => "")
            # end

        end

     CImGui.End()
    end
end

function show_gui()
    state1 = Vars()
    state2 = Vrs()
    Renderer.render(
        ()->ui(state1,state2),
        width=1600,
        height=700,
        title="",
        hotloading=true
    )
    return state1, state2
end

show_gui();