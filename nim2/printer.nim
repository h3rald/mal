import
  types,
  strutils,
  tables

proc prStr*(p: Printer, form: Node, printReadably = true): string =
  result = ""
  case form.kind:
    of nList:
      result &= "("
      var count = 0
      for i in form.listVal:
        count.inc
        result &= p.prStr(i, printReadably)
        if count < form.listVal.len:
          result &= " "
      result &= ")"
    of nHashMap:
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
    of nVector:
      result &= "["
      var count = 0
      for i in form.vectorVal:
        count.inc
        result &= p.prStr(i, printReadably)
        if count < form.vectorVal.len:
          result &= " "
      result &= "]"
    of nInt:
      result = $form.intVal
    of nBool:
      if form.boolVal: 
        result = "true" 
      else: 
        result = "false"
    of nKeyword:
      result = "$1" % form.keyVal
    of nNil:
      result = "nil"
    of nString:
      if printReadably:
        result = form.stringVal.replace("\\", "\\\\").replace("\n", "\\n").replace("\"", "\\\"").replace("\r", "\\r")
        result = "\"$1\"" % result
      else:
        result = form.stringVal
    of nSymbol:
      result = form.symbolVal
    of nAtom:
      result = form.atomVal
    of nProc:
      result = "#<function>"
    of nSpecProc:
      result = "#<special-function>"

proc `$`*(n: Node): string =
  var p:Printer
  return p.prStr(n)

proc `$~`*(n: Node): string =
  var p:Printer
  return p.prStr(n, false)
