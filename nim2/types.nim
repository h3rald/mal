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
    NativeProc, 
    Bool,
    Nil
  NodeHash* = Table[string, Node]
  Node* = ref NodeObj
  NodeProc* = proc(args: varargs[Node]): Node
  ProcType* = ref object
    fun*: NodeProc
    ast*: Node
    params*: Node
    env*: Env
    isMacro*: bool
  NodeObj* = object
    meta*: Node
    case kind*: NodeKind
    of Proc:
      procVal*: ProcType
    of NativeProc:
      nativeProcVal*: NodeProc
    of List, Vector:   
      seqVal*:   seq[Node]
    of String, Symbol, Keyword: 
      stringVal*: string
    of Int:    
      intVal*:    int
    of Atom:   
      atomVal*: Node
    of HashMap: 
      hashVal*: NodeHash
    of Bool:
      boolVal*: bool
    of Nil:
      discard
  Env* = ref EnvObj
  EnvObj* = object
    name*: string
    outer*: Env
    data*: NodeHash
  NoTokensError* = object of Exception
  UnknownSymbolError* = object of Exception
  ParsingError* = object of Exception
  UnhandledExceptionError* = object of Exception
  LangException* = object of Exception
    value*: Node

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

proc newAtom*(n: Node): Node =
  new(result)
  result.kind = Atom
  result.atomVal = n

proc newList*(nseq: seq[Node]): Node =
  new(result)
  result.kind = List
  result.seqVal = nseq

proc newList*(args: varargs[Node]): Node =
  new(result)
  result.kind = List
  result.seqVal = newSeq[Node]()
  for arg in args:
    result.seqVal.add arg

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
  result.stringVal = s

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
  result.stringVal = '\xff' & s

proc newNativeProc*(f: NodeProc): Node = 
  new(result)
  result.kind = NativeProc
  result.nativeProcVal = f

proc newProc*(f: NodeProc, ast: Node, params: Node, env: Env, isMacro = false): Node = 
  new(result)
  result.kind = Proc
  result.procVal = new ProcType
  result.procVal.ast = ast
  result.procVal.params = params
  result.procVal.env = env
  result.procVal.fun = f
  result.procVal.isMacro = isMacro

proc newProc*(f: NodeProc, isMacro = false): Node = 
  new(result)
  result.kind = Proc
  result.procVal = new ProcType
  result.procVal.ast = nil
  result.procVal.params = nil
  result.procVal.env = nil
  result.procVal.fun = f
  result.procVal.isMacro = isMacro

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
    of NativeProc:
      return "native-function"
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
  if a.kind != b.kind:
    if (a.kind in {List, Vector}) and (b.kind in {List, Vector}):
      return a.seqVal == b.seqVal
    else:
      return false
  case a.kind:
    of List, Vector:
      return a.seqVal == b.seqVal
    of Proc:
      return a.procVal == b.procVal
    of NativeProc:
      return a.nativeProcVal == b.nativeProcVal
    of Int:
      return a.intVal == b.intVal
    of String, Symbol, Keyword:
      return a.stringVal == b.stringVal
    of Bool:
      return a.boolVal == b.boolVal
    of HashMap:
      return a.hashVal == b.hashVal
    of Nil:
      return true
    of Atom:
      return a.atomVal == b.atomVal


proc falsy*(n: Node): bool =
  if n.kind == Nil or n.kind == Bool and n.boolVal == false:
    return true
  else:
    return false

proc isPair*(n: Node): bool =
  return n.kind in {List, Vector} and n.seqVal.len > 0

proc getFun*(x: Node): NodeProc =
  if x.kind == NativeProc: result = x.nativeProcVal
  elif x.kind == Proc: result = x.procVal.fun
  else: raise newException(ValueError, "no function")

proc keyval*(s: Node): string =
  if s.kind == Keyword:
    return '\xff' & s.stringVal[1 .. s.stringVal.high]
  else:
    return s.stringVal

proc keyrep*(s: Node): string =
  if s.stringVal[0] == '\xff':
    return ':' & s.stringVal[1 .. s.stringVal.high]
  else:
    return s.stringVal

