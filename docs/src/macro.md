# Modelica in Julia files

`Modelica"""..."""` (exported) gives the `Absyn.Program` of Modelica source written in a Julia file:
```julia
using OpenModelicaParser
program = Modelica"""
  model Decay
    Real x(start = 1.0);
  equation
    der(x) = -x;
  end Decay;
  """
```

- The text is parsed when the macro is expanded. A syntax error is a `ParseError` when the file is
  loaded. The program is a constant of the code: nothing is parsed when the code runs, and each
  evaluation gives the same object.
- The text is taken as written, as in a Modelica file: `$` and backslashes stay. The one exception
  is Julia's rule for string macros: a quote escaped in a Modelica string takes two backslashes
  (`\\"`). Line ends are line feeds, also in a Julia file with CRLF line ends.
- Positions and error messages name the Julia file and its lines. Julia gives a macro the line of
  its call only: a text of several lines is taken to start on the line after the call (as above),
  a text of one line on the line of the call.
- The grammar is Modelica of the latest standard. Other grammars, and a text held in a variable:
  `parseString`.

## Interpolation: `@Modelica`
`@Modelica` (exported) builds the text from values:
```julia
tank(name::String, n::Int) = @Modelica "model $name Real x[$n]; end $name;"
```
The text is put together and parsed each time the code runs. It is a Julia string, so Julia's
escapes apply first: a backslash of the Modelica text is written `\\`, a dollar sign `\$`.

## Tested on the Modelica Standard Library
The 278 example models of the Modelica Standard Library 3.2.1, each written in both forms, give the
classes of the library, positions included. 177 are written as they are in the library. The 101
with escaped quotes in their documentation take the two backslashes; pasted unchanged, they are a
`ParseError` when the file is loaded
([test/README.md](https://github.com/OpenModelica/OpenModelicaParser.jl/blob/master/test/README.md)).
