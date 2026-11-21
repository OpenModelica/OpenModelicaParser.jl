#=
This file is part of OpenModelica.
Copyright (c) 1998-2026, Open Source Modelica Consortium (OSMC),
c/o Linköpings universitet, Department of Computer and Information Science,
SE-58183 Linköping, Sweden.

All rights reserved.

THIS PROGRAM IS PROVIDED UNDER THE TERMS OF THE GPL VERSION 3 LICENSE OR
THE OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.2.
ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES
RECIPIENT'S ACCEPTANCE OF THE OSMC PUBLIC LICENSE OR THE GPL VERSION 3,
ACCORDING TO RECIPIENTS CHOICE.

The OpenModelica software and the OSMC (Open Source Modelica Consortium)
Public License (OSMC-PL) are obtained from OSMC, either from the above
address, from the URLs: http://www.openmodelica.org or
http://www.ida.liu.se/projects/OpenModelica, and in the OpenModelica
distribution. GNU version 3 is obtained from:
http://www.gnu.org/copyleft/gpl.html.

This program is distributed WITHOUT ANY WARRANTY; without even the implied
warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE, EXCEPT AS
EXPRESSLY SET FORTH IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE
CONDITIONS OF OSMC-PL.
=#

"""
    OpenModelicaParser.Absyn

The abstract syntax of Modelica and MetaModelica: the records that `OpenModelicaParser.Parser` builds and the frontend
instantiates. Formerly the package Absyn.jl (1.4.2); `import
OpenModelicaParser.Absyn` keeps the name `Absyn` in the code that uses it.
"""
module Absyn

using ImmutableList
#= ExportAll is not good practice but it makes it so that we do not have to write export after each function :( =#
using ExportAll

"""
`Option{T}`: `Union{Some{T}, Nothing}`, MetaModelica's optional type. In a submodule, used without importing the name,
so `@exportAll` does not export it: MetaModelica exports `Option`, and two exported bindings of one name clash in code
that uses both.
"""
module Optional
const Option{T} = Union{Some{T}, Nothing}
export Option
end
using .Optional

"""
    SourceInfo

Where a syntax element or class is in the source (formerly MetaModelica's `SourceInfo`).
"""
abstract type SourceInfo end

"""
    SOURCEINFO(fileName, isReadOnly, lineNumberStart, columnNumberStart, lineNumberEnd, columnNumberEnd[,
               lastModification])

The file (`isReadOnly`: true for libraries), the start and end positions, and the file's modification time (stat(2)
mtime as Float64; 0.0 when not given).
"""
mutable struct SOURCEINFO <: SourceInfo
  fileName::String
  isReadOnly::Bool
  lineNumberStart::Int
  columnNumberStart::Int
  lineNumberEnd::Int
  columnNumberEnd::Int
  lastModification::Float64
end

SOURCEINFO(fileName::String, isReadOnly::Bool, lineNumberStart::Int, columnNumberStart::Int, lineNumberEnd::Int,
           columnNumberEnd::Int) =
  SOURCEINFO(fileName, isReadOnly, lineNumberStart, columnNumberStart, lineNumberEnd, columnNumberEnd, 0.0)

"""The source info of a value made without a source."""
const DEFAULT_INFO = SOURCEINFO("", true, 1, 2, 3, 4, 0.0)

"""MetaModelica's `sourceInfo()`: [`DEFAULT_INFO`](@ref)."""
sourceInfo()::SOURCEINFO = DEFAULT_INFO
#= Necessary to write declarations for your uniontypes until Julia adds support for mutually recursive types =#

abstract type ForIterator end
abstract type Program end
abstract type Within end
abstract type Class end
abstract type ClassDef end
abstract type TypeSpec end
abstract type EnumDef end
abstract type EnumLiteral end
abstract type ClassPart end
abstract type ElementItem end
abstract type Element end
abstract type ConstrainClass end
abstract type ElementSpec end
abstract type InnerOuter end
abstract type Import end
abstract type GroupImport end
abstract type ComponentItem end
abstract type Component end
abstract type EquationItem end
abstract type AlgorithmItem end
abstract type Equation end
abstract type Algorithm end
abstract type WhenClause end
abstract type Modification end
abstract type EqMod end
abstract type ElementArg end
abstract type RedeclareKeywords end
abstract type Each end
abstract type ElementAttributes end
abstract type IsField end
abstract type Parallelism end
abstract type FlowStream end
abstract type Variability end
abstract type Direction end
abstract type Exp end
abstract type Case end
abstract type MatchType end
abstract type CodeNode end
abstract type FunctionArgs end
abstract type ReductionIterType end
abstract type NamedArg end
abstract type Operator end
abstract type Subscript end
abstract type ComponentRef end
abstract type Path end
abstract type Restriction end
abstract type FunctionPurity end
abstract type FunctionRestriction end
abstract type Annotation end
abstract type Comment end
abstract type ExternalDecl end
abstract type Ref end
abstract type Msg end

