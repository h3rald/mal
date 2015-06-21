type
  Printer* = object
  Reader* = object
    pos*: int
    tokens*: seq[string]
  NodeKind* = enum
    nList,
    nAtom,
    nSymbol,
    nInt
  Node* = object
    case kind*: NodeKind
    of nList:   listVal*:   seq[Node]
    of nSymbol: symbolVal*: string
    of nInt:    intVal*:    int
    of nAtom:   atomVal*: string

proc `position=`*(r: var Reader, value: int) {.inline.} =
  r.pos = value
