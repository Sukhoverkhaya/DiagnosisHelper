module parsetxt2
    struct Node
        name::String
        banned_by::Vector{String}
        will_ban::String
    end

    struct List
        name::String
        children::Vector{Node}
    end

    function my_txtparser2(filename::String, type::String)
        
        if type == "data"
            data = List[]

            open(filename) do file # Открываем файл
                needwrite = false
                children = Node[]
                groupname = ""

                while !eof(file) # Пока не достигнут конец файла,
                    lines = rstrip(readline(file)) # читаем его построчно

                    ln = split(lines, "    ")
                    if length(ln) == 1
                        if needwrite
                            push!(data, List(groupname, children))
                            children = Node[]
                            groupname = ""
                        end
                        needwrite = true
                        groupname = split(ln[1], " - ")[2]
                    else
                        ph = split(ln[2], " : ")
                        if length(ph) == 1
                            push!(children, Node(ph[1], [""], ""))
                        elseif length(ph) == 2
                            banned_by = split(ph[2], ", ")
                            push!(children, Node(ph[1], banned_by, ""))
                        elseif length(ph) == 3
                            banned_by = split(ph[2], ", ")
                            push!(children, Node(ph[1], banned_by, ph[3]))
                        end
                    end
                end
                push!(data, List(groupname, children))
            end

            return data
        elseif type == "history"
            hst = ""
            open(filename) do file # Открываем файл
                while !eof(file) # Пока не достигнут конец файла,
                    line = rstrip(readline(file)) # читаем его построчно
                    hst *= line * "\n"
                end
            end

            return hst
        end
    end
end

# filename = "configs/history.txt"
# hist = my_txtparser2(filename, "history")

# filename = "configs/newtxt.txt"
# data = my_txtparser2(filename)

# data
# data[1]
# data[1].name
# data[1].children
# data[1].children[1].name
# data[1].children[1].banned_by
# data[1].children[1].will_ban

# data[2].children[1].name
# data[2].children[1].banned_by
# data[2].children[1].will_ban

# data[7].children[1].name
# data[7].children[1].banned_by
# data[7].children[1].will_ban


