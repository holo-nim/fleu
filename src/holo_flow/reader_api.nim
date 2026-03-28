## include file to ensure reader implementation is complete
## not actually used since forward declarations don't support {.inline.} after the fact

import std/unicode # just to expose API otherwise not used

when not declared(ReaderType):
  {.fatal: "need to include with `ReaderType` defined".}

proc startRead*(reader: ReaderType, str: sink string)

when false:
  import std/streams

  proc startRead*(reader: ReaderType, loader: BufferLoader, bufferCapacity = 32)

  proc startRead*(reader: ReaderType, stream: Stream, loadAmount = 16, bufferCapacity = 32)

  when declared(File):
    proc startRead*(reader: ReaderType, file: File, loadAmount = 16, bufferCapacity = 32)

# these are exposed but the type does not have to be `string`, at most `openArray[char]`:
proc currentBuffer*(reader: ReaderType): string
proc bufferPos*(reader: ReaderType): int
# this is also a standin for any type:
proc state*(reader: ReaderType): ReadState
proc `state=`*(reader: ReaderType, state: ReadState)

proc lockBuffer*(reader: ReaderType)
proc unlockBuffer*(reader: ReaderType)

proc peek*(reader: ReaderType, c: var char): bool

proc unsafePeek*(reader: ReaderType): char

proc peek*(reader: ReaderType, c: var char, offset: int): bool

proc unsafePeek*(reader: ReaderType, offset: int): char

proc peekCount*(reader: ReaderType, rune: var Rune): int

proc peek*(reader: ReaderType, rune: var Rune): bool {.inline.} =
  peekCount(reader, rune) != 0

proc peek*(reader: ReaderType, cs: var openArray[char]): bool

proc peek*[I](reader: ReaderType, cs: var array[I, char]): bool

proc peekOrZero*(reader: ReaderType): char

proc hasNext*(reader: ReaderType): bool

proc hasNext*(reader: ReaderType, offset: int): bool

proc unsafeNext*(reader: ReaderType)

proc unsafeNextBy*(reader: ReaderType, n: int)

proc next*(reader: ReaderType, c: var char): bool

proc next*(reader: ReaderType, rune: var Rune): bool

proc next*(reader: ReaderType): bool {.inline.} =
  var dummy: char
  result = next(reader, dummy)

iterator peekNext*(reader: ReaderType): char =
  var c: char
  while peek(reader, c):
    yield c
    unsafeNext(reader)

proc peekMatch*(reader: ReaderType, c: char): bool

proc nextMatch*(reader: ReaderType, c: char): bool {.inline.} =
  result = peekMatch(reader, c)
  if result:
    unsafeNext(reader)

proc peekMatch*(reader: ReaderType, c: char, offset: int): bool

proc peekMatch*(reader: ReaderType, rune: Rune): bool

proc nextMatch*(reader: ReaderType, rune: Rune): bool {.inline.} =
  result = peekMatch(reader, rune)
  if result:
    unsafeNextBy(reader, size(rune))

proc peekMatch*(reader: ReaderType, cs: set[char], c: var char): bool

proc nextMatch*(reader: ReaderType, cs: set[char], c: var char): bool {.inline.} =
  result = peekMatch(reader, cs, c)
  if result:
    unsafeNext(reader)

proc peekMatch*(reader: ReaderType, cs: set[char]): bool {.inline.} =
  var dummy: char
  result = peekMatch(reader, cs, dummy)

proc nextMatch*(reader: ReaderType, cs: set[char]): bool {.inline.} =
  var dummy: char
  result = nextMatch(reader, cs, dummy)

proc peekMatch*(reader: ReaderType, cs: set[char], offset: int, c: var char): bool

proc peekMatch*(reader: ReaderType, cs: set[char], offset: int): bool {.inline.} =
  var dummy: char
  result = peekMatch(reader, cs, offset, dummy)

proc peekMatch*(reader: ReaderType, str: openArray[char]): bool

proc peekMatch*[I](reader: ReaderType, str: array[I, char]): bool

proc peekMatch*(reader: ReaderType, str: static string): bool

proc nextMatch*(reader: ReaderType, str: openArray[char]): bool {.inline.} =
  result = peekMatch(reader, str)
  if result:
    unsafeNextBy(reader, str.len)

proc nextMatch*[I](reader: ReaderType, str: array[I, char]): bool {.inline.} =
  result = peekMatch(reader, str)
  if result:
    unsafeNextBy(reader, str.len)

proc nextMatch*(reader: ReaderType, str: static string): bool {.inline.} =
  result = peekMatch(reader, str)
  if result:
    unsafeNextBy(reader, str.len)
