import ./flush_buffer
import std/[streams, unicode, strutils] # just to expose API otherwise not used

type
  FlushState* = object
    buffer*: FlushBuffer
    bufferLocks*: int
  FlushWriter* = object
    flush*: FlushState
  IndentState* = object
    level*: int
    # could add space vs tab
    atLineStart*: bool
  IndentFlushWriter* = object
    state*: IndentState
    flush*: FlushState

{.push checks: off, stacktrace: off.}

proc initFlushWriter*(): FlushWriter {.inline.} =
  result = FlushWriter()

proc initIndentFlushWriter*(): IndentFlushWriter {.inline.} =
  result = IndentFlushWriter()

proc startFlush*(flush: var FlushState, bufferCapacity = 16) {.inline.} =
  flush.buffer = initFlushBuffer(bufferCapacity)

proc startFlush*(flush: var FlushState, consumer: BufferConsumer, bufferCapacity = 16) {.inline.} =
  flush.buffer = initFlushBuffer(consumer, bufferCapacity)

proc startFlush*(flush: var FlushState, stream: Stream, bufferCapacity = 16) {.inline.} =
  flush.buffer = initFlushBuffer(stream, bufferCapacity)

when declared(File):
  proc startFlush*(flush: var FlushState, file: File, bufferCapacity = 16) {.inline.} =
    ## `file` has to last as long as the writer
    flush.buffer = initFlushBuffer(file, bufferCapacity)

when false:
  type WriterType = var FlushWriter
  include writer_api

proc startWrite*(writer: var FlushWriter, bufferCapacity = 16) {.inline.} =
  writer.flush.startFlush(bufferCapacity)

proc startWrite*(writer: var IndentFlushWriter, bufferCapacity = 16) {.inline.} =
  writer.flush.startFlush(bufferCapacity)

proc startWrite*(writer: var FlushWriter, consumer: BufferConsumer, bufferCapacity = 16) {.inline.} =
  writer.flush.startFlush(consumer, bufferCapacity)

proc startWrite*(writer: var IndentFlushWriter, consumer: BufferConsumer, bufferCapacity = 16) {.inline.} =
  writer.flush.startFlush(consumer, bufferCapacity)

proc startWrite*(writer: var FlushWriter, stream: Stream, bufferCapacity = 16) {.inline.} =
  writer.flush.startFlush(stream, bufferCapacity)

proc startWrite*(writer: var IndentFlushWriter, stream: Stream, bufferCapacity = 16) {.inline.} =
  writer.flush.startFlush(stream, bufferCapacity)

when declared(File):
  proc startWrite*(writer: var FlushWriter, file: File, bufferCapacity = 16) {.inline.} =
    ## `file` has to last as long as the writer
    writer.flush.startFlush(file, bufferCapacity)

  proc startWrite*(writer: var IndentFlushWriter, file: File, bufferCapacity = 16) {.inline.} =
    ## `file` has to last as long as the writer
    writer.flush.startFlush(file, bufferCapacity)

template currentBuffer*(writer: FlushWriter | IndentFlushWriter): string =
  writer.flush.buffer.data

template bufferStart*(writer: FlushWriter | IndentFlushWriter): int =
  writer.flush.buffer.flushPos

proc addToBuffer*(writer: var FlushWriter, c: char) {.inline.} =
  writer.flush.buffer.add(c)

proc addToBuffer*(writer: var FlushWriter, s: string) {.inline.} =
  writer.flush.buffer.add(s)

proc addToBuffer*(writer: var FlushWriter, s: openArray[char]) {.inline.} =
  writer.flush.buffer.add(s)

proc addToBuffer*(writer: var FlushWriter, rune: Rune) {.inline.} =
  writer.flush.buffer.add(rune)

proc addIndent*(writer: var IndentFlushWriter, level: int = 2) {.inline.} =
  writer.state.level += level

proc removeIndent*(writer: var IndentFlushWriter, level: int = 2) {.inline.} =
  writer.state.level -= level

proc setIndent*(writer: var IndentFlushWriter, level: int) {.inline.} =
  writer.state.level = level

proc hasIndent*(writer: var IndentFlushWriter): bool {.inline.} =
  writer.state.level > 0

proc checkIndent(writer: var IndentFlushWriter, c: char) =
  if c in Newlines:
    writer.state.atLineStart = true
  else:
    if writer.state.atLineStart:
      for i in 0 ..< writer.state.level:
        writer.flush.buffer.add ' '
    writer.state.atLineStart = false

proc addToBuffer*(writer: var IndentFlushWriter, c: char) {.inline.} =
  if writer.hasIndent:
    checkIndent(writer, c)
  writer.flush.buffer.add(c)

proc addToBuffer*(writer: var IndentFlushWriter, s: string) {.inline.} =
  if writer.hasIndent:
    for c in s:
      checkIndent(writer, c)
      writer.flush.buffer.add(c)
  else:
    writer.flush.buffer.add(s)

proc addToBuffer*(writer: var IndentFlushWriter, s: openArray[char]) {.inline.} =
  if writer.hasIndent:
    for c in s:
      checkIndent(writer, c)
      writer.flush.buffer.add(c)
  else:
    writer.flush.buffer.add(s)

