import
  regex,
  types,
  strutils,
  printer,
  tables

let
  # Original PCRE:  """[\s,]*(~@|[\[\]{}()'`~^@]|"(?:\\.|[^\\"])*"|;.*|[^\s\[\]{}('"`,;)]*)"""
  REGEX_TOKEN   = re"""[\s,]*{(~@|[\[\]\{\}()'`~^@]|"(\\.|[^\\"])*"|;[^\\n]*|[^\s\[\]\{\}('"`,;)]*)}"""
  REGEX_INT     = re"""^[\d]+$"""
  REGEX_SYMBOL  = re"""^[\w]+$"""
  REGEX_STRING  = re"""^".*"$"""
  REGEX_KEYWORD  = re"""^:[\w]+$"""
  REGEX_COMMENT = re"""^;"""


const
  UNMATCHED_PAREN = "expected ')', got EOF"
  UNMATCHED_BRACKET = "expected ']', got EOF"
  UNMATCHED_BRACE = "expected '}', got EOF"
  UNMATCHED_DOUBLE_QUOTE = "expected '\"', got EOF"
  INVALID_HASHMAP_KEY = "invalid hashmap key"

proc tokenizer(str: string): seq[string] =
  result = newSeq[string](0)
  var 
    matches: array[0..0, string]
    s = str
    token: string
  while s != "" and s.match(REGEX_TOKEN, matches) and matches[0] != nil and matches[0] != "":
    token = matches[0]
    if not token.match(REGEX_COMMENT):
      result.add(token)
    s = s.substr(s.find(token) + token.len, s.len-1)
    matches[0] = nil
  if token.len == 0:
    parsingError UNMATCHED_DOUBLE_QUOTE
    
proc readForm*(r: var Reader): Node

proc readStr*(str: string): Node =
  var r:Reader
  r.tokens = str.tokenizer()
  r.pos = 0
  if r.tokens.len == 0:
    noTokensError()
  return r.readForm()

proc peek*(r: Reader): string =
  result = r.tokens[r.pos]

proc next*(r: var Reader): string =
  result = r.tokens[r.pos]
  r.pos = r.pos + 1

proc readAtom*(r: var Reader): Node =
  let token = r.peek()
  if token.match(REGEX_KEYWORD):
    return newKeyword(token.substr(1, token.len-1))
  elif token.match(REGEX_STRING):
    return newString(token.substr(1, token.len-2).replace("\\\\", "\\").replace("\\\"", "\"").replace("\\n", "\n"))
  elif token.match(REGEX_INT):
    return newInt(token.parseInt)
  elif token == "nil":
    return newNil()
  elif token == "false":
    return newBool(false)
  elif token == "true":
    return newBool(true)
  else:
    return newSymbol(token)

proc readList*(r: var Reader): Node = 
  var list = newSeq[Node]()
  try:
    discard r.peek()
  except:
    parsingError UNMATCHED_PAREN
  while r.peek() != ")":
    list.add r.readForm()
    discard r.next()
    if r.tokens.len == r.pos:
      parsingError UNMATCHED_PAREN
    try:
      discard r.peek()
    except:
      parsingError UNMATCHED_PAREN
  return newList(list)

proc readVector*(r: var Reader): Node = 
  var vector = newSeq[Node]()
  try:
    discard r.peek()
  except:
    parsingError UNMATCHED_BRACKET
    return
  while r.peek() != "]":
    vector.add r.readForm()
    discard r.next()
    if r.tokens.len == r.pos:
      parsingError UNMATCHED_PAREN
    try:
      discard r.peek()
    except:
      parsingError UNMATCHED_BRACKET
  return newvector(vector)

proc readHashMap*(r: var Reader): Node = 
  var p: Printer
  var hash = initTable[string, Node]()
  try:
    discard r.peek()
  except:
    parsingError UNMATCHED_BRACE
  var key: Node
  while r.peek() != "}":
    key = r.readAtom()
    discard r.next()
    var success = false
    if key.kind in {String, Keyword}:
      hash.add(key.keyval, r.readForm())
      discard r.next()
      if r.tokens.len == r.pos:
        parsingError UNMATCHED_PAREN
      try:
        discard r.peek()
      except:
        parsingError UNMATCHED_BRACE
    else:
      parsingError INVALID_HASHMAP_KEY & " - got: '$value' ($type)" % ["value", p.prStr(key), "type", key.kindName]
  return newhashMap(hash)

proc readForm*(r: var Reader): Node =
  var p: Printer
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
      result = newList(@[newSymbol("quote"), r.readForm()])
    of "`":
      discard r.next()
      result = newList(@[newSymbol("quasiquote"), r.readForm()])
    of "~":
      discard r.next()
      result = newList(@[newSymbol("unquote"), r.readForm()])
    of "~@":
      discard r.next()
      result = newList(@[newSymbol("splice-unquote"), r.readForm()])
    of "@":
      discard r.next()
      let sym = r.readForm()
      result = newList(@[newSymbol("deref"), sym])
    of "^":
      discard r.next()
      if r.peek() == "{":
        discard r.next()
        let h = r.readHashMap()
        discard r.next()
        let v = r.readForm()
        result = newList(@[newSymbol("with-meta"), v, h])
      else:
        incorrectValueError "A HashMap is required by the with-meta macro"
    else:
      result = r.readAtom()