const Ident = String  #= An identifier, for example a variable name =#

#= For Iterator - these are used in:
* for loops where the expression part can be NONE() and then the range
is taken from an array variable that the iterator is used to index,
see 3.3.3.2 Several Iterators from Modelica Specification.
* in array iterators where the expression should always be SOME(Exp),
see 3.4.4.2 Array constructor with iterators from Specification
* the guard is a MetaModelica extension; it's a Boolean expression that
filters out items in the range. =#
  struct ITERATOR <: ForIterator
    name::String
    guardExp::Option{Exp}
    range::Option{Exp}
  end

const ForIterators = List{ForIterator}  #= For Iterators -
these are used in:
* for loops where the expression part can be NONE() and then the range
is taken from an array variable that the iterator is used to index,
see 3.3.3.2 Several Iterators from Modelica Specification.
* in array iterators where the expression should always be SOME(Exp),
see 3.4.4.2 Array constructor with iterators from Specification =#

#= - Programs, the top level construct
A program is simply a list of class definitions declared at top
level in the source file, combined with a within statement that
indicates the hieractical position of the program. =#
  struct PROGRAM <: Program
    classes #= List of classes =#::List{Class}
    within_ #= Within clause =#::Within
  end

#= Within Clauses =#
  struct WITHIN <: Within
    path #= the path for within =#::Path
  end

  struct TOP <: Within
  end

const Info = SourceInfo

#= A class definition consists of a name, a flag to indicate
if this class is declared as partial, the declared class restriction,
and the body of the declaration. =#
  struct CLASS <: Class
    name::Ident
    partialPrefix #= true if partial =#::Bool
    finalPrefix #= true if final =#::Bool
    encapsulatedPrefix #= true if encapsulated =#::Bool
    restriction #= Restriction =#::Restriction
    body::ClassDef
    info #= Information: FileName is the class is defined in +
    isReadOnly bool + start line no + start column no +
    end line no + end column no =#::Info
  end

#= The ClassDef type contains thClasse definition part of a class declaration.
The definition is either explicit, with a list of parts
(public, protected, equation, and algorithm), or it is a definition
derived from another class or an enumeration type.
For a derived type, the  type contains the name of the derived class
and an optional array dimension and a list of modifications.
=#
  struct PARTS <: ClassDef
    typeVars #= class A<B,C> ... has type variables B,C =#::List{String}
    classAttrs #= optimization Op (objective=...) end Op. A list arguments attributing a
    class declaration. Currently used only for Optimica extensions =#::List{NamedArg}
    classParts::List{ClassPart}
    ann #= Modelica2 allowed multiple class-annotations =#::List{Annotation}
    comment::Option{String}
  end

  struct DERIVED <: ClassDef
    typeSpec #= typeSpec specification includes array dimensions =#::TypeSpec
    attributes::ElementAttributes
    arguments::List{ElementArg}
    comment::Option{Comment}
  end

  struct ENUMERATION <: ClassDef
    enumLiterals::EnumDef
    comment::Option{Comment}
  end

  struct OVERLOAD <: ClassDef
    functionNames::List{Path}
    comment::Option{Comment}
  end

  struct CLASS_EXTENDS <: ClassDef
    baseClassName #= name of class to extend =#::Ident
    modifications #= modifications to be applied to the base class =#::List{ElementArg}
    comment #= comment =#::Option{String}
    parts #= class parts =#::List{ClassPart}
    ann::List{Annotation}
  end

  struct PDER <: ClassDef
    functionName::Path
    vars #= derived variables =#::List{Ident}
    comment #= comment =#::Option{Comment}
  end

const ArrayDim = List{Subscript}  #= Component attributes are
properties of components which are applied by type prefixes.
As an example, declaring a component as `input Real x;\\' will
give the attributes `ATTR({},false,VAR,INPUT)\\'.
Components in Modelica can be scalar or arrays with one or more
dimensions. This type is used to indicate the dimensionality
of a component or a type definition.
- Array dimensions =#

#= ModExtension: new MetaModelica type specification! =#
  struct TPATH <: TypeSpec
    path::Path
    arrayDim::Option{ArrayDim}
  end

  struct TCOMPLEX <: TypeSpec
    path::Path
    typeSpecs::List{TypeSpec}
    arrayDim::Option{ArrayDim}
  end

#= The definition of an enumeration is either a list of literals
or a colon, \\':\\', which defines a supertype of all enumerations =#
  struct ENUMLITERALS <: EnumDef
    enumLiterals::List{EnumLiteral}
  end

  struct ENUM_COLON <: EnumDef
  end

#= EnumLiteral, which is a name in an enumeration and an optional
Comment. =#
  struct ENUMLITERAL <: EnumLiteral
    literal::Ident
    comment::Option{Comment}
  end

#= A class definition contains several parts.  There are public and
protected component declarations, type definitions and `extends\\'
clauses, collectively called elements.  There are also equation
sections and algorithm sections. The EXTERNAL part is used only by functions
which can be declared as external C or FORTRAN functions. =#
  struct PUBLIC <: ClassPart
    contents::List{ElementItem}
  end

  struct PROTECTED <: ClassPart
    contents::List{ElementItem}
  end

  struct CONSTRAINTS <: ClassPart
    contents::List{Exp}
  end

  struct EQUATIONS <: ClassPart
    contents::List{EquationItem}
  end

  struct INITIALEQUATIONS <: ClassPart
    contents::List{EquationItem}
  end

  struct ALGORITHMS <: ClassPart
    contents::List{AlgorithmItem}
  end

  struct INITIALALGORITHMS <: ClassPart
    contents::List{AlgorithmItem}
  end

  struct EXTERNAL <: ClassPart
    externalDecl #= externalDecl =#::ExternalDecl
    annotation_ #= annotation =#::Option{Annotation}
  end

#= An element item is either an element or an annotation =#
  struct ELEMENTITEM <: ElementItem
    element::Element
  end

  struct LEXER_COMMENT <: ElementItem
    comment::String
  end

#= Elements
The basic element type in Modelica =#
  struct ELEMENT <: Element
    finalPrefix::Bool
    redeclareKeywords #= replaceable, redeclare =#::Option{RedeclareKeywords}
    innerOuter #= inner/outer =#::InnerOuter
    specification #= Actual element specification =#::ElementSpec
    info #= File name the class is defined in + line no + column no =#::Info
    constrainClass #= only valid for classdef and component =#::Option{ConstrainClass}
  end

  struct DEFINEUNIT <: Element
    name::Ident
    args::List{NamedArg}
    info::Info
  end

  struct TEXT <: Element
    optName #= optName : optional name of text, e.g. model with syntax error.
    We need the name to be able to browse it... =#::Option{Ident}
    string::String
    info::Info
  end

#= Constraining type, must be extends =#
  struct CONSTRAINCLASS <: ConstrainClass
    elementSpec #= must be extends =#::ElementSpec
    comment #= comment =#::Option{Comment}
  end

#= An element is something that occurs in a public or protected
section in a class definition.  There is one constructor in the
`ElementSpec\\' type for each possible element type.  There are
class definitions (`CLASSDEF\\'), `extends\\' clauses (`EXTENDS\\')
and component declarations (`COMPONENTS\\').

As an example, if the element `extends TwoPin;\\' appears
in the source, it is represented in the AST as
`EXTENDS(IDENT(\\\"TwoPin\\\"),{})\\'.
=#
  struct CLASSDEF <: ElementSpec
    replaceable_ #= replaceable =#::Bool
    class_ #= class =#::Class
  end

  struct EXTENDS <: ElementSpec
    path #= path =#::Path
    elementArg #= elementArg =#::List{ElementArg}
    annotationOpt #= optional annotation =#::Option{Annotation}
  end

  struct IMPORT <: ElementSpec
    import_ #= import =#::Import
    comment #= comment =#::Option{Comment}
    info::Info
  end

  struct COMPONENTS <: ElementSpec
    attributes #= attributes =#::ElementAttributes
    typeSpec #= typeSpec =#::TypeSpec
    components #= components =#::List{ComponentItem}
  end

#= One of the keyword inner and outer CAN be given to reference an
inner or outer element. Thus there are three disjoint possibilities. =#
  struct INNER <: InnerOuter
  end

  struct OUTER <: InnerOuter
  end

  struct INNER_OUTER <: InnerOuter
  end

  struct NOT_INNER_OUTER <: InnerOuter
  end

#= Import statements, different kinds =#
  #=  A named import is a import statement to a variable ex;
  =#
  #=  NAMED_IMPORT(\"SI\",QUALIFIED(\"Modelica\",IDENT(\"SIunits\")));
  =#

  struct NAMED_IMPORT <: Import
    name #= name =#::Ident
    path #= path =#::Path
  end

  struct QUAL_IMPORT <: Import
    path #= path =#::Path
  end

  struct UNQUAL_IMPORT <: Import
    path #= path =#::Path
  end

  struct GROUP_IMPORT <: Import
    prefix::Path
    groups::List{GroupImport}
  end

  struct GROUP_IMPORT_NAME <: GroupImport
    name::String
  end

  struct GROUP_IMPORT_RENAME <: GroupImport
    rename::String
    name::String
  end

const ComponentCondition = Exp  #= A componentItem can have a condition that must be fulfilled if
          the component should be instantiated.
         =#

#= Collection of component and an optional comment =#
  struct COMPONENTITEM <: ComponentItem
    component #= component =#::Component
    condition #= condition =#::Option{ComponentCondition}
    comment #= comment =#::Option{Comment}
  end

#= Some kind of Modelica entity (object or variable) =#
  struct COMPONENT <: Component
    name #= name =#::Ident
    arrayDim #= Array dimensions, if any =#::ArrayDim
    modification #= Optional modification =#::Option{Modification}
  end

#= Several component declarations can be grouped together in one
`ElementSpec\\' by writing them on the same line in the source.
This type contains the information specific to one component. =#
  struct EQUATIONITEM <: EquationItem
    equation_ #= equation =#::Equation
    comment #= comment =#::Option{Comment}
    info #= line number =#::Info
  end

  struct EQUATIONITEMCOMMENT <: EquationItem
    comment::String
  end

#= Info specific for an algorithm item. =#
  struct ALGORITHMITEM <: AlgorithmItem
    algorithm_ #= algorithm =#::Algorithm
    comment #= comment =#::Option{Comment}
    info #= line number =#::Info
  end

  struct ALGORITHMITEMCOMMENT <: AlgorithmItem
    comment::String
  end

#= Information on one (kind) of equation, different constructors for different
kinds of equations =#
  struct EQ_IF <: Equation
    ifExp #= Conditional expression =#::Exp
    equationTrueItems #= true branch =#::List{EquationItem}
    elseIfBranches #= elseIfBranches =#::List{Tuple{Exp, List{EquationItem}}}
    equationElseItems #= equationElseItems Standard 2-side eqn =#::List{EquationItem}
  end

  struct EQ_EQUALS <: Equation
    leftSide #= leftSide =#::Exp
    rightSide #= rightSide Connect stmt =#::Exp
  end

  struct EQ_PDE <: Equation
    leftSide #= leftSide =#::Exp
    rightSide #= rightSide Connect stmt =#::Exp
    domain #= domain for PDEs =#::ComponentRef
  end

  struct EQ_CONNECT <: Equation
    connector1 #= connector1 =#::ComponentRef
    connector2 #= connector2 =#::ComponentRef
  end

  struct EQ_FOR <: Equation
    iterators::ForIterators
    forEquations #= forEquations =#::List{EquationItem}
  end

  struct EQ_WHEN_E <: Equation
    whenExp #= whenExp =#::Exp
    whenEquations #= whenEquations =#::List{EquationItem}
    elseWhenEquations #= elseWhenEquations =#::List{Tuple{Exp, List{EquationItem}}}
  end

  struct EQ_NORETCALL <: Equation
    functionName #= functionName =#::ComponentRef
    functionArgs #= functionArgs; fcalls without return value =#::FunctionArgs
  end

  struct EQ_FAILURE <: Equation
    equ::EquationItem
  end

  #= Agentic Modelica: reconfigure block.
     Two modes depending on which optional field is present:
       - Agentic mode  (prompt present):       consults an external LLM agent.
       - VSS mode (modification present): applies assignments in modification block directly.
     The upon-clauses (now optional) constrain valid configurations in both modes. =#
  struct EQ_RECONFIGURE <: Equation
    variables         #= Optional structural parameter declarations =#::List{ElementItem}
    whenClauses       #= Trigger condition and optional invariant =#::List{WhenClause}
    prompt            #= Agentic mode: natural-language hint for LLM agent =#::Option{Exp}
    modification      #= VSS mode: equations assigning new parameter values =#::Option{List{EquationItem}}
    initialEquations  #= Constraints checked at recompilation time =#::Option{List{EquationItem}}
  end

#= A when-clause declares the agent trigger and an optional invariant.
   - WHEN_TRIGGER(E)         means E fires the agent (no post-condition).
   - WHEN_CONDITIONAL(C, E)  means C fires the agent; E must hold after reconfig. =#
  struct WHEN_TRIGGER <: WhenClause
    condition::Exp
  end
  struct WHEN_CONDITIONAL <: WhenClause
    condition::Exp
    constraint::Exp
  end

#= The Algorithm type describes one algorithm statement in an
algorithm section.  It does not describe a whole algorithm.  The
reason this type is named like this is that the name of the
grammar rule for algorithm statements is `algorithm\\'. =#
  struct ALG_ASSIGN <: Algorithm
    assignComponent #= assignComponent =#::Exp
    value #= value =#::Exp
  end

  struct ALG_IF <: Algorithm
    ifExp #= ifExp =#::Exp
    trueBranch #= trueBranch =#::List{AlgorithmItem}
    elseIfAlgorithmBranch #= elseIfAlgorithmBranch =#::List{Tuple{Exp, List{AlgorithmItem}}}
    elseBranch #= elseBranch =#::List{AlgorithmItem}
  end

  struct ALG_FOR <: Algorithm
    iterators::ForIterators
    forBody #= forBody =#::List{AlgorithmItem}
  end

  struct ALG_PARFOR <: Algorithm
    iterators::ForIterators
    parforBody #= parallel for loop Body =#::List{AlgorithmItem}
  end

  struct ALG_WHILE <: Algorithm
    boolExpr #= boolExpr =#::Exp
    whileBody #= whileBody =#::List{AlgorithmItem}
  end

  struct ALG_WHEN_A <: Algorithm
    boolExpr #= boolExpr =#::Exp
    whenBody #= whenBody =#::List{AlgorithmItem}
    elseWhenAlgorithmBranch #= elseWhenAlgorithmBranch =#::List{Tuple{Exp, List{AlgorithmItem}}}
  end

  struct ALG_NORETCALL <: Algorithm
    functionCall #= functionCall =#::ComponentRef
    functionArgs #= functionArgs; general fcalls without return value =#::FunctionArgs
  end

  struct ALG_RETURN <: Algorithm
  end

  struct ALG_BREAK <: Algorithm
  end

  #=  MetaModelica extensions
  =#

  struct ALG_FAILURE <: Algorithm
    equ::List{AlgorithmItem}
  end

  struct ALG_TRY <: Algorithm
    body::List{AlgorithmItem}
    elseBody::List{AlgorithmItem}
  end

  struct ALG_CONTINUE <: Algorithm
  end

#= Modifications are described by the `Modification\\' type.  There
are two forms of modifications: redeclarations and component
modifications.
- Modifications =#
  struct CLASSMOD <: Modification
    elementArgLst::List{ElementArg}
    eqMod::EqMod
  end

  struct NOMOD <: EqMod
  end

  struct EQMOD <: EqMod
    exp::Exp
    info::Info
  end

#= Wrapper for things that modify elements, modifications and redeclarations =#
  struct MODIFICATION <: ElementArg
    finalPrefix #= final prefix =#::Bool
    eachPrefix #= each =#::Each
    path::Path
    modification #= modification =#::Option{Modification}
    comment #= comment =#::Option{String}
    info::Info
  end

  struct REDECLARATION <: ElementArg
    finalPrefix #= final prefix =#::Bool
    redeclareKeywords #= redeclare  or replaceable  =#::RedeclareKeywords
    eachPrefix #= each prefix =#::Each
    elementSpec #= elementSpec =#::ElementSpec
    constrainClass #= class definition or declaration =#::Option{ConstrainClass}
    info #= needed because ElementSpec does not contain this info; Element does =#::Info
  end

  #= Selective model extension (Modelica 3.6), `extends A(break x)` or `extends A(break
     connect(a, b))`. `break x` is stored as connect(break, x), as omc does. =#
  struct INHERITANCEBREAK <: ElementArg
    cnct::Equation
    info::Info
  end

#= The keywords redeclare and replacable can be given in three different kombinations, each one by themself or the both combined. =#
  struct REDECLARE <: RedeclareKeywords
  end

  struct REPLACEABLE <: RedeclareKeywords
  end

  struct REDECLARE_REPLACEABLE <: RedeclareKeywords
  end

#= The each keyword can be present in both MODIFICATION\\'s and REDECLARATION\\'s.
- Each attribute =#
  struct EACH <: Each
  end

  struct NON_EACH <: Each
  end

#= Element attributes =#
  struct ATTR <: ElementAttributes
    flowPrefix #= flow =#::Bool
    streamPrefix #= stream =#::Bool
    parallelism #= for OpenCL/CUDA parglobal, parlocal ... =#::Parallelism
    variability #= parameter, constant etc. =#::Variability
    direction #= input/output =#::Direction
    isField #= non-field / field =#::IsField
    arrayDim #= array dimensions =#::ArrayDim
    isMode::Bool #= Specifies if this component is a structural mode component. =#
  end

#= Is field =#
  struct NONFIELD <: IsField
  end
  struct FIELD <: IsField
  end

#= Parallelism =#
  struct PARGLOBAL <: Parallelism
  end

  struct PARLOCAL <: Parallelism
  end

  struct NON_PARALLEL <: Parallelism
  end

  struct FLOW <: FlowStream
  end

  struct STREAM <: FlowStream
  end

  struct NOT_FLOW_STREAM <: FlowStream
  end

#= Variability =#
  struct VAR <: Variability
  end

  struct DISCRETE <: Variability
  end

  struct PARAM <: Variability
  end

  struct CONST <: Variability
  end

#= Direction =#
  struct INPUT <: Direction
  end

  struct OUTPUT <: Direction
  end

  struct BIDIR <: Direction
  end

  struct INPUT_OUTPUT <: Direction
  end

#= The Exp uniontype is the container of a Modelica expression.
- Expressions =#
  struct INTEGER <: Exp
    value::Int
  end

  struct REAL <: Exp
    value::String
  end

  struct CREF <: Exp
    componentRef::ComponentRef
  end

  struct STRING <: Exp
    value::String
  end

  struct BOOL <: Exp
    value::Bool
  end

  struct BINARY <: Exp
    exp1::Exp
    op::Operator
    exp2::Exp
  end

  struct UNARY <: Exp
    op #= op =#::Operator
    exp #= exp - any arithmetic expression =#::Exp
  end

  struct LBINARY <: Exp
    exp1 #= exp1 =#::Exp
    op #= op =#::Operator
    exp2::Exp
  end

  struct LUNARY <: Exp
    op #= op =#::Operator
    exp #= exp - any logical or relation expression =#::Exp
  end

  struct RELATION <: Exp
    exp1 #= exp1 =#::Exp
    op #= op =#::Operator
    exp2::Exp
  end

  struct IFEXP <: Exp
    ifExp #= ifExp =#::Exp
    trueBranch #= trueBranch =#::Exp
    elseBranch #= elseBranch =#::Exp
    elseIfBranch #= elseIfBranch Function calls =#::List{Tuple{Exp, Exp}}
  end

  struct CALL <: Exp
    function_ #= function =#::ComponentRef
    functionArgs::FunctionArgs
    typeVars::List{Path}
  end

  struct PARTEVALFUNCTION <: Exp
    function_ #= function =#::ComponentRef
    functionArgs::FunctionArgs
  end

  struct ARRAY <: Exp
    arrayExp::List{Exp}
  end

  struct MATRIX <: Exp
    matrix::List{List{Exp}}
  end

  struct RANGE <: Exp
    start #= start =#::Exp
    step #= step =#::Option{Exp}
    stop #= stop =#::Exp
  end

  struct TUPLE <: Exp
    expressions #= comma-separated expressions =#::List{Exp}
  end

  struct END <: Exp
  end

  struct CODE <: Exp
    code::CodeNode
  end

  #=  MetaModelica expressions follow below!
  =#

  struct AS <: Exp
    id #=  only an id  =#::Ident
    exp #=  expression to bind to the id  =#::Exp
  end

  struct CONS <: Exp
    head #=  head of the list  =#::Exp
    rest #=  rest of the list  =#::Exp
  end

  struct MATCHEXP <: Exp
    matchTy #=  match or matchcontinue       =#::MatchType
    inputExp #=  match expression of          =#::Exp
    localDecls #=  local declarations           =#::List{ElementItem}
    cases #=  case list + else in the end  =#::List{Case}
    comment #=  match expr comment_optional  =#::Option{String}
  end

  #= Compiler-internal expression types (not produced by the parser) =#

  struct LIST <: Exp
    exps::List{Exp}
  end

  struct DOT <: Exp
    exp::Exp
    index::Exp
  end

  #= Subscripted expression, e.g. array[index].
     Constructed programmatically by NFFrontEnd (enum conversion functions). =#
  struct SUBSCRIPTED_EXP <: Exp
    exp::Exp
    subscripts::List{Subscript}
  end

  #= Expression wrapped with before/after comments from the source.
     Upstream signature: EXPRESSIONCOMMENT(list<String>, Exp, list<String>).
     Not produced by OpenModelicaParser.jl (expression-level comment collection is missing). =#
  struct EXPRESSIONCOMMENT <: Exp
    commentBefore::List{String}
    exp::Exp
    commentAfter::List{String}
  end

  #= `break` as a modifier's value (Modelica 3.6, `x = break`): removes the binding. =#
  struct BREAK <: Exp
  end

#= case in match or matchcontinue =#
  struct CASE <: Case
    pattern #=  patterns to be matched  =#::Exp
    patternGuard::Option{Exp}
    patternInfo #= file information of the pattern =#::Info
    localDecls #=  local decls  =#::List{ElementItem}
    classPart #=  equation or algorithm section  =#::ClassPart
    result #=  result  =#::Exp
    resultInfo #= file information of the result-exp =#::Info
    comment #=  comment after case like: case pattern string_comment  =#::Option{String}
    info #= file information of the whole case =#::Info
  end

  struct ELSE <: Case
    localDecls #=  local decls  =#::List{ElementItem}
    classPart #=  equation or algorithm section  =#::ClassPart
    result #=  result  =#::Exp
    resultInfo #= file information of the result-exp =#::Info
    comment #=  comment after case like: case pattern string_comment  =#::Option{String}
    info #= file information of the whole case =#::Info
  end

  struct MATCH <: MatchType
  end

  struct MATCHCONTINUE <: MatchType
  end

#= The Code uniontype is used for Meta-programming. It originates from the $Code quoting mechanism. See paper in Modelica2003 conference =#
  struct C_TYPENAME <: CodeNode
    path::Path
  end

  struct C_VARIABLENAME <: CodeNode
    componentRef::ComponentRef
  end

  struct C_CONSTRAINTSECTION <: CodeNode
    boolean::Bool
    equationItemLst::List{EquationItem}
  end

  struct C_EQUATIONSECTION <: CodeNode
    boolean::Bool
    equationItemLst::List{EquationItem}
  end

  struct C_ALGORITHMSECTION <: CodeNode
    boolean::Bool
    algorithmItemLst::List{AlgorithmItem}
  end

  struct C_ELEMENT <: CodeNode
    element::Element
  end

  struct C_EXPRESSION <: CodeNode
    exp::Exp
  end

  struct C_MODIFICATION <: CodeNode
    modification::Modification
  end

#= The FunctionArgs uniontype consists of a list of positional arguments
followed by a list of named arguments (Modelica v2.0) =#
  struct FUNCTIONARGS <: FunctionArgs
    args #= args =#::List{Exp}
    argNames #= argNames =#::List{NamedArg}
  end

  struct FOR_ITER_FARG <: FunctionArgs
    exp #= iterator expression =#::Exp
    iterType::ReductionIterType
    iterators::ForIterators
  end

const emptyFunctionArgs = FUNCTIONARGS(list(), list())::FunctionArgs

  struct COMBINE <: ReductionIterType
  end

  struct THREAD <: ReductionIterType
  end

#= The NamedArg uniontype consist of an Identifier for the argument and an expression
giving the value of the argument =#
  struct NAMEDARG <: NamedArg
    argName #= argName =#::Ident
    argValue #= argValue =#::Exp
  end

#= Expression operators =#
  #= /* arithmetic operators */ =#

  struct ADD <: Operator
  end

  struct SUB <: Operator
  end

  struct MUL <: Operator
  end

  struct DIV <: Operator
  end

  struct POW <: Operator
  end

  struct UPLUS <: Operator
  end

  struct UMINUS <: Operator
  end

  #= /* element-wise arithmetic operators */ =#

  struct ADD_EW <: Operator
  end

  struct SUB_EW <: Operator
  end

  struct MUL_EW <: Operator
  end

  struct DIV_EW <: Operator
  end

  struct POW_EW <: Operator
  end

  struct UPLUS_EW <: Operator
  end

  struct UMINUS_EW <: Operator
  end

  #= /* logical operators */ =#

  struct AND <: Operator
  end

  struct OR <: Operator
  end

  struct NOT <: Operator
  end

  #= /* relational operators */ =#

  struct LESS <: Operator
  end

  struct LESSEQ <: Operator
  end

  struct GREATER <: Operator
  end

  struct GREATEREQ <: Operator
  end

  struct EQUAL <: Operator
  end

  struct NEQUAL <: Operator
  end

#= The Subscript uniontype is used both in array declarations and
component references.  This might seem strange, but it is
inherited from the grammar.  The NOSUB constructor means that
the dimension size is undefined when used in a declaration, and
when it is used in a component reference it means a slice of the
whole dimension.
- Subscripts =#
  struct NOSUB <: Subscript
  end

  struct SUBSCRIPT <: Subscript
    subscript #= subscript =#::Exp
  end

#= A component reference is the fully or partially qualified name of
a component.  It is represented as a list of
identifier--subscript pairs.
- Component references and paths =#
  struct CREF_FULLYQUALIFIED <: ComponentRef
    componentRef::ComponentRef
  end

  struct CREF_QUAL <: ComponentRef
    name #= name =#::Ident
    subscripts #= subscripts =#::List{Subscript}
    componentRef #= componentRef =#::ComponentRef
  end

  struct CREF_IDENT <: ComponentRef
    name #= name =#::Ident
    subscripts #= subscripts =#::List{Subscript}
  end

  struct WILD <: ComponentRef
  end

  struct ALLWILD <: ComponentRef
  end

#= The type `Path\\', on the other hand,
is used to store references to class names, or names inside
class definitions. =#
  struct QUALIFIED <: Path
    name #= name =#::Ident
    path #= path =#::Path
  end

  struct IDENT <: Path
    name #= name =#::Ident
  end

  struct FULLYQUALIFIED <: Path
    path::Path
  end