proc addToBuffer*(writer: var IndentFlushWriter, rune: Rune) {.inline.} =
  if writer.hasIndent:
    checkIndent(writer, if rune.int > 127: char(128) else: char(rune))
  writer.flush.buffer.add(rune)

proc lockFlush*(writer: var FlushWriter) {.inline.} =
  inc writer.flush.bufferLocks

proc lockFlush*(writer: var IndentFlushWriter) {.inline.} =
  inc writer.flush.bufferLocks

proc unlockFlush*(writer: var FlushWriter) {.inline.} =
  assert writer.flush.bufferLocks > 0, "unpaired flush unlock"
  dec writer.flush.bufferLocks

proc unlockFlush*(writer: var IndentFlushWriter) {.inline.} =
  assert writer.flush.bufferLocks > 0, "unpaired flush unlock"
  dec writer.flush.bufferLocks

proc callBufferConsumer*(writer: var FlushWriter) {.inline.} =
  ## for internal use, only called if buffer consumer is known not to be nil
  callConsumer(writer.flush.buffer)
  if writer.flush.bufferLocks == 0: writer.flush.buffer.freeBefore = writer.flush.buffer.flushPos

proc callBufferConsumer*(writer: var IndentFlushWriter) {.inline.} =
  ## for internal use, only called if buffer consumer is known not to be nil
  callConsumer(writer.flush.buffer)
  if writer.flush.bufferLocks == 0: writer.flush.buffer.freeBefore = writer.flush.buffer.flushPos

proc consumeBuffer*(writer: var FlushWriter) {.inline.} =
  if not writer.flush.buffer.consumer.isNil:
    callBufferConsumer(writer)

proc consumeBuffer*(writer: var IndentFlushWriter) {.inline.} =
  if not writer.flush.buffer.consumer.isNil:
    callBufferConsumer(writer)

proc callBufferConsumerFull*(writer: var FlushWriter) {.inline.} =
  ## for internal use, only called if buffer consumer is known not to be nil
  callConsumerFull(writer.flush.buffer)
  if writer.flush.bufferLocks == 0: writer.flush.buffer.freeBefore = writer.flush.buffer.flushPos

proc callBufferConsumerFull*(writer: var IndentFlushWriter) {.inline.} =
  ## for internal use, only called if buffer consumer is known not to be nil
  callConsumerFull(writer.flush.buffer)
  if writer.flush.bufferLocks == 0: writer.flush.buffer.freeBefore = writer.flush.buffer.flushPos

proc consumeBufferFull*(writer: var FlushWriter) {.inline.} =
  if not writer.flush.buffer.consumer.isNil:
    callBufferConsumerFull(writer)

proc consumeBufferFull*(writer: var IndentFlushWriter) {.inline.} =
  if not writer.flush.buffer.consumer.isNil:
    callBufferConsumerFull(writer)

proc write*(writer: var FlushWriter, c: char) {.inline.} =
  writer.addToBuffer(c)
  writer.consumeBuffer()

proc write*(writer: var FlushWriter, c: Rune) {.inline.} =
  writer.addToBuffer(c)
  writer.consumeBuffer()

proc write*(writer: var FlushWriter, s: string) {.inline.} =
  writer.addToBuffer(s)
  writer.consumeBuffer()

proc write*(writer: var FlushWriter, s: openArray[char]) {.inline.} =
  writer.addToBuffer(s)
  writer.consumeBuffer()

proc write*(writer: var IndentFlushWriter, c: char) {.inline.} =
  writer.addToBuffer(c)
  writer.consumeBuffer()

proc write*(writer: var IndentFlushWriter, c: Rune) {.inline.} =
  writer.addToBuffer(c)
  writer.consumeBuffer()

proc write*(writer: var IndentFlushWriter, s: string) {.inline.} =
  writer.addToBuffer(s)
  writer.consumeBuffer()

proc write*(writer: var IndentFlushWriter, s: openArray[char]) {.inline.} =
  writer.addToBuffer(s)
  writer.consumeBuffer()

proc finishWrite*(writer: var FlushWriter): string {.inline.} =
  ## returns leftover buffer
  if false: assert writer.flush.bufferLocks == 0, "unpaired flush lock"
  if not writer.flush.buffer.consumer.isNil:
    writer.flush.buffer.callConsumerFinish()
  if writer.bufferStart == 0:
    result = move writer.currentBuffer
  elif writer.bufferStart < writer.currentBuffer.len:
    result = writer.currentBuffer[writer.bufferStart ..< writer.currentBuffer.len]
  else:
    result = ""

proc finishWrite*(writer: var IndentFlushWriter): string {.inline.} =
  ## returns leftover buffer
  if false: assert writer.flush.bufferLocks == 0, "unpaired flush lock"
  if not writer.flush.buffer.consumer.isNil:
    writer.flush.buffer.callConsumerFinish()
  if writer.bufferStart == 0:
    result = move writer.currentBuffer
  elif writer.bufferStart < writer.currentBuffer.len:
    result = writer.currentBuffer[writer.bufferStart ..< writer.currentBuffer.len]
  else:
    result = ""

{.pop.}
