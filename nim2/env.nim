import 
  tables,
  strutils

import 
  types,
  printer

proc newEnv*(name: string, outer: Env): Env =
  new(result)
  result.name = name
  result.outer = outer
  result.data = initTable[string, Node]()

proc newEnv*(name: string): Env =
  new(result)
  result.outer = nil
  result.name = name
  result.data = initTable[string, Node]()

proc set*(env: Env, sym: string, n: Node) =
  var p:Printer
  dbg:
    echo "ENV($1) SET: $2 = $3" % [env.name, sym, p.prStr(n)]
  let key = "sym:" & sym
  if env.data.hasKey(key):
    # TODO check -- otherwise it generates duplicated entries
    env.data.del(key)
  env.data[key] = n

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

var MAINENV* = newEnv("MAIN")

proc defineSymbol(sym: string, p: NodeProc) =
  MAINENV.set(sym, newProc(p))

proc defineSpecialSymbol(sym: string, p: NodeSpecProc) =
  MAINENV.set(sym, newSpecProc(p))

template defsym*(s: string, args: expr, body: stmt): stmt {.immediate.} =
  defineSymbol(s) do (args: NodeArgs) -> Node:
    body

template defspec*(s: string, args, env: expr, body: stmt): stmt {.immediate.} =
  defineSpecialSymbol(s) do (args: NodeArgs, env: Env) -> Node:
    body

### Definitions

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
