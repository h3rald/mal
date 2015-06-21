import
  regex,
  types,
  strutils

let
  REGEX_TOKEN   = re"""(\s|[,])*({~@|[\[\]\{\}()'`~^@]|"(\\.|[^\\"])*"|;.*|[^\s\[\]\{\}('"`,;)]*})"""
  #REGEX_TOKEN   = re"""({[^\s\[\]\{\}('"`,;)]*})"""
  REGEX_INT     = re"""\d+"""
  REGEX_SYMBOL  = re"""\w+"""

proc tokenize(str: string): seq[string] =
  result = newSeq[string](0)
  var 
    matches: array[0..0, string]
    s = str
    token: string
  while s != "" and s.match(REGEX_TOKEN, matches) and matches[0] != nil:
    token = matches[0]
    echo s
    echo token
    result.add(token)
    echo s.find(token)
    s = s.substr(s.find(token) + token.len, s.len-1)
    echo "->", s, "<-"
    matches[0] = nil
    #break
    
proc readStr*(str: string): Reader =
  result.tokens = str.tokenize()
  result.pos = 0

proc peek*(r: Reader): string =
  result = r.tokens[r.pos]

proc next*(r: var Reader): string =
  result = r.tokens[r.pos]
  r.position = r.pos + 1

proc readAtom*(r: var Reader): Node =
  let token = r.peek()
  if token.match(REGEX_INT):
    result.kind = nInt
    result.intVal = token.parseInt
  elif token.match(REGEX_SYMBOL):
    result.kind = nSymbol
    result.symbolVal = token
  else:
    result.kind = nAtom
    result.atomVal = token

proc readForm*(r: var Reader): Node

proc readList*(r: var Reader): Node = 
  var list = newSeq[Node](0)
  while r.next()[0] != ')':
    list.add r.readForm()
  result.kind = nList
  result.listVal = list

proc readForm*(r: var Reader): Node =
  case r.peek()[0]:
    of '(':
      result = r.readList()
    else:
      result = r.readAtom()

