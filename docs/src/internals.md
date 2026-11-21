# How it works

A lexer (`src/Parser/Lexer.jl`, `src/Parser/Tokens.jl`) and a recursive-descent parser
(`src/Parser/Rules.jl`) with one function per rule of omc's grammar (`OMCompiler/Parser/Modelica.g`
in the OpenModelica repository).

The trees are the ones omc's ANTLR parser builds, source positions and comments included.
`test/Differential` compares the two over directory trees: OMParser 0.2 (the ANTLR/C parser, loaded
from its library, its trees built from the Absyn.jl package's records) against this parser, compared
by name. They agree on:
- the Modelica Standard Library,
- the OpenModelica testsuite,
- the OpenModelica compiler's MetaModelica sources,
- the Buildings library.

## Compile with JuliaC
The parser has no dynamic dispatch (tested), so programs that use it can be compiled with
[JuliaC](https://github.com/JuliaLang/JuliaC.jl) and `--trim=safe`. `bin/omparse.jl` is an example
(the build command is in the file): a 2.4 MB executable that parses MSL 4.1.0 in 0.13 s.
