import
  regex,
  types,
  strutils

let
  # Original PCRE:  """[\s,]*(~@|[\[\]{}()'`~^@]|"(?:\\.|[^\\"])*"|;.*|[^\s\[\]{}('"`,;)]*)"""
  REGEX_TOKEN   = re"""[\s,]*{(~@|[\[\]\{\}()'`~^@]|"(\\.|[^\\"])*"|;.*|[^\s\[\]\{\}('"`,;)]*)}"""
  REGEX_INT     = re"""^[\d]+$"""
  REGEX_SYMBOL  = re"""^[\w]+$"""
  REGEX_STRING  = re"""^".*"$"""


const
  UNMATCHED_PAREN = "expected ')', got EOF"
  UNMATCHED_DOUBLE_QUOTE = "expected '\"', got EOF"

proc error(str: string) =
  stderr.write str
  stderr.write "\n"

proc tokenizer(str: string): seq[string] =
  result = newSeq[string](0)
  var 
    matches: array[0..0, string]
    s = str
    token: string
  while s != "" and s.match(REGEX_TOKEN, matches) and matches[0] != nil and matches[0] != "":
    #echo "--- matches ---"
    #for m in matches:
    #  echo "->", m, "<-"
    #echo "---------------"
    token = matches[0]
    #echo "Token: ->", token, "<-"
    result.add(token)
    #echo s.find(token)
    #echo token.len
    s = s.substr(s.find(token) + token.len, s.len-1)
    #echo "->", s, "<-"
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
  if token.match(REGEX_STRING):
    result.kind = nString
    result.stringVal = token.substr(1, token.len-2).replace("\\\"", "\"").replace("\\n", "\n")
  elif token.match(REGEX_INT):
    result.kind = nInt
    result.intVal = token.parseInt
  elif token.match(REGEX_SYMBOL):
    result.kind = nSymbol
    result.symbolVal = token
  else:
    result.kind = nAtom
    result.atomVal = token

proc readForm*(r: var Reader): Node

proc readString*(r: var Reader): Node =
  let atom = r.readAtom().atomVal


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
  result.kind = nList
  result.listVal = list

proc readForm*(r: var Reader): Node =
  case r.peek():
    of "(":
      discard r.next() 
      result = r.readList()
    #of "\"":
    #  echo "test"
    #  discard r.next() 
    #  result = r.readString()
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
    else:
      result = r.readAtom()