#= These constructors each correspond to a different kind of class
declaration in Modelica, except the last four, which are used
for the predefined types.  The parser assigns each class
declaration one of the restrictions, and the actual class
definition is checked for conformance during translation.  The
predefined types are created in the Builtin module and are
assigned special restrictions.
=#
  struct R_CLASS <: Restriction
  end

  struct R_OPTIMIZATION <: Restriction
  end

  struct R_MODEL <: Restriction
  end

  struct R_RECORD <: Restriction
  end

  struct R_BLOCK <: Restriction
  end

  struct R_CONNECTOR <: Restriction
  end

  struct R_EXP_CONNECTOR <: Restriction
  end

  struct R_TYPE <: Restriction
  end

  struct R_PACKAGE <: Restriction
  end

  struct R_FUNCTION <: Restriction
    functionRestriction::FunctionRestriction
  end

  struct R_OPERATOR <: Restriction
  end

  struct R_OPERATOR_RECORD <: Restriction
  end

  struct R_ENUMERATION <: Restriction
  end

  struct R_PREDEFINED_INTEGER <: Restriction
  end

  struct R_PREDEFINED_REAL <: Restriction
  end

  struct R_PREDEFINED_STRING <: Restriction
  end

  struct R_PREDEFINED_BOOLEAN <: Restriction
  end

  struct R_PREDEFINED_ENUMERATION <: Restriction
  end

  #=  BTH
  =#

  struct R_PREDEFINED_CLOCK <: Restriction
  end

  #=  MetaModelica
  =#

  struct R_UNIONTYPE <: Restriction
  end

  struct R_METARECORD <: Restriction

    #= MetaModelica extension, added by simbj
    =#
    name::Path
    #= Name of the uniontype
    =#
    index::Int
    #= Index in the uniontype
    =#
    singleton::Bool
    moved::Bool
    #=  true if moved outside uniontype, otherwise false.
    =#
    typeVars::List{String}
  end

  struct R_UNKNOWN <: Restriction
  end

  #= /* added by simbj */ =#

