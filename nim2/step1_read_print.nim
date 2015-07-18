import 
  readline,
  regex,
  types,
  reader,
  printer

const
  PROMPT = "user> "

var 
  r: Reader
  p: Printer

proc read(prompt = PROMPT): Node =
  var line = readline(prompt)
  historyAdd(line)
  r = line.readStr()
  return r.readForm()

proc print(n: Node) =
  echo p.prStr(n)


proc eval(n: Node): Node = 
  return n

proc rep() = 
  print(eval(read()))

##########

while true:
  rep()


