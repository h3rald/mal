import tables, hashes, strutils

type
  Printer* = object
  Reader* = object
    pos*: int
    tokens*: seq[string]
  NodeKind* = enum
    nList,
    nAtom,
    nSymbol,
    nString,
    nInt,
    nKeyword,
    nVector,
    nHashMap,
    nProc, 
    nSpecProc
  NodeHash* = Table[string, Node]
  Node* = object
    kindName*: string
    case kind*: NodeKind
    of nProc:
      procVal*: NodeProc
    of nSpecProc:
      specProcVal*: NodeSpecProc
    of nList:   
      listVal*:   seq[Node]
    of nSymbol: 
      symbolVal*: string
    of nString: 
      stringVal*: string
    of nInt:    
      intVal*:    int
    of nAtom:   
      atomVal*: string
    of nKeyword: 
      keyVal*: string
    of nVector: 
      vectorVal*: seq[Node]
    of nHashMap: 
      hashVal*: NodeHash
  NodeArgs* = varargs[Node]
  NodeProc* = proc(args: NodeArgs): Node
  NodeSpecProc* = proc(args: NodeArgs, env: Env): Node
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
  stderr.write str
  stderr.write "\n"
  failure = true

proc `position=`*(r: var Reader, value: int) {.inline.} =
  r.pos = value

proc newList*(nseq: seq[Node]): Node =
  result.kind = nList
  result.kindName = "list"
  result.listVal = nseq

proc newVector*(nseq: seq[Node]): Node =
  result.kind = nVector
  result.kindName = "vector"
  result.vectorVal = nseq

proc newSymbol*(s: string): Node =
  result.kind = nSymbol
  result.kindName = "symbol"
  result.symbolVal = s

proc newInt*(i: int): Node =
  result.kind = nInt
  result.kindName = "int"
  result.intVal = i

proc newHashMap*(h: NodeHash): Node =
  result.kind = nHashMap
  result.kindName = "hashmap"
  result.hashVal = h

proc `[]=`*(h: var NodeHash, key: string, value: Node) =
  h.add(key, value)

proc newString*(s: string): Node = 
  result.kind = nString
  result.kindName = "string"
  result.stringVal = s

proc newKeyword*(s: string): Node = 
  result.kind = nKeyword
  result.kindName = "keyword"
  result.keyVal = s

proc newProc*(f: NodeProc): Node = 
  result.kind = nProc
  result.kindName = "procedure"
  result.procVal = f

proc newSpecProc*(f: NodeSpecProc): Node = 
  result.kind = nSpecProc
  result.kindName = "special procedure"
  result.specProcVal = f

### Helper procs

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

