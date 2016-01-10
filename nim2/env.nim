import 
  tables,
  strutils,
  sequtils

import 
  types,
  printer


proc newEnv*(outer: Env = nil, binds, exprs: Node = newNil()): Env =
  result = Env(outer: outer, data: initTable[string, Node]())
  if binds.kind in {List, Vector}:
    for i, b in binds.seqVal:
      if b.stringVal == "&":
        var list: Node
        if exprs.seqVal.len == 0:
          list = newList(exprs.seqVal)
        else:
          list = newList(exprs.seqVal[i .. ^1])
        result.data.setKey(binds.seqVal[i+1].stringVal, list)
        break
      else:
        result.data.setKey(b.stringVal,  exprs.seqVal[i])

proc set*(env: Env, sym: string, n: Node): Node {.discardable.} =
  dbg:
    echo "ENV SET: $1 = $2" % [sym, $n]
  env.data.setKey(sym, n)
  return n

proc lookup*(env: Env, key: string): Env = 
  if env.data.hasKey(key):
    return env
  if not env.outer.isNil:
    return env.outer.lookup(key)

proc get*(env: Env, sym: string): Node = 
  let res = env.lookup(sym)
  if not res.isNil:
    return res.data[sym]
  else:
    raise newException(UnknownSymbolError, "'$1' not found" % sym)


#proc newEnv(nBinds, nExprs: Node): Env =
#  var p:Printer
#  new(result)
#  result.data = initTable[string, Node]()
#  result.name = "closure"
#  var binds = newSeq[Node]()
#  var exprs = newSeq[Node]()
#  if nBinds.kind in {List, Vector}:
#    binds = nBinds.seqVal
#  if nExprs.kind in {List, Vector}:
#    exprs = nExprs.seqVal
#  dbg:
#    echo "binds($1) -> exprs($2)" % [$binds.len, $exprs.len]
#  for i in 0..binds.len-1:
#    if binds[i].stringVal == "&": # Clojure-style variadic operator
#      if exprs.len == 0:
#        discard result.set(binds[i+1].stringVal, newList(exprs))
#      else:
#        discard result.set(binds[i+1].stringVal, newList(exprs[i .. ^1]))
#      break
#    else:
#      discard result.set(binds[i].stringVal, exprs[i])
#
#proc newEnv*(name: string): Env =
#  result = newEnv(nBinds = newNil(), nExprs = newNil())
#  result.name = name
#
#proc newEnv*(name: string, outer: Env): Env =
#  result = newEnv(nBinds = newNil(), nExprs = newNil())
#  result.name = name
#  result.outer = outer
#
#proc newEnv*(name: string, outer: Env, binds, exprs: Node): Env =
#  result = newEnv(binds, exprs)
#  result.name = name
#  result.outer = outer
#
#
### Main Environment

var MAINENV* = newEnv()

proc defineFunction(sym: string, p: NodeProc) =
  discard MAINENV.set(sym, newNativeProc(p))

proc defconst*(sym: string, n: Node) = 
  discard MAINENV.set(sym, n)

template defun*(s: string, args: expr, body: stmt): stmt {.immediate.} =
  defineFunction(s) do (args: varargs[Node]) -> Node:
    body

