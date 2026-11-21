# Absyn

`OpenModelicaParser.Absyn` is the abstract syntax of Modelica and MetaModelica: the tree that `parseFile`,
`parseString` and `Modelica"..."` return. Each kind of node is an abstract type, and its forms are immutable records
(structs) of that type: test them with `isa` or match on them. Lists are `ImmutableList` lists; optional fields are
`Option{T}` (`Some{T}` or `nothing`). The fields are described by comments in `src/Absyn/Absyn.jl`.

```julia
import OpenModelicaParser
import OpenModelicaParser.Absyn
program = OpenModelicaParser.parseString("model M Real x; equation x = 1; end M;", "M.mo")
cls = first(program.classes)        # an Absyn.CLASS
cls.name                            # "M"
cls.restriction isa Absyn.R_MODEL   # true
cls.info.lineNumberStart            # 1
```

## The tree
A `PROGRAM` holds the classes of a file and its `within` clause. A `CLASS` has a name, its prefixes, a
`Restriction`, a body (`ClassDef`) and its position in the source (`SourceInfo`). A body of parts lists public and
protected elements, equations and algorithms.

| Type | Records |
|---|---|
| `Program` | `PROGRAM` |
| `Within` | `WITHIN`, `TOP` |
| `Class` | `CLASS` |
| `ClassDef` | `PARTS`, `DERIVED`, `ENUMERATION`, `OVERLOAD`, `CLASS_EXTENDS`, `PDER` |
| `ClassPart` | `PUBLIC`, `PROTECTED`, `EQUATIONS`, `INITIALEQUATIONS`, `ALGORITHMS`, `INITIALALGORITHMS`, `CONSTRAINTS`, `EXTERNAL` |
| `ElementItem` | `ELEMENTITEM`, `LEXER_COMMENT` |
| `Element` | `ELEMENT`, `DEFINEUNIT`, `TEXT` |
| `ElementSpec` | `CLASSDEF`, `EXTENDS`, `IMPORT`, `COMPONENTS` |
| `Import` | `NAMED_IMPORT`, `QUAL_IMPORT`, `UNQUAL_IMPORT`, `GROUP_IMPORT` |
| `ComponentItem`, `Component` | `COMPONENTITEM`, `COMPONENT` |
| `Modification` | `CLASSMOD` |
| `ElementArg` | `MODIFICATION`, `REDECLARATION`, `INHERITANCEBREAK` |
| `EquationItem` | `EQUATIONITEM`, `EQUATIONITEMCOMMENT` |
| `Equation` | `EQ_EQUALS`, `EQ_CONNECT`, `EQ_IF`, `EQ_FOR`, `EQ_WHEN_E`, `EQ_NORETCALL`, `EQ_FAILURE`, `EQ_PDE`, `EQ_RECONFIGURE` |
| `AlgorithmItem` | `ALGORITHMITEM`, `ALGORITHMITEMCOMMENT` |
| `Algorithm` | `ALG_ASSIGN`, `ALG_IF`, `ALG_FOR`, `ALG_PARFOR`, `ALG_WHILE`, `ALG_WHEN_A`, `ALG_NORETCALL`, `ALG_RETURN`, `ALG_BREAK`, `ALG_CONTINUE`, `ALG_FAILURE`, `ALG_TRY` |
| `Exp` | `INTEGER`, `REAL`, `STRING`, `BOOL`, `CREF`, `BINARY`, `UNARY`, `LBINARY`, `LUNARY`, `RELATION`, `IFEXP`, `CALL`, `PARTEVALFUNCTION`, `ARRAY`, `MATRIX`, `RANGE`, `TUPLE`, `END`, `CODE`, `AS`, `CONS`, `MATCHEXP`, `LIST`, `DOT`, `SUBSCRIPTED_EXP`, `EXPRESSIONCOMMENT`, `BREAK` |
| `ComponentRef` | `CREF_IDENT`, `CREF_QUAL`, `CREF_FULLYQUALIFIED`, `WILD`, `ALLWILD` |
| `Path` | `IDENT`, `QUALIFIED`, `FULLYQUALIFIED` |
| `Subscript` | `SUBSCRIPT`, `NOSUB` |
| `TypeSpec` | `TPATH`, `TCOMPLEX` |
| `Restriction` | 22 records: `R_MODEL`, `R_BLOCK`, `R_CONNECTOR`, `R_RECORD`, `R_FUNCTION`, `R_PACKAGE`, `R_TYPE`, ... |
| `Comment`, `Annotation` | `COMMENT`, `ANNOTATION` |
| `SourceInfo` | `SOURCEINFO` |

## Source positions, the optional type, printing

```@autodocs
Modules = [OpenModelicaParser.Absyn]
```

```@docs
OpenModelicaParser.Absyn.Optional
```
