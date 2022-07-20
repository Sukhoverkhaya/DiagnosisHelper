using JSON

# s = "{\"a_number\" : 5.0, \"an_array\" : [\"string\", 9]}"
# j = JSON.parse(s)

# JSON.json([2,3])

s="configs/configTest.json"

data = JSON.parsefile(s)
names = data["groupnames"]
names[3]

t=Vector{Vector{Int64}}[[]]
d=[]
a=fill(5, 5)
push!(d, a)
push!(d, [1,2,3,4,5,6,7,8])