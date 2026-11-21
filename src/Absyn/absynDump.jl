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

#=
  Modelica pretty-printing for Absyn types.
  Used by the Dump module for error messages in NFFrontEnd.
  Reference: AbsynDumpTpl.tpl from OMCompiler/Compiler/Template/
=#

# --- Path ---

dumpPath(p::FULLYQUALIFIED)::String = "." * dumpPath(p.path)
dumpPath(p::QUALIFIED)::String = p.name * "." * dumpPath(p.path)
dumpPath(p::IDENT)::String = p.name

# --- ComponentRef ---

dumpCref(cr::CREF_QUAL)::String = cr.name * dumpSubscripts(cr.subscripts) * "." * dumpCref(cr.componentRef)
dumpCref(cr::CREF_IDENT)::String = cr.name * dumpSubscripts(cr.subscripts)
dumpCref(cr::CREF_FULLYQUALIFIED)::String = "." * dumpCref(cr.componentRef)
dumpCref(::WILD)::String = "_"
dumpCref(::ALLWILD)::String = "__"
dumpCref(::ComponentRef)::String = "<unknown cref>"

# --- Subscripts ---

function dumpSubscripts(subs)::String
  local lst = collect(subs)
  isempty(lst) && return ""
  "[" * join((dumpSubscript(s) for s in lst), ", ") * "]"
end

dumpSubscript(::NOSUB)::String = ":"
dumpSubscript(sub::SUBSCRIPT)::String = dumpExp(sub.subscript)

# --- Expression ---

dumpExp(exp::INTEGER)::String = string(exp.value)
dumpExp(exp::REAL)::String = exp.value
dumpExp(exp::STRING)::String = "\"" * exp.value * "\""
dumpExp(exp::BOOL)::String = exp.value ? "true" : "false"
dumpExp(exp::CREF)::String = dumpCref(exp.componentRef)
dumpExp(exp::BINARY)::String = dumpBinary(exp.exp1, exp.op, exp.exp2, dumpPrecedence(exp))
dumpExp(exp::UNARY)::String = dumpOperator(exp.op) * dumpOperand(exp.exp, dumpPrecedence(exp), true)
dumpExp(exp::LBINARY)::String = dumpBinary(exp.exp1, exp.op, exp.exp2, dumpPrecedence(exp))
dumpExp(exp::LUNARY)::String = dumpOperator(exp.op) * dumpOperand(exp.exp, dumpPrecedence(exp), true)
dumpExp(exp::RELATION)::String =
  dumpOperand(exp.exp1, dumpPrecedence(exp), true) * dumpOperator(exp.op) * dumpOperand(exp.exp2, dumpPrecedence(exp), true)
function dumpExp(exp::IFEXP)::String
  local s::String = "if " * dumpExp(exp.ifExp) * " then " * dumpExp(exp.trueBranch)
  for (c, b) in exp.elseIfBranch
    s = s * " elseif " * dumpExp(c) * " then " * dumpExp(b)
  end
  return s * " else " * dumpExp(exp.elseBranch)
end
dumpExp(exp::CALL)::String = dumpCref(exp.function_) * "(" * dumpFunctionArgs(exp.functionArgs) * ")"
dumpExp(exp::PARTEVALFUNCTION)::String =
  "function " * dumpCref(exp.function_) * "(" * dumpFunctionArgs(exp.functionArgs) * ")"
dumpExp(exp::ARRAY)::String = "{" * join((dumpExp(e) for e in exp.arrayExp), ", ") * "}"
dumpExp(exp::MATRIX)::String = "[" * join((join((dumpExp(e) for e in row), ", ") for row in exp.matrix), "; ") * "]"
function dumpExp(exp::RANGE)::String
  local s::String = dumpExp(exp.start)
  if !isnothing(exp.step)
    s = s * ":" * dumpExp(exp.step.value)
  end
  return s * ":" * dumpExp(exp.stop)
end
dumpExp(exp::TUPLE)::String = "(" * join((dumpExp(e) for e in exp.expressions), ", ") * ")"
dumpExp(::END)::String = "end"
dumpExp(::CODE)::String = "\$Code(...)"
dumpExp(exp::AS)::String = exp.id * " as " * dumpExp(exp.exp)
dumpExp(exp::CONS)::String = dumpExp(exp.head) * " :: " * dumpExp(exp.rest)
dumpExp(exp::LIST)::String = "{" * join((dumpExp(e) for e in exp.exps), ", ") * "}"
dumpExp(exp::DOT)::String = dumpExp(exp.exp) * "." * dumpExp(exp.index)
dumpExp(exp::SUBSCRIPTED_EXP)::String = "(" * dumpExp(exp.exp) * ")" * dumpSubscripts(exp.subscripts)
dumpExp(exp::EXPRESSIONCOMMENT)::String = dumpExp(exp.exp)
dumpExp(::Exp)::String = "<unknown exp>"

# --- Precedence: parentheses where Modelica needs them ---

