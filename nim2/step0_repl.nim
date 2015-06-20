import 
  strutils,
  vendor/linenoise

const
  PROMPT = "user> "

proc completionCallback*(str: cstring, completions: ptr LinenoiseCompletions) = 
  let symbols = newSeq[string](0) # TODO populate with completion targets
  var words = ($str).split(" ")
  var w = if words.len > 0: words.pop else: ""
  var sep = ""
  if words.len > 0:
    sep = " "
  for s in symbols:
    if startsWith(s, w):
      linenoiseAddCompletion completions, words.join(" ") & sep & s

proc exit() {.noconv.} =
  echo "Exiting..."
  quit()

proc read(prompt = PROMPT): string =
  let res = linenoise(prompt)
  if res != nil:
    discard linenoiseHistoryAdd(res)
    return $res
  else:
    exit()

proc print(s: string) =
  echo s

proc eval(s: string): string = 
  return s

proc rep() = 
  print(eval(read()))

##########

setControlCHook(exit)

while true:
  rep()


