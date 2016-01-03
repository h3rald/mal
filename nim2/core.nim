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

defun "list", args:
  var list = newSeq[Node]()
  for a in args:
    list.add(a)
  return newList(list)

defun "list?", args:
  if args[0].kind == List:
    return newBool(true)
  else:
    return newBool(false)

defun "empty?", args:
  case args[0].kind
  of List, Vector:
    if args[0].seqVal.len == 0:
      return newBool(true)
  else:
    error "empty?: First argument is not a list or vector"
  return newBool(false)

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

