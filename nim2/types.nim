import tables, hashes, strutils

type
  Printer* = object
  Reader* = object
    pos*: int
    tokens*: seq[string]
  NodeKind* = enum
    List,
    Atom,
    Symbol,
    String,
    Int,
    Keyword,
    Vector,
    HashMap,
    Proc, 
    SpecProc,
    Bool,
    Nil
  NodeHash* = Table[string, Node]
  Node* = ref NodeObj
  NodeObj* = object
    case kind*: NodeKind
    of Proc:
      procVal*: NodeProc
      ast*: Node
      params*: seq[Node]
      env*: Env
    of SpecProc:
      name*: string
      specProcVal*: NodeSpecProc
    of List, Vector:   
      seqVal*:   seq[Node]
    of Symbol: 
      symbolVal*: string
    of String: 
      stringVal*: string
    of Int:    
      intVal*:    int
    of Atom:   
      atomVal*: string
    of Keyword: 
      keyVal*: string
    of HashMap: 
      hashVal*: NodeHash
    of Bool:
      boolVal*: bool
    of Nil:
      discard
  NodeProc* = proc(args: varargs[Node]): Node
  NodeSpecProc* = proc(args: varargs[Node], env: Env): Node
  Env* = ref EnvObj
  EnvObj* = object
    name*: string
    outer*: Env
    data*: NodeHash
  ParsingError* = object of Exception

var
  DEBUG* = false
  failure* = false

template dbg*(x: stmt) = 
  if DEBUG:
    x

proc error*(str: string) =
  stderr.write "ERROR - "
  stderr.write str
  stderr.write "\n"
  failure = true

proc `position=`*(r: var Reader, value: int) {.inline.} =
  r.pos = value

proc newList*(nseq: seq[Node]): Node =
  new(result)
  result.kind = List
  result.seqVal = nseq

proc newNil*(): Node = 
  new(result)
  result.kind = Nil

proc newVector*(nseq: seq[Node]): Node =
  new(result)
  result.kind = Vector
  result.seqVal = nseq

proc newSymbol*(s: string): Node =
  new(result)
  result.kind = Symbol
  result.symbolVal = s

proc newBool*(s: bool): Node =
  new(result)
  result.kind = Bool
  result.boolVal = s

proc newInt*(i: int): Node =
  new(result)
  result.kind = Int
  result.intVal = i

proc newHashMap*(h: NodeHash): Node =
  new(result)
  result.kind = HashMap
  result.hashVal = h

proc `[]=`*(h: var NodeHash, key: string, value: Node) =
  h.add(key, value)

proc newString*(s: string): Node = 
  new(result)
  result.kind = String
  result.stringVal = s

proc newKeyword*(s: string): Node = 
  new(result)
  result.kind = Keyword
  result.keyVal = s

proc newProc*(f: NodeProc, ast: Node, params: seq[Node], env: Env): Node = 
  new(result)
  result.kind = Proc
  result.ast = ast
  result.params = params
  result.env = env
  result.procVal = f

proc newProc*(f: NodeProc): Node = 
  new(result)
  result.kind = Proc
  result.ast = nil
  result.params = nil
  result.env = nil
  result.procVal = f

proc newSpecProc*(f: NodeSpecProc, s: string): Node = 
  new(result)
  result.kind = SpecProc
  result.name = s
  result.specProcVal = f

### Helper procs

proc kindName*(n: Node): string =
  case n.kind:
    of List:
      return "list"
    of Vector:
      return "vector"
    of Symbol:
      return "symbol"
    of Proc:
      return "function"
    of SpecProc:
      return "special-function"
    of Int:
      return "int"
    of String:
      return "string"
    of Keyword:
      return "keyword"
    of Bool:
      return "boolean"
    of HashMap:
      return "hashmap"
    of Nil:
      return "nil"
    of Atom:
      return "atom"

proc `==`*(a, b: Node): bool =
  if a.kind != b.kind and not (a.kind in {List, Vector}):
    return a.seqVal == b.seqVal
  else:
    return false
  case a.kind:
    of List, Vector:
      return a.seqVal == b.seqVal
    of Symbol:
      return a.symbolVal == b.symbolVal
    of Proc:
      return a.procVal == b.procVal
    of SpecProc:
      return a.specProcVal == b.specProcVal
    of Int:
      return a.intVal == b.intVal
    of String:
      return a.stringVal == b.stringVal
    of Keyword:
      return a.keyVal == b.keyVal
    of Bool:
      return a.boolVal == b.boolVal
    of HashMap:
      return a.hashVal == b.hashVal
    of Nil:
      return true
    of Atom:
      return a.atomVal == b.atomVal


proc falsy*(n: Node): bool =
  var p:Printer
  if n.kind == Nil or n.kind == Bool and n.boolVal == false:
    return true
  else:
    return false

proc code2kind(s: string): string =
  let id = s[0..2]
  case id:
    of "sym":
      return "symbol"
    of "key":
      return "keyword"
    of "str":
      return "string"
    else:
      return "unknown"

