import 
  tables,
  strutils

import 
  types,
  printer


proc set*(env: Env, sym: string, n: Node)

proc newEnv(binds, exprs: seq[Node]): Env =
  new(result)
  result.data = initTable[string, Node]()
  result.name = "closure"
  dbg:
    echo "binds($1) -> exprs($2)" % [$binds.len, $exprs.len]
  for i in 0..binds.len-1:
    result.set(binds[i].symbolVal, exprs[i]) # TODO check if right... should expr be evaluated?

proc newEnv*(name: string): Env =
  result = newEnv(newSeq[Node](), newSeq[Node]())
  result.name = name

proc newEnv*(name: string, outer: Env): Env =
  result = newEnv(newSeq[Node](), newSeq[Node]())
  result.name = name
  result.outer = outer

proc newEnv*(name: string, outer: Env, binds, exprs: seq[Node]): Env =
  result = newEnv(binds, exprs)
  result.name = name
  result.outer = outer

proc set*(env: Env, sym: string, n: Node) =
  var p:Printer
  dbg:
    echo "ENV($1) SET: $2 = $3" % [env.name, sym, p.prStr(n)]
  let key = "sym:" & sym
  if env.data.hasKey(key):
    # TODO check -- otherwise it generates duplicated entries
    env.data.del(key)
  env.data[key] = n

proc copy*(env: Env, orig, alias: string) =
  dbg:
    echo "ENV($1) COPY: $2 -> $3" % [env.name, orig, alias]
  env.data["sym:" & alias] = env.data["sym:" & orig]


proc lookup*(env: Env, sym: string): Env =
  if env.data.hasKey("sym:" & sym):
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
    return res.data["sym:" & sym]
  else:
    error "Symbol '$1' not found." % sym

### Main Environment

var MAINENV* = newEnv("main")

proc defineSymbol(sym: string, p: NodeProc) =
  MAINENV.set(sym, newProc(p))

proc defineSpecialSymbol(sym: string, p: NodeSpecProc) =
  MAINENV.set(sym, newSpecProc(p))

proc defalias*(alias, orig: string) =
  MAINENV.copy(orig, alias)

template defsym*(s: string, args: expr, body: stmt): stmt {.immediate.} =
  defineSymbol(s) do (args: NodeArgs) -> Node:
    body

template defspec*(s: string, args, env: expr, body: stmt): stmt {.immediate.} =
  defineSpecialSymbol(s) do (args: NodeArgs, env: Env) -> Node:
    body

### Definitions


defsym "#t", args:
  return newBool(true)

defsym "#f", args:
  return newBool(false)

defsym "+", args:
  return newInt(args[0].intVal + args[1].intVal)

defsym "-", args:
  return newInt(args[0].intVal - args[1].intVal)

defsym "*", args:
  return newInt(args[0].intVal * args[1].intVal)

defsym "/", args:
  return newInt(int(args[0].intVal / args[1].intVal))

### Special Definitions

defspec "print-env", args, env:
  var p:Printer
  echo "Printing environment: $1" % env.name
  for k, v in env.data.pairs:
    echo "'$1'\t\t= $2" % [k, p.prStr(v)]
