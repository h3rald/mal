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
    nHashMap
  HashKey* = object
    kindName*: string
    key*: string
  Node* = object
    kindName*: string
    case kind*: NodeKind
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
      hashVal*: Table[HashKey, Node]
  ParsingError* = object of Exception

proc `position=`*(r: var Reader, value: int) {.inline.} =
  r.pos = value

proc hash*(n: HashKey): Hash = 
  return n.key.hash

proc newNlist*(nseq: seq[Node]): Node =
  result.kind = nList
  result.kindName = "list"
  result.listVal = nseq

proc newNvector*(nseq: seq[Node]): Node =
  result.kind = nVector
  result.kindName = "vector"
  result.vectorVal = nseq

proc newNsymbol*(s: string): Node =
  result.kind = nSymbol
  result.kindName = "symbol"
  result.symbolVal = s

proc newNhashMap*(h: Table[HashKey, Node]): Node =
  result.kind = nHashMap
  result.kindName = "hashmap"
  result.hashVal = h

proc newNstring*(s: string): Node = 
  result.kind = nString
  result.kindName = "string"
  result.stringVal = s

proc newNkeyword*(s: string): Node = 
  result.kind = nKeyword
  result.kindName = "keyword"
  result.keyVal = s