"""
How tightly an expression binds, higher is tighter: if-expressions and ranges, `or`, `and`, `not`, relations,
`+ -`, `* /`, unary `+ -`, `^`, then primaries. Unary minus binds tighter than `*` (`-a*x`) and
looser than `^` (`(-a)^2`).
"""
function dumpPrecedence(exp::Exp)::Int
  if exp isa IFEXP || exp isa RANGE
    return 0
  elseif exp isa LBINARY
    return exp.op isa OR ? 1 : 2
  elseif exp isa LUNARY
    return 3
  elseif exp isa RELATION
    return 4
  elseif exp isa BINARY
    return exp.op isa Union{POW, POW_EW} ? 8 : exp.op isa Union{MUL, DIV, MUL_EW, DIV_EW} ? 6 : 5
  elseif exp isa UNARY
    return 7
  end
  return 10
end

"""An operand in parentheses when it binds looser than its operator, or as tightly with `tight`."""
function dumpOperand(exp::Exp, precedence::Int, tight::Bool)::String
  local p::Int = dumpPrecedence(exp)
  local s::String = dumpExp(exp)
  return (p < precedence || (tight && p == precedence)) ? "(" * s * ")" : s
end

"""
A binary or logical operation: the right operand in parentheses also when it binds as tightly (`a - (b - c)`) or is
a unary operation (`a + (-b)`: Modelica allows a unary operator only at the start); `^` takes no operator
expression unparenthesised on either side.
"""
function dumpBinary(exp1::Exp, op::Operator, exp2::Exp, precedence::Int)::String
  local right::String = exp2 isa UNARY ? "(" * dumpExp(exp2) * ")" : dumpOperand(exp2, precedence, true)
  return dumpOperand(exp1, precedence, precedence == 8) * dumpOperator(op) * right
end

# --- Operator ---

dumpOperator(::ADD)::String = " + "
dumpOperator(::SUB)::String = " - "
dumpOperator(::MUL)::String = "*"
dumpOperator(::DIV)::String = "/"
dumpOperator(::POW)::String = "^"
dumpOperator(::UPLUS)::String = "+"
dumpOperator(::UMINUS)::String = "-"
dumpOperator(::ADD_EW)::String = " .+ "
dumpOperator(::SUB_EW)::String = " .- "
dumpOperator(::MUL_EW)::String = ".*"
dumpOperator(::DIV_EW)::String = "./"
dumpOperator(::POW_EW)::String = ".^"
dumpOperator(::UPLUS_EW)::String = ".+"
dumpOperator(::UMINUS_EW)::String = ".-"
dumpOperator(::AND)::String = " and "
dumpOperator(::OR)::String = " or "
dumpOperator(::NOT)::String = "not "
dumpOperator(::LESS)::String = " < "
dumpOperator(::LESSEQ)::String = " <= "
dumpOperator(::GREATER)::String = " > "
dumpOperator(::GREATEREQ)::String = " >= "
dumpOperator(::EQUAL)::String = " == "
dumpOperator(::NEQUAL)::String = " <> "
dumpOperator(::Operator)::String = " <unknown op> "

# --- FunctionArgs ---

function dumpFunctionArgs(args::FUNCTIONARGS)::String
  local pos::String = join((dumpExp(a) for a in args.args), ", ")
  local named::String = join((dumpNamedArg(na) for na in args.argNames), ", ")
  if !isempty(pos) && !isempty(named)
    return pos * ", " * named
  end
  return isempty(pos) ? named : pos
end
function dumpFunctionArgs(args::FOR_ITER_FARG)::String
  local iters::String = join((dumpForIterator(i) for i in args.iterators), ", ")
  local thread::String = args.iterType isa THREAD ? "threaded " : ""
  return dumpExp(args.exp) * " " * thread * "for " * iters
end

dumpNamedArg(na::NAMEDARG)::String = na.argName * " = " * dumpExp(na.argValue)

function dumpForIterator(it::ITERATOR)::String
  local s::String = it.name
  if !isnothing(it.guardExp)
    s = s * " guard " * dumpExp(it.guardExp.value)
  end
  if !isnothing(it.range)
    s = s * " in " * dumpExp(it.range.value)
  end
  return s
end

# --- TypeSpec ---

function dumpTypeSpec(ts::TPATH)::String
  local s::String = dumpPath(ts.path)
  if !isnothing(ts.arrayDim)
    s = s * dumpSubscripts(collect(ts.arrayDim.value))
  end
  return s
end
function dumpTypeSpec(ts::TCOMPLEX)::String
  local s::String = dumpPath(ts.path) * "<" * join((dumpTypeSpec(t) for t in ts.typeSpecs), ", ") * ">"
  if !isnothing(ts.arrayDim)
    s = s * dumpSubscripts(collect(ts.arrayDim.value))
  end
  return s
end

# --- Direction ---

dumpDirection(::BIDIR)::String = ""
dumpDirection(::INPUT)::String = "input "
dumpDirection(::OUTPUT)::String = "output "
dumpDirection(::Direction)::String = ""
