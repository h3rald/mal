import
  types,
  strutils,
  tables

proc prStr*(p: Printer, form: Node, printReadably = true): string =
  result = ""
  case form.kind:
    of List, Vector:
      let start = if form.kind == List: "(" else: "["
      let finish = if form.kind == List: ")" else: "]"
      result &= start
      var count = 0
      for i in form.seqVal:
        count.inc
        result &= p.prStr(i, printReadably)
        if count < form.seqVal.len:
          result &= " "
      result &= finish
    of HashMap:
      result &= "{"
      var count = 0
      for key, value in form.hashVal.pairs:
        var n: Node
        if key[0..3] == "str:":
          n = newString(key[4..key.len-1])
        else:
          n = newKeyword(key[4..key.len-1])
        count.inc
        result &= p.prStr(n, printReadably)
        result &= " "
        result &= p.prStr(value, printReadably)
        if count < form.hashVal.len:
          result &= " "
      result &= "}"
    of Int:
      result = $form.intVal
    of Bool:
      if form.boolVal: 
        result = "true" 
      else: 
        result = "false"
    of Keyword:
      result = "$1" % form.keyVal
    of Nil:
      result = "nil"
    of String:
      if printReadably:
        result = form.stringVal.replace("\\", "\\\\").replace("\n", "\\n").replace("\"", "\\\"").replace("\r", "\\r")
        result = "\"$1\"" % result
      else:
        result = form.stringVal
    of Symbol:
      result = form.symbolVal
    of Atom:
      result = form.atomVal
    of Proc:
      result = "#<function>"
    of SpecProc:
      result = "#<special-function>"

proc `$`*(n: Node): string =
  var p:Printer
  return p.prStr(n)

proc `$~`*(n: Node): string =
  var p:Printer
  return p.prStr(n, false)
