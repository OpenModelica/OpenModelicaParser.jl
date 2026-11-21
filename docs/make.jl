#= Build the documentation: `julia --project=docs docs/make.jl`. Deploys to gh-pages only on CI. =#
using Documenter
using OpenModelicaParser

makedocs(
  sitename = "OpenModelicaParser.jl",
  modules = [OpenModelicaParser],
  authors = "John Tinnerholm <john.tinnerholm@liu.se>, Adrian Pop <adrian.pop@liu.se>",
  repo = Documenter.Remotes.GitHub("OpenModelica", "OpenModelicaParser.jl"),
  format = Documenter.HTML(;
    prettyurls = get(ENV, "CI", "false") == "true",
    canonical = "https://OpenModelica.github.io/OpenModelicaParser.jl",
    edit_link = "master",
  ),
  pages = [
    "Home" => "index.md",
    "Modelica in Julia files" => "macro.md",
    "How it works" => "internals.md",
    "API reference" => "api.md",
    "Absyn" => "absyn.md",
  ],
  #= The exported names must be in the manual: the macros, and Absyn's (it exports all its names). =#
  checkdocs = :exports,
)

if get(ENV, "CI", "false") == "true"
  deploydocs(repo = "github.com/OpenModelica/OpenModelicaParser.jl.git", devbranch = "master")
end
