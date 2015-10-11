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
    nKeyword
  Node* = object
    case kind*: NodeKind
    of nList:   listVal*:   seq[Node]
    of nSymbol: symbolVal*: string
    of nString: stringVal*: string
    of nInt:    intVal*:    int
    of nAtom:   atomVal*: string
    of nKeyword: keyVal*: string
  ParsingError* = object of Exception

proc `position=`*(r: var Reader, value: int) {.inline.} =
  r.pos = value

proc newNlist*(nseq: seq[Node]): Node =
  result.kind = nList
  result.listVal = nseq

proc newNsymbol*(s: string): Node =
  result.kind = nSymbol
  result.symbolVal = s
