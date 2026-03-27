const holoReaderLineColumn* {.booldefine.} = true
  ## enables/disables line column tracking by default, has very little impact on performance

const holoReaderDisableLineColumn* {.booldefine.} = false
  ## completely disables line column tracking at compile time, overriding runtime option

const holoReaderPeekStrCopyMem* {.booldefine.} = false
  ## possible minor optimization, seems slightly slower in practice 

type
  ReadState* = object
    pos*: int
    # XXX also total byte count #4
    when not holoReaderDisableLineColumn:
      doLineColumn*: bool = holoReaderLineColumn
      line*, column*: int

  SomeBuffer* = typed

{.push checks: off, stacktrace: off.}

when holoReaderDisableLineColumn:
  template doLineColumn*(state: ReadState): bool = false
  template line*(state: ReadState): int = -1
  template column*(state: ReadState): int = -1

proc initReadState*(doLineColumn = holoReaderLineColumn): ReadState {.inline.} =
  result = ReadState()
  when not holoReaderDisableLineColumn:
    result.doLineColumn = doLineColumn

proc startRead*(state: var ReadState) {.inline.} =
  state.pos = -1
  when not holoReaderDisableLineColumn:
    state.line = 1
    state.column = 1

template doPeek*(data: SomeBuffer, dataLen: int, nextPos: int, c: var char, result: var bool) =
  if nextPos < dataLen:
    c = data[nextPos]
    result = true
  else:
    result = false

{.pop.}