#= function purity =#
  struct PURE <: FunctionPurity
  end

  struct IMPURE <: FunctionPurity
  end

  struct NO_PURITY <: FunctionPurity
  end

  struct FR_NORMAL_FUNCTION <: FunctionRestriction
    purity #= function purity =#::FunctionPurity
  end

  struct FR_OPERATOR_FUNCTION <: FunctionRestriction
  end

  struct FR_PARALLEL_FUNCTION <: FunctionRestriction
  end

  struct FR_KERNEL_FUNCTION <: FunctionRestriction
  end

#= An Annotation is a class_modification.
- Annotation =#
  struct ANNOTATION <: Annotation
    elementArgs #= elementArgs =#::List{ElementArg}
  end

#= Comment =#
  struct COMMENT <: Comment
    annotation_ #= annotation =#::Option{Annotation}
    comment #= comment =#::Option{String}
  end

#= Declaration of an external function call - ExternalDecl =#
  struct EXTERNALDECL <: ExternalDecl
    funcName #= The name of the external function =#::Option{Ident}
    lang #= Language of the external function =#::Option{String}
    output_ #= output parameter as return value =#::Option{ComponentRef}
    args #= only positional arguments, i.e. expression list =#::List{Exp}
    annotation_::Option{Annotation}
  end

  struct RCR <: Ref
    cr::ComponentRef
  end

  struct RTS <: Ref
    ts::TypeSpec
  end

  struct RIM <: Ref
    im::Import
  end

