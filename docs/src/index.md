# OpenModelicaParser.jl

A Modelica parser written in Julia. It reads Modelica (and MetaModelica, ParModelica, Optimica and
PDEModelica) into `Absyn` trees, the abstract syntax of the OpenModelica compiler, which
[OMFrontend.jl](https://github.com/OpenModelica/OMFrontend.jl) instantiates. Pure Julia: nothing to
build.

Two modules:
- `OpenModelicaParser.Absyn`: the syntax tree records (formerly the package Absyn.jl).
- `OpenModelicaParser.Parser`: the lexer and the parser.

`parseFile`, `parseString` and `ParseError` are also `OpenModelicaParser.parseFile` etc.
`Modelica"..."` takes Modelica source written in a Julia file ([Modelica in Julia files](macro.md)).

Formerly OMParser.jl: OpenModelicaParser 1.0.0 is OMParser 1.1.0 renamed, with a new UUID. OMParser
stays registered for the packages that depend on it.

## Install
```julia
import Pkg
Pkg.add(url = "https://github.com/OpenModelica/OpenModelicaParser.jl")
```

## Use
```julia
import OpenModelicaParser
program = OpenModelicaParser.parseFile("HelloWorld.mo")
program = OpenModelicaParser.parseString("model M Real x; equation x = 1; end M;", "M.mo")
```
Both return an `Absyn.Program`.

| Argument | Values |
|---|---|
| `acceptedGram` | 1 Modelica (default), 2 MetaModelica, 3 ParModelica, 4 Optimica, 5 PDEModelica |
| `languageStandard` | 10, 20, 30, 31, 32, 33, 34, 35 (1.x to 3.5), 1000 (latest), 9999 (experimental) |
| `firstLine` | the number of the text's first line, for a text that is part of a file (`parseString` only) |

`parseFile` defaults to the experimental standard (9999), `parseString` to the latest (1000).

The records keep their names under `import OpenModelicaParser.Absyn`:
```julia
import OpenModelicaParser.Absyn
program isa Absyn.PROGRAM
Absyn.dumpPath(Absyn.QUALIFIED("Modelica", Absyn.IDENT("Blocks")))   # "Modelica.Blocks"
```

## Errors
A syntax error throws an `OpenModelicaParser.ParseError` with the file, line and column:
```
M.mo:2:9: Expected ';' after the element but found 'equation' on line 3
    Real x
          ^
```
A file that cannot be read is a `ParseError` with line 0.

## License
GPL version 3 or the OSMC Public License (OSMC-PL), according to the recipient's choice: see
[LICENSE.md](https://github.com/OpenModelica/OpenModelicaParser.jl/blob/master/LICENSE.md).
