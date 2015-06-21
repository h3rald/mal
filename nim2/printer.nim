import
  types

proc printStr*(p: Printer, form: Node) =
  case form.kind:
    of nList:
      stdout.write "("
      var count = 0
      for i in form.listVal:
        count.inc
        p.printStr(i)
        if count < form.listVal.len:
          stdout.write " "
      stdout.write ")"
    of nInt:
      stdout.write form.intVal
    of nSymbol:
      stdout.write form.symbolVal
    of nAtom:
      stdout.write form.atomVal
