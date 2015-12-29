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
    nProc
  Proc = proc(ns: varargs[Node]):Node
  NodeHash* = Table[string, Node]
  #Env* = object
  #  outer*: Env
  #  data*: NodeHash
  Node* = object
    kindName*: string
    case kind*: NodeKind
    of nProc:
      procVal*: Proc
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
  ParsingError* = object of Exception

proc `position=`*(r: var Reader, value: int) {.inline.} =
  r.pos = value

#proc newEnv*(outer: Env): Env =
#  result.outer = outer
#  result.data = initTable[HashKey, Node]()

#proc newEnv*(): Env =
#  result.data = initTable[HashKey, Node]()

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

proc newProc*(f: Proc): Node = 
  result.kind = nProc
  result.kindName = "procedure"
  result.procVal = f


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
