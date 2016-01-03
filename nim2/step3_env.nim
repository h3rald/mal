import 
  tables, 
  sequtils,
  strutils,
  readline,
  regex

import
  types,
  reader,
  printer,
  env

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

proc eval(ast: Node, env: Env): Node

proc eval_ast(ast: Node, env: Env): Node = 
  var p:Printer
  case ast.kind:
    of Symbol:
      let val = ast.stringVal
      var hashkey: string
      hashkey = ast.stringVal
      dbg:
        echo "EVAL_AST: symbol: " & ast.stringVal
      return env.get(hashkey)
    of List:
      dbg:
        echo "EVAL_AST: list"
      return newList(map(ast.seqVal, proc(n: Node): Node = return eval(n, env)))
    of Vector:
      dbg:
        echo "EVAL_AST: vector"
      return newVector(map(ast.seqVal, proc(n: Node): Node = return eval(n, env)))
    of HashMap:
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

proc apply(f, list: Node): Node =
  let args = list.seqVal[1 .. list.seqVal.len-1]
  return f.procVal(args)

proc applySpec(f, list: Node, env: Env): Node =
  let args = list.seqVal[1 .. list.seqVal.len-1]
  return f.specProcVal(args, env)


proc eval(ast: Node, env: Env): Node = 
  case ast.kind:
    of List:
      # Evaluate the first item of the list, check if it's a known symbol
      var evalSym = eval_ast(ast.seqVal[0], env)
      case evalSym.kind:
        of Proc:
          dbg:
            echo "EVAL: normal form"
          # Apply normal form to evaluated AST
          return apply(evalSym, eval_ast(ast, env))
        of SpecProc:
          dbg:
            echo "EVAL: special form"
          # Apply special form to unevaluated AST
          return applySpec(evalSym, ast, env)
        else:
          return eval_ast(ast, env)
    else:
      return eval_ast(ast, env)

proc rep(env: Env) = 
  print(eval(read(), env))



#### SPECIAL FORMS ####

defspec "def!", args, env:
  dbg:
    echo "def!: called"
  var evaluated = eval(args[1], env)
  env.set(args[0].stringVal, evaluated)
  return evaluated

defspec "let*", args, env:
  var nEnv = newEnv("let*", env)
  var blist: seq[Node]
  case args[0].kind:
    of List, Vector:
      blist = args[0].seqVal
    else:
      error("let*: The first parameter must be a list.")
      return
  if blist.len mod 2 != 0:
    error("let*: The first parameter must be a list of even elemenets")
  var c = 0
  while c<blist.len:
    nEnv.set(blist[c].stringVal, eval(blist[c+1], nEnv))
    c.inc(2)
  return eval(args[1], nEnv)

#### REPL ####

while true:
  rep(MAINENV)