#= Controls output of error-messages =#
  struct MSG <: Msg
    info::Info
  end

  struct NO_MSG <: Msg
  end

#= Modelica pretty-printing functions (dumpExp, dumpCref, dumpTypeSpec, etc.) =#
include("absynDump.jl")

#= Ordering on Path so that sort() works (needed by NFFrontEnd for derivative/inverse annotations).
   Self-contained reimplementation of AbsynUtil.pathCompare to avoid circular dependency. =#
function _pathCompare(p1::Path, p2::Path)::Int
  if p1 isa FULLYQUALIFIED || p2 isa FULLYQUALIFIED
    p1 isa FULLYQUALIFIED && p2 isa FULLYQUALIFIED && return _pathCompare(p1.path, p2.path)
    return p1 isa FULLYQUALIFIED ? 1 : -1
  elseif p1 isa QUALIFIED || p2 isa QUALIFIED
    if p1 isa QUALIFIED && p2 isa QUALIFIED
      local c::Int = cmp(p1.name, p2.name)
      return c != 0 ? c : _pathCompare(p1.path, p2.path)
    end
    return p1 isa QUALIFIED ? 1 : -1
  end
  return cmp((p1::IDENT).name, (p2::IDENT).name)
end

Base.isless(p1::Path, p2::Path) = _pathCompare(p1, p2) < 0

#= So that we can use wildcard imports and named imports when they do occur. Not good Julia practice =#
@exportAll()
end
