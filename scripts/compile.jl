using PackageCompiler

# PackageCompiler.create_app(pwd(), "MyProjectCompiled";
#     cpu_target="generic;sandybridge,-xsaveopt,clone_all;haswell,-rdrnd,base(1)",
#     include_transitive_dependencies=false,
#     filter_stdlibs=true,
#     precompile_execution_file=["scripts/newgui.jl"])

PackageCompiler.create_app(pwd(), "HotBoxCompiled"; filter_stdlibs=true, precompile_execution_file=["scripts/newgui.jl"])