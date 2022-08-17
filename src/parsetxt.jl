
module parsetxt
    struct Node
        name::String
        ban::Vector{String}
    end

    struct List
        name::String
        children::Vector{Node}
    end

    struct Code
        name::String
        code::String
    end

    function my_txtparser(filename::String)

        data = []
        push!(data, Code[])
        push!(data, List[])

        open(filename) do file # Открываем файл

            isgroup = true
            needwrite = false
            children = Node[]
            groupname = ""

            while !eof(file) # Пока не достигнут конец файла,
                lines = rstrip(readline(file)) # читаем его построчно
                if lines != "#" && isgroup == true
                    ln = split(lines, " : ")
                    push!(data[1], Code(ln[2], ln[1]))
                elseif lines == "#"
                    isgroup = false
                elseif lines != "#" && isgroup == false
                    ln = split(lines, "    ")
                    if length(ln) == 1 # если нет отступа
                        if needwrite
                            push!(data[2], List(groupname, children))
                            children = Node[]
                            groupname = ""
                        end
                        groupname = split(lines, " - ")[2]
                        needwrite = true
                    else # если есть отступ
                        diagnosis = split(ln[2], " : ")
                        if length(diagnosis) == 1
                            ban = [""]
                        else
                            ban = split(diagnosis[2], ", ")
                        end
                        push!(children, Node(diagnosis[1], ban))
                    end
                end
            end
            push!(data[2], List(groupname, children))
        end

        return data
    end
end

# filename = "configs/test.txt"
# data = parsetxt.my_txtparser(filename)

# data[1][5].name
# data[1][5].code

# data[2][5].name
# data[2][5].children[1].name
# data[2][5].children[1].ban

