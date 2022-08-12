using PackageCompiler

include("txtgui.jl")
using .ConclusionGui

ConclusionGui.show_gui()

create_app("../Project.toml", "txtgui.jl")
