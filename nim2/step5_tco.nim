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

proc eval(ast: Node, env: var Env): Node

proc eval_ast(ast: Node, env: var Env): Node = 
  var p:Printer
  case ast.kind:
    of Symbol:
      dbg:
        echo "EVAL_AST: symbol: " & ast.stringVal
      return env.get(ast.stringVal)
    of List:
      dbg:
        echo "EVAL_AST: list"
      var list = newSeq[Node]()
      for i in ast.seqVal:
        list.add eval(i, env)
      return newList(list)
    of Vector:
      dbg:
        echo "EVAL_AST: vector"
      var list = newSeq[Node]()
      for i in ast.seqVal:
        list.add eval(i, env)
      return newVector(list)
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

proc eval(ast: Node, env: var Env): Node =
  var p:Printer
  var ast = ast
  dbg:
    echo "EVAL: " & $ast
  template apply = 
    let el = eval_ast(ast, env)
    let f = el.seqVal[0]
    case f.kind
    of Proc:
      ast = f.procVal.ast
      env = newEnv("closure", f.procVal.env, f.procVal.params, newList(el.seqVal[1 .. ^1]))
    else:
      # Assuming NativeProc
      return f.nativeProcVal(el.seqVal[1 .. ^1])
  while true:
    if ast.kind != List: 
      return ast.eval_ast(env)
    let 
      first = ast.seqVal[0]
      second = ast.seqVal[1]
      last = ast.seqVal.high
    case first.kind
    of Symbol:
      case first.stringVal
      of "print-env":
        var p:Printer
        echo "Printing environment: $1" % env.name
        for k, v in env.data.pairs:
           echo "'$1'\t\t= $2" % [k, p.prStr(v)]
      of "def!":
        let third = ast.seqVal[2]
        return env.set(second.stringVal, eval(third, env))
      of "let*":
        let third = ast.seqVal[2]
        var nEnv = newEnv("let*", env)
        case second.kind
        of List, Vector:
          for i in countup(0, second.seqVal.high, 2):
            discard nEnv.set(second.seqVal[i].stringVal, eval(second.seqVal[i+1], nEnv))
        else: 
          error("let*: First argument is not a list or vector")
        ast = third
        env = nEnv
        # Continue loop (TCO)
      of "do":
        let el = eval_ast(newList(ast.seqVal[1 .. <last]), env)
        ast = ast.seqVal[last]
        # Continue loop (TCO)
      of "if":
        let
          third = ast.seqVal[2]
          cond = eval(second, env)
        if cond.falsy:
          if ast.seqVal.len > 3: 
            ast = ast.seqVal[3]
          else: ast = newNil()
        else: ast = third
      of "fn*":
        let third = ast.seqVal[2]
        var nEnv = env
        let fn = proc(args: varargs[Node]): Node =
          var list = newSeq[Node]()
          for arg in args:
            list.add(arg)
          var newEnv = newEnv("fn*", nEnv, second, newList(list))
          return eval(third, newEnv)
        return newProc(fn, ast = third, params = second, env = env)
      else:
        apply()
    else:
      apply()

proc rep(env: var Env) = 
  print(eval(read(), env))


proc defnative*(s: string) =
  var r: Reader = readStr(s)
  discard eval(r.readForm(), MAINENV)

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
