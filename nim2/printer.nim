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
        result &= p.prStr(i)
        if count < form.listVal.len:
          result &= " "
      result &= ")"
    of nHashMap:
      result &= "{"
      var count = 0
      for key, value in form.hashVal.pairs:
        var n: Node
        if key.kindName == "string":
          n = newNstring(key.key)
        else:
          n = newNkeyword(key.key)
        count.inc
        result &= p.prStr(n)
        result &= " "
        result &= p.prStr(value)
        if count < form.hashVal.len:
          result &= " "
      result &= "}"
    of nVector:
      result &= "["
      var count = 0
      for i in form.vectorVal:
        count.inc
        result &= p.prStr(i)
        if count < form.vectorVal.len:
          result &= " "
      result &= "]"
    of nInt:
      result = $form.intVal
    of nKeyword:
      result = ":$1" % [form.keyVal]
    of nString:
      if printReadably:
        result = form.stringVal.replace("\n", "\\n").replace("\"", "\\\"")
      else:
        result = form.stringVal
      result = "\"$1\"" % [result]
    of nSymbol:
      result = form.symbolVal
    of nAtom:
      result = form.atomVal
