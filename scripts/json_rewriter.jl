using CImGui
using ImPlot
using JSON
using CImGui.CSyntax
using CImGui.CSyntax.CStatic
using CImGui: ImVec2
using Gtk

include(joinpath(pathof(ImPlot),"..","..","demo","Renderer.jl"))
using .Renderer

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


function rewriter(v::Vrs)

    CImGui.Begin("Rewrite json")

        if CImGui.Button("Load file.json")
            v.filename = open_dialog_native("Select file", GtkNullContainer(), ("*.json",))
            if v.filename != ""
                v.data = JSON.parsefile(v.filename)
                v.all_phrases = all_diagnoses(v.data)
                v.is_file_loaded = true
            else
                warn_dialog("File was not selected!")
                v.is_file_loaded = false
            end
        end

        CImGui.SameLine(500)
        if CImGui.Button("Add changes to file.json")
            can_whrite = true
            # сделать возможность добавления вектора из забаненных фраз!!!!!!!!!!!
            if v.newname != "" && v.newdiagnosis != "" && v.newban != "" 

                names = v.data["groupnames"]
                is_new=true

                for i in 1:length(names)
                    if v.newname == names[i]
                        is_new = false
                    end
                end

                if is_new
                    entry = Dict(v.newname => ([Dict("diagnosis" => v.newdiagnosis, "ban" => v.newban)]))
                    newdata = merge(v.data, entry)
                    push!(newdata["groupnames"], v.newname)
                else
                    newdata = v.data
                    group = newdata[v.newname]

                    is_new_diagnosis = true
                    for i in 1:length(group)
                        if group[i]["diagnosis"] == v.newdiagnosis
                            is_new_diagnosis = false
                        end
                    end

                    if is_new_diagnosis
                        push!(newdata[v.newname], Dict("diagnosis" => v.newdiagnosis, "ban" => v.newban))
                    else
                        warn_dialog("The entered phrase is already in this section")
                        can_whrite = false
                    end
                end

                if can_whrite
                    open(v.filename, "w") do f
                        JSON.print(f, newdata)
                    end

                    v.filename="configs/rewrited.json"
                    v.data = JSON.parsefile(v.filename)
                    v.all_phrases = all_diagnoses(v.data)
                    v.is_file_loaded = true
                end

                info_dialog("Changes were added")

            end
        end

        if v.is_file_loaded

            ###############################################################
            function text_and_combo(title::String, name::String, num::Int64, items::Vector{Any})
                CImGui.Text("Enter a new"*name*"or select an existing one")
            
                @cstatic str0 = "Write here"*"\0"^50 begin
                    CImGui.InputText("", str0, length(str0))
                    if v.buf[num] != v.current_item[num]
                        str0 = v.current_item[num]*"\0"^50
                        v.buf[num] = v.current_item[num]
                    end
                    v.newname = replace(str0 ,"\0" => "")
                end
            
                CImGui.SameLine()
                @cstatic item_current="" begin
                    if CImGui.BeginCombo(title, item_current, CImGui.ImGuiComboFlags_NoPreview)
                        for n = 0:length(items)-1
                            is_selected = item_current == items[n+1]
                            CImGui.Selectable(items[n+1], is_selected) && (item_current = items[n+1];)
                            is_selected && CImGui.SetItemDefaultFocus()
                            v.current_item[num] = item_current
                        end
                        CImGui.EndCombo()
                    end
                end
            end
            
            ####################################################

            text_and_combo("Group name", "group name", 1, v.data["groupnames"])
    
            @cstatic str1 = "New phrase"*"\0"^50 begin
                CImGui.InputText("Phrase", str1, length(str1))
                v.newdiagnosis = replace(str1 ,"\0" => "")
            end

            if CImGui.TreeNode("Select a banned phrase(s)")
                CImGui.Text("     *Hold CTRL and click to select multiple items.")
                CImGui.Separator()
                @cstatic selection=fill(false,1000) begin
                    for n = 0:length(v.all_phrases)-1
                        buf = v.all_phrases[n+1]
                        if CImGui.Selectable(buf, selection[n+1])
                               # clear selection when CTRL is not held
                            !CImGui.GetIO().KeyCtrl && fill!(selection, false)
                            selection[n+1] ⊻= 1
                        end
                    end
                    v.newban=v.all_phrases[selection[1:length(v.all_phrases)]]
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

    ###########################

    
end

function show_rewriter()
    state = Vrs();
    Renderer.render(
        ()->rewriter(state),
        width=1600,
        height=700,
        title="",
        hotloading=true
    )
    return state
end

show_rewriter();


# s = open_dialog_native("Select file", GtkNullContainer(), ("*.json",))
# # s="configs/configRewrite.json"
    
# data = JSON.parsefile(s)

#     newname = "new entry"
#     newdiagnosis = "d3"
#     newban = [""]

#     names = data["groupnames"]

#     # data[newname]

#     is_new=true
#     for i in 1:length(names)
#         if newname == names[i]
#             is_new = false
#         end
#     end

#     if is_new
#         entry=Dict(newname => ([Dict("diagnosis" => newdiagnosis, "ban" => newban)]))
#         newdata = merge(data, entry)
#         push!(newdata["groupnames"], newname)
#     else
#         newdata = data
#         group = newdata[newname]

#         is_new_diagnosis = true
#         for i in 1:length(group)
#             if group[i]["diagnosis"] == newdiagnosis
#                 is_new_diagnosis = false
#             end
#         end

#         if is_new_diagnosis
#             push!(newdata[newname], Dict("diagnosis" => newdiagnosis, "ban" => newban))
#         else
#             # вывести сообщение о том, что такая фраза в этом разделе уже соержится
#         end
#     end

#     rm(s)
#     open(s,"w") do f
#         JSON.print(f, newdata)
#     end
