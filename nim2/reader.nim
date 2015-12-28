import
  regex,
  types,
  strutils,
  printer,
  tables

let
  # Original PCRE:  """[\s,]*(~@|[\[\]{}()'`~^@]|"(?:\\.|[^\\"])*"|;.*|[^\s\[\]{}('"`,;)]*)"""
  REGEX_TOKEN   = re"""[\s,]*{(~@|[\[\]\{\}()'`~^@]|"(\\.|[^\\"])*"|;.*|[^\s\[\]\{\}('"`,;)]*)}"""
  REGEX_INT     = re"""^[\d]+$"""
  REGEX_SYMBOL  = re"""^[\w]+$"""
  REGEX_STRING  = re"""^".*"$"""
  REGEX_KEYWORD  = re"""^:[\w]+$"""


const
  UNMATCHED_PAREN = "expected ')', got EOF"
  UNMATCHED_BRACKET = "expected ']', got EOF"
  UNMATCHED_BRACE = "expected '}', got EOF"
  UNMATCHED_DOUBLE_QUOTE = "expected '\"', got EOF"
  INVALID_HASHMAP_KEY = "invalid hashmap key"

var
  DEBUG = false
  failure = false

template dbg*(x: stmt) = 
  if DEBUG:
    x

proc error*(str: string) =
  stderr.write str
  stderr.write "\n"
  failure = true

proc tokenizer(str: string): seq[string] =
  result = newSeq[string](0)
  var 
    matches: array[0..0, string]
    s = str
    token: string
  while s != "" and s.match(REGEX_TOKEN, matches) and matches[0] != nil and matches[0] != "":
    token = matches[0]
    result.add(token)
    s = s.substr(s.find(token) + token.len, s.len-1)
    matches[0] = nil
  if token.len == 0:
    error UNMATCHED_DOUBLE_QUOTE
    
proc readStr*(str: string): Reader =
  result.tokens = str.tokenizer()
  result.pos = 0

proc peek*(r: Reader): string =
  result = r.tokens[r.pos]

proc next*(r: var Reader): string =
  result = r.tokens[r.pos]
  r.position = r.pos + 1

proc readAtom*(r: var Reader): Node =
  let token = r.peek()
  if token.match(REGEX_KEYWORD):
    result.kind = nKeyword
    result.keyVal = token.substr(1, token.len-1)
    result.kindName = "keyword"
  elif token.match(REGEX_STRING):
    result.kind = nString
    result.stringVal = token.substr(1, token.len-2).replace("\\\"", "\"").replace("\\n", "\n")
    result.kindName = "string"
  elif token.match(REGEX_INT):
    result.kind = nInt
    result.intVal = token.parseInt
    result.kindName = "int"
  #elif token.match(REGEX_SYMBOL):
  else:
    result.kind = nSymbol
    result.symbolVal = token
    result.kindName = "symbol"
  #else:
  #  result.kind = nAtom
  #  result.atomVal = token
  #  result.kindName = "atom"

proc readForm*(r: var Reader): Node

proc readList*(r: var Reader): Node = 
  var list = newSeq[Node](0)
  try:
    discard r.peek()
  except:
    error UNMATCHED_PAREN
    return
  while r.peek() != ")":
    list.add r.readForm()
    discard r.next()
    try:
      discard r.peek()
    except:
      error UNMATCHED_PAREN
      return
  return newNlist(list)

proc readVector*(r: var Reader): Node = 
  var vector = newSeq[Node](0)
  try:
    discard r.peek()
  except:
    error UNMATCHED_BRACKET
    return
  while r.peek() != "]":
    vector.add r.readForm()
    discard r.next()
    try:
      discard r.peek()
    except:
      error UNMATCHED_BRACKET
      return
  return newNvector(vector)

proc readHashMap*(r: var Reader): Node = 
  var p: Printer
  var hash = initTable[HashKey, Node]()
  try:
    discard r.peek()
  except:
    error UNMATCHED_BRACE
    return
  var key: Node
  while r.peek() != "}":
    key = r.readAtom()
    discard r.next()
    var success = false
    if key.kind == nString or key.kind == nKeyword:
      var hashkey: HashKey
      hashkey.kindName = key.kindName
      if key.kind == nString:
        hashkey.key = key.stringVal
      else:
        hashkey.key = key.keyVal
      hash[hashkey] = r.readForm()
      discard r.next()
      try:
        discard r.peek()
      except:
        error UNMATCHED_BRACE
        return
    else:
      error INVALID_HASHMAP_KEY & " (got: $value -- $type)" % ["value", p.prStr(key), "type", key.kindName]
      return
  return newNhashMap(hash)

proc readForm*(r: var Reader): Node =
  var p: Printer
  if failure:
    failure = false
    return
  case r.peek():
    of "{":
      discard r.next() 
      result = r.readHashMap()
    of "[":
      discard r.next() 
      result = r.readVector()
    of "(":
      discard r.next() 
      result = r.readList()
    of "'":
      discard r.next()
      result = newNlist(@[newNsymbol("quote"), r.readForm()])
    of "`":
      discard r.next()
      result = newNlist(@[newNsymbol("quasiquote"), r.readForm()])
    of "~":
      discard r.next()
      result = newNlist(@[newNsymbol("unquote"), r.readForm()])
    of "~@":
      discard r.next()
      result = newNlist(@[newNsymbol("splice-unquote"), r.readForm()])
    of "@":
      discard r.next()
      let sym = r.readForm();
      #if sym.kind != nSymbol:
      #  error "Cannot derefence $1: $2" % [sym.kindName, p.prStr(sym)]
      #  return
      result = newNList(@[newNsymbol("deref"), sym])
    of "^":
      discard r.next()
      if r.peek() == "{":
        discard r.next()
        let h = r.readHashMap()
        discard r.next()
        let v = r.readForm()
        result = newNList(@[newNsymbol("with-meta"), v, h])
      else:
        error "A HashMap is required by the with-meta macro"
    else:
      result = r.readAtom()
