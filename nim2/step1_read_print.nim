import 
  readline,
  regex

const
  PROMPT = "user> "

proc read(prompt = PROMPT): string =
  result = readline(prompt)
  historyAdd(result)

proc print(s: string) =
  echo s

proc eval(s: string): string = 
  return s

proc rep() = 
  print(eval(read()))

##########

while true:
  rep()


