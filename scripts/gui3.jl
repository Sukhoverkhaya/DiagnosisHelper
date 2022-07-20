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
    file::String
    data::Dict{String, Any}
    names::Vector{Any}
    check::Vector{Vector{Int64}}
    conclusion::String
    
    function Vars()
        file = "configs/configTest.json"
        data = JSON.parsefile(file)
        names = data["groupnames"]
        check = []
        for i in 1:length(names)
            n=length(data[names[i]])
            push!(check, fill(0,n))
        end
        conclusion = ""

        new(file, data, names, check, conclusion)
    end
end

function ui(v::Vars)
    CImGui.Begin("Menu")
        if CImGui.TreeNode(v.names[1])
            groupdata=v.data[v.names[1]]
            for j in 1:length(groupdata)
                CImGui.RadioButton(groupdata[j]["diagnosis"], v.check[1][1] == j) && (v.check[1][1] = j;)
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
                    groupdata=v.data[v.names[i]]
                    for j in 1:length(groupdata)

                        is_banned = false
                        for t in 1:length(v.names)
                            for p in 1:length(v.check[t])
                                if v.check[t][p]!=0
                                    banned = v.data[v.names[t]][v.check[t][p]]["ban"]
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
                        txt*=v.data[v.names[i]][v.check[i][j]]["diagnosis"]*". "
                    end
                end
            end
            CImGui.InputTextMultiline("##source", txt*text, length(text), ImVec2(-1.0, CImGui.GetTextLineHeight() * 16), flags)

            v.conclusion=txt
        end
    CImGui.End
end

function show_gui()
    state = Vars()
    Renderer.render(
        ()->ui(state),
        width=1000,
        height=700,
        title="",
        hotloading=true
    )
    return state
end

show_gui();