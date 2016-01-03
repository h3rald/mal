import 
  tables,
  strutils,
  sequtils

import 
  types,
  printer


proc set*(env: Env, sym: string, n: Node): Node {.discardable.}=
  var p:Printer
  dbg:
    echo "ENV($1) SET: $2 = $3" % [env.name, sym, p.prStr(n)]
  if env.data.hasKey(sym):
    # TODO check -- otherwise it generates duplicated entries
    env.data.del(sym)
  env.data[sym] = n
  return n

proc newEnv(nBinds, nExprs: Node): Env =
  var p:Printer
  new(result)
  result.data = initTable[string, Node]()
  result.name = "closure"
  var binds = newSeq[Node]()
  var exprs = newSeq[Node]()
  if nBinds.kind in {List, Vector}:
    binds = nBinds.seqVal
  if nExprs.kind in {List, Vector}:
    exprs = nExprs.seqVal
  dbg:
    echo "binds($1) -> exprs($2)" % [$binds.len, $exprs.len]
  for i in 0..binds.len-1:
    if binds[i].stringVal == "&": # Clojure-style variadic operator
      if exprs.len == 0:
        discard result.set(binds[i+1].stringVal, newList(exprs))
      else:
        discard result.set(binds[i+1].stringVal, newList(exprs[i .. ^1]))
      break
    else:
      discard result.set(binds[i].stringVal, exprs[i])

proc newEnv*(name: string): Env =
  result = newEnv(nBinds = newNil(), nExprs = newNil())
  result.name = name

proc newEnv*(name: string, outer: Env): Env =
  result = newEnv(nBinds = newNil(), nExprs = newNil())
  result.name = name
  result.outer = outer

proc newEnv*(name: string, outer: Env, binds, exprs: Node): Env =
  result = newEnv(binds, exprs)
  result.name = name
  result.outer = outer

proc copy*(env: Env, orig, alias: string) =
  dbg:
    echo "ENV($1) COPY: $2 -> $3" % [env.name, orig, alias]
  env.data[alias] = env.data[orig]


proc lookup*(env: Env, sym: string): Env =
  if env.data.hasKey(sym):
    dbg:
      echo "ENV($1) LOOKUP: symbol '$2' found" % [env.name, sym]
    return env
  else:
    if env.outer != nil:
      return env.outer.lookup(sym)
    else: 
      dbg:
        echo "ENV($1) LOOKUP: symbol '$2' not found" % [env.name, sym]
      return nil

proc get*(env: Env, sym: string): Node = 
  let res = env.lookup(sym)
  if res != nil:
    return res.data[sym]
  else:
    error "Symbol '$1' not found." % sym

### Main Environment

var MAINENV* = newEnv("main")

proc defineFunction(sym: string, p: NodeProc) =
  discard MAINENV.set(sym, newNativeProc(p))

proc defconst*(sym: string, n: Node) = 
  discard MAINENV.set(sym, n)

proc defalias*(alias, orig: string) =
  MAINENV.copy(orig, alias)

template defun*(s: string, args: expr, body: stmt): stmt {.immediate.} =
  defineFunction(s) do (args: varargs[Node]) -> Node:
    body

### Constants

defconst "true", newBool(true)

defconst "false", newBool(false)

defconst "nil", newNil()

### Functions

defun "+", args:
  return newInt(args[0].intVal + args[1].intVal)

defun "-", args:
  return newInt(args[0].intVal - args[1].intVal)

defun "*", args:
  return newInt(args[0].intVal * args[1].intVal)

defun "/", args:
  return newInt(int(args[0].intVal / args[1].intVal))

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

defun "=", args:
  return newBool(args[0] == args[1])

defun "<", args:
  return newBool(args[0].intVal < args[1].intVal)

defun "<=", args:
  return newBool(args[0].intVal <= args[1].intVal)

defun ">", args:
  return newBool(args[0].intVal > args[1].intVal)

defun ">=", args:
  return newBool(args[0].intVal >= args[1].intVal)

defun "debug", args:
  if args[0].falsy:
    DEBUG = false
    return newBool(false)
  else:
    DEBUG = true
    return newBool(true)

### String Functions

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

