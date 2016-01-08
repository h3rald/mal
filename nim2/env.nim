import 
  tables,
  strutils,
  sequtils

import 
  types,
  printer


proc set*(env: Env, sym: string, n: Node): Node {.discardable.} =
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
    return env
  else:
    if env.outer != nil:
      return env.outer.lookup(sym)
    else: 
      return nil

proc get*(env: Env, sym: string): Node = 
  let res = env.lookup(sym)
  if res != nil:
    return res.data[sym]
  else:
    raise newException(UnknownSymbolError, "'$1' not found" % sym)

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
