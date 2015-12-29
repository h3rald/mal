import 
  readline,
  regex,
  types,
  reader,
  printer,
  tables, 
  sequtils,
  strutils

const
  PROMPT = "user> "

var 
  r: Reader
  p: Printer

proc read(prompt = PROMPT): Node =
  var line = readline(prompt)
  historyAdd(line)
  r = line.readStr()
  return r.readForm()

proc print(n: Node) =
  echo p.prStr(n)

proc eval(ast: Node, env: NodeHash): Node

proc eval_ast(ast: Node, env: NodeHash): Node = 
  var p:Printer
  case ast.kind:
    of nSymbol:
      var hashkey: string
      hashkey = "sym:" & ast.symbolVal
      dbg:
        echo "EVAL_AST: symbol: " & ast.symbolVal
      if env.hasKey(hashKey):
        return env[hashkey]
      else:
        error "Symbol '$1' not found" % [ast.symbolVal]
    of nList:
      dbg:
        echo "EVAL_AST: list"
      return newList(map(ast.listVal, proc(n: Node): Node = return eval(n, env)))
    of nVector:
      dbg:
        echo "EVAL_AST: vector"
      return newVector(map(ast.vectorVal, proc(n: Node): Node = return eval(n, env)))
    of nHashMap:
      dbg:
        echo "EVAL_AST: hashmap"
      var hash = initTable[string, Node]()
      for k, v in ast.hashVal.pairs:
        hash[k] = eval(v, env)
      return newHashMap(hash)
    else:
      dbg:
        echo "EVAL_AST: literal: " & p.prStr(ast)
      return ast

proc apply(list: Node): Node =
  let f = list.listVal[0]
  let args = list.listVal[1 .. list.listVal.len-1]
  return f.procVal(args)


proc eval(ast: Node, env: NodeHash): Node = 
  if ast.kind != nList:
    return eval_ast(ast, env)
  else:
    var list = eval_ast(ast, env)
    if (list.listVal[0].kind == nProc):
      return apply(list)
    else:
      return list

proc rep(env: NodeHash) = 
  print(eval(read(), env))

##########

var repl_env = initTable[string, Node]()

repl_env.add("sym:+", newProc(proc(ns: varargs[Node]): Node = return newInt(ns[0].intVal + ns[1].intVal)))
repl_env.add("sym:-", newProc(proc(ns: varargs[Node]): Node = return newInt(ns[0].intVal - ns[1].intVal)))
repl_env.add("sym:*", newProc(proc(ns: varargs[Node]): Node = return newInt(ns[0].intVal * ns[1].intVal)))
repl_env.add("sym:/", newProc(proc(ns: varargs[Node]): Node = return newInt(int(ns[0].intVal / ns[1].intVal))))


while true:
  rep(repl_env)
