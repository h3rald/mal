import
  sequtils,
  strutils

import
  types,
  reader,
  printer,
  env

### Constants

defconst "true", newBool(true)

defconst "false", newBool(false)

defconst "nil", newNil()

### Functions working with all types

defun "=", args:
  return newBool(args[0] == args[1])

defun "throw", args:
  raise (ref LangException)(value: newList(args))

defun "apply", args:
  let f = args[0]
  var list = newSeq[Node]()
  if args.len > 2:
    for i in 1 .. args.high-1:
      list.add args[i]
  list.add args[args.high].seqVal
  return f.getFun()(list)

defun "map", args:
  result = newList()
  for i in 0 .. args[1].seqVal.high:
    result.seqVal.add args[0].getFun()(args[1].seqVal[i])

### Constructors

defun "symbol", args:
  return newSymbol(args[0].stringVal)

defun "keyword", args:
  if args[0].kind == Keyword:
    return args[0]
  else:
    return newKeyword(":" & args[0].stringVal)

defun "list", args:
  var list = newSeq[Node]()
  for a in args:
    list.add(a)
  return newList(list)

defun "vector", args:
  var list = newSeq[Node]()
  for a in args:
    list.add(a)
  return newVector(list)

### Predicates

defun "nil?", args:
  return newBool(args[0] == newNil())

defun "true?", args:
  return newBool(args[0] == newBool(true))

defun "false?", args:
  return newBool(args[0] == newBool(false))

defun "symbol?", args:
  return newBool(args[0].kind == Symbol)

defun "keyword?", args:
  return newBool(args[0].kind == Keyword)

defun "empty?", args:
  case args[0].kind
  of List, Vector:
    if args[0].seqVal.len == 0:
      return newBool(true)
  else:
    error "empty?: First argument is not a list or vector"
  return newBool(false)

defun "list?", args:
  return newBool(args[0].kind == List)

defun "vector?", args:
  return newBool(args[0].kind == Vector)

defun "sequential?", args:
  return newBool(args[0].kind in {List, Vector})

defun "map?", args:
  return newBool(args[0].kind == HashMap)

### Numeric Functions

defun "<", args:
  return newBool(args[0].intVal < args[1].intVal)

defun "<=", args:
  return newBool(args[0].intVal <= args[1].intVal)

defun ">", args:
  return newBool(args[0].intVal > args[1].intVal)

defun ">=", args:
  return newBool(args[0].intVal >= args[1].intVal)

defun "+", args:
  return newInt(args[0].intVal + args[1].intVal)

defun "-", args:
  return newInt(args[0].intVal - args[1].intVal)

defun "*", args:
  return newInt(args[0].intVal * args[1].intVal)

defun "/", args:
  return newInt(int(args[0].intVal / args[1].intVal))

### List/Vector Functions

defun "count", args:
  case args[0].kind:
  of Nil:
    return newInt(0)
  of List, Vector:
    return newInt(args[0].seqVal.len)
  else:
    error "count: First argument is not a list or vector"

defun "cons", args:
  var list = newSeq[Node]()
  list.add args[0]
  return newList(list & args[1].seqVal)

defun "concat", args:
  var list: seq[Node]
  for arg in args:
    list = list & arg.seqVal
  return newList(list)

defun "nth", args:
  return args[0].seqVal[args[1].intVal]

defun "first", args:
  if args[0].seqVal.len == 0:
    return newNil()
  return args[0].seqVal[0]

defun "rest", args:
  if args[0].seqVal.len == 0:
    return newList(args[0].seqVal)
  return newList(args[0].seqVal[1 .. ^1])

### String Functions

defun "read-string", args:
  return readStr(args[0].stringVal)

defun "pr-str", args:
  return newString(args.map(proc(n: Node): string = return $n).join(" "))

defun "str", args:
  return newString(args.map(proc(n: Node): string = return $~n).join())

defun "prn", args:
  echo args.map(proc(n: Node): string = return $n).join(" ")
  return newNil()

defun "println", args:
  echo args.map(proc(n: Node): string = return $~n).join(" ")
  return newNil()

defun "slurp", args:
  return newString(readFile(args[0].stringVal))

### Other Functions

defun "debug", args:
  if args[0].falsy:
    DEBUG = false
    return newBool(false)
  else:
    DEBUG = true
    return newBool(true)


