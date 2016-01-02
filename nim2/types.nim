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
    nSpecProc,
    nBool,
    nNil
  NodeHash* = Table[string, Node]
  Node* = object
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
    of nBool:
      boolVal*: bool
    of nNil:
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
  result.kind = nList
  result.listVal = nseq

proc newNil*(): Node = 
  result.kind = nNil

proc newVector*(nseq: seq[Node]): Node =
  result.kind = nVector
  result.vectorVal = nseq

proc newSymbol*(s: string): Node =
  result.kind = nSymbol
  result.symbolVal = s

proc newBool*(s: bool): Node =
  result.kind = nBool
  result.boolVal = s

proc newInt*(i: int): Node =
  result.kind = nInt
  result.intVal = i

proc newHashMap*(h: NodeHash): Node =
  result.kind = nHashMap
  result.hashVal = h

proc `[]=`*(h: var NodeHash, key: string, value: Node) =
  h.add(key, value)

proc newString*(s: string): Node = 
  result.kind = nString
  result.stringVal = s

proc newKeyword*(s: string): Node = 
  result.kind = nKeyword
  result.keyVal = s

proc newProc*(f: NodeProc): Node = 
  result.kind = nProc
  result.procVal = f

proc newSpecProc*(f: NodeSpecProc): Node = 
  result.kind = nSpecProc
  result.specProcVal = f

### Helper procs

proc kindName*(n: Node): string =
  case n.kind:
    of nList:
      return "list"
    of nVector:
      return "vector"
    of nSymbol:
      return "symbol"
    of nProc:
      return "function"
    of nSpecProc:
      return "special-function"
    of nInt:
      return "int"
    of nString:
      return "string"
    of nKeyword:
      return "keyword"
    of nBool:
      return "boolean"
    of nHashMap:
      return "hashmap"
    of nNil:
      return "nil"
    of nAtom:
      return "atom"

proc `==`*(a, b: Node): bool =
  if a.kind != b.kind:
    if a.kind == nList and b.kind == nVector:
      return a.listVal == b.vectorVal
    if b.kind == nList and a.kind == nVector:
      return b.listVal == a.vectorVal
    return false
  case a.kind:
    of nList:
      return a.listVal == b.listVal
    of nVector:
      return a.vectorVal == b.vectorVal
    of nSymbol:
      return a.symbolVal == b.symbolVal
    of nProc:
      return a.procVal == b.procVal
    of nSpecProc:
      return a.specProcVal == b.specProcVal
    of nInt:
      return a.intVal == b.intVal
    of nString:
      return a.stringVal == b.stringVal
    of nKeyword:
      return a.keyVal == b.keyVal
    of nBool:
      return a.boolVal == b.boolVal
    of nHashMap:
      return a.hashVal == b.hashVal
    of nNil:
      return true
    of nAtom:
      return a.atomVal == b.atomVal


proc falsy*(n: Node): bool =
  var p:Printer
  if n.kind == nNil or n.kind == nBool and n.boolVal == false:
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

