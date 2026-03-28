## include file to ensure writer implementation is complete
## not actually used since forward declarations don't support {.inline.} after the fact

import std/unicode # just to expose API otherwise not used

when not declared(WriterType):
  {.fatal: "need to include with `WriterType` defined".}

when false:
  import std/streams

  proc startWrite*(writer: WriterType, bufferCapacity = 16)

  proc startWrite*(writer: WriterType, consumer: BufferConsumer, bufferCapacity = 16)

  proc startWrite*(writer: WriterType, stream: Stream, bufferCapacity = 16)

  when declared(File):
    proc startWrite*(writer: WriterType, file: File, bufferCapacity = 16)

# these are exposed but the type does not have to be `string`, at most `openArray[char]`:
template currentBuffer*(writer: WriterType): string
template bufferStart*(writer: WriterType): int

proc lockFlush*(writer: WriterType)
proc unlockFlush*(writer: WriterType)

proc addToBuffer*(writer: WriterType, c: char)
proc addToBuffer*(writer: WriterType, c: Rune)
proc addToBuffer*(writer: WriterType, s: string)
proc addToBuffer*(writer: WriterType, s: openArray[char])

proc write*(writer: WriterType, c: char)
proc write*(writer: WriterType, c: Rune)
proc write*(writer: WriterType, s: string)
proc write*(writer: WriterType, s: openArray[char])

proc finishWrite*(writer: WriterType): string
