using JSON

# s = "{\"a_number\" : 5.0, \"an_array\" : [\"string\", 9]}"
# j = JSON.parse(s)

# JSON.json([2,3])

s="configNEW.json"

data = JSON.parsefile(s)
names = data["groupnames"]
names[3]

data[names[2]]