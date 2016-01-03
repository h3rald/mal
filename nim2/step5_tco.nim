import 
  tables, 
  sequtils,
  strutils,
  readline,
  regex,
  parseopt2

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

proc eval(orig_ast: Node, env: Env): Node

proc eval_ast(ast: Node, env: Env): Node = 
  var p:Printer
  case ast.kind:
    of Symbol:
      let val = ast.symbolVal
      var hashkey: string
      hashkey = ast.symbolVal
      dbg:
        echo "EVAL_AST: symbol: " & ast.symbolVal
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


proc eval(orig_ast: Node, env: Env): Node = 
  var ast = orig_ast
  while true:
    var p:Printer
    dbg:
      echo "EVAL: AST -> " & p.prStr(ast)
    case ast.kind:
      of List:
        dbg: 
          echo "EVAL: list"
        if ast.seqVal.len == 0:
          return ast
        let car = ast.seqVal[0]
        let cdr = ast.seqVal[1 .. ast.seqVal.len-1]
        case car.kind:
        of Proc:
          dbg:
            echo "EVAL: closure"
          if ast.env != nil:
            var fAst = ast.ast
            var fEnv = newEnv("closure", outer = ast.env, binds = ast.params, exprs = cdr)
            ast = apply(ast, eval_ast(fAst, fEnv))
            continue
          else:
            return apply(car, eval_ast(ast, env))
        of Symbol, List:
          # Evaluate the first item of the list, check if it is a known symbol
          var fun = eval(car, env)
          case fun.kind:
            of Proc:
              dbg:
                echo "EVAL: normal form"
              return apply(fun, eval_ast(ast, env))
            of SpecProc:
              dbg:
                echo "EVAL: special form"
              # Apply special form to unevaluated AST
              # TODO: check TCO!
              ast = applySpec(fun, ast, env)
              continue
            else:
              dbg:
                echo "EVAL: unknown form" # Unlikely...
              quit()
              return eval_ast(ast, env)
        else:
          return eval_ast(ast, env)
      else:
        dbg:
          echo "EVAL: other"
        return eval_ast(ast, env)

proc rep(env: Env) = 
  print(eval(read(), env))


proc defnative*(s: string) =
  var r: Reader = readStr(s)
  discard eval(r.readForm(), MAINENV)

#### SPECIAL FORMS ####

defspecfun "def!", args, env:
  dbg:
    echo "def!: called"
  var evaluated = eval(args[1], env)
  env.set(args[0].symbolVal, evaluated)
  return evaluated

defspecfun "let*", args, env:
  var nEnv = newEnv("let*", env)
  var blist: seq[Node]
  case args[1].kind: # was 0
    of List, Vector:
      blist = args[1].seqVal # was 0
    else:
      error("let*: The first parameter must be a list.")
      return
  if blist.len mod 2 != 0:
    error("let*: The first parameter must be a list of even elemenets")
  var c = 0
  while c<blist.len:
    nEnv.set(blist[c].symbolVal, eval(blist[c+1], nEnv))
    c.inc(2)
  #return eval(args[1], nEnv)

defspecfun "do", args, env:
  #for arg in args:
  var i = 0
  while i < args.len-1: # one less arg
    result = eval(args[i], env)
    i.inc
  result = args[args.len-1]

defspecfun "if", args, env:
  var cond = eval(args[0], env)
  var ifTrue = args[1]
  var ifFalse = newNil()
  if args.len > 2:
    ifFalse = args[2]
  if cond.falsy:
    dbg:
      echo "IF: false"
    #return eval(ifFalse, env)
    return ifFalse
  else:
    dbg:
      echo "IF: true"
    #return eval(ifTrue, env)
    return ifTrue

defspecfun "fn*", args, env:
  var p:Printer
  var binds: seq[Node]
  case args[0].kind:
    of List, Vector:
      binds = args[0].seqVal
    else:
      error("fn*: Function arguments are not in a list.")
      return
  var body = args[1]
  var closure = proc(cArgs: varargs[Node]): Node = 
    var exprs = newSeq[Node]()
    for arg in cArgs:
      exprs.add(arg)
    dbg:
      echo "fn*: Defining closure"
    var closureEnv = newEnv("closure", env, binds, exprs)
    dbg: 
      echo "CLOSURE - arguments: "
      for arg in exprs:
        echo p.prStr(arg)
    let res = eval(body, closureEnv) 
    dbg:
      echo "CLOSURE - result: " & p.prStr(res)
    return res
  return newProc(closure, ast = args[1], params = args[0].seqVal, env = env)
  
defalias "lambda", "fn*"

### Define symbols natively

defnative "(def! not (fn* (a) (if a false true)))"


### Parse Options

for kind, key, val in getopt():
  case kind:
    of cmdLongOption, cmdShortOption:
      case key:
        of "debug", "d":
          DEBUG = true
        else:
          discard
    else:
      discard

### REPL

while true:
  rep(MAINENV)
