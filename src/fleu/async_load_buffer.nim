import ./stringresize, lib/asyncwrapper

type
  AsyncBufferLoader* = proc (): Future[string]
  AsyncLoadBuffer* = object
    data*: string
      ## buffer string, users need to access directly & keep track of position
    loader*: AsyncBufferLoader
      ## loads a string at a time to add to the buffer when needed
      ## set to nil after returning empty string
    freeBefore*: int
      ## position before which we can cull the buffer

{.push checks: off, stacktrace: off.}

proc initAsyncLoadBuffer*(str: sink string): AsyncLoadBuffer {.inline.} =
  result = AsyncLoadBuffer(data: str, loader: nil)

proc initAsyncLoadBuffer*(loader: AsyncBufferLoader, capacity = 32): AsyncLoadBuffer {.inline.} =
  result = AsyncLoadBuffer(data: newStringOfCap(capacity), loader: loader)

when declared(asyncstreams):
  proc initAsyncLoadBuffer*(stream: FutureStream[string], capacity = 32): AsyncLoadBuffer {.inline.} =
    let loader = proc (): Future[string] {.async.} =
      let (success, data) = await read(stream)
      if success:
        result = data
      else:
        result = ""
    result = initAsyncLoadBuffer(loader, capacity)
  proc initAsyncLoadBuffer*(stream: FutureStream[char], loadAmount = 16, capacity = 32): AsyncLoadBuffer {.inline.} =
    let loader = proc (): Future[string] {.async.} =
      result = ""
      while result.len < loadAmount:
        let (success, data) = await read(stream)
        if success:
          result.add data
        else:
          return
    result = initAsyncLoadBuffer(loader, capacity)
  proc initAsyncLoadBuffer*(stream: FutureStream[byte], loadAmount = 16, capacity = 32): AsyncLoadBuffer {.inline.} =
    let loader = proc (): Future[string] {.async.} =
      result = ""
      while result.len < loadAmount:
        let (success, data) = await read(stream)
        if success:
          result.add char(data)
        else:
          return
    result = initAsyncLoadBuffer(loader, capacity)

when declared(AsyncFile):
  proc initAsyncLoadBuffer*(file: AsyncFile, loadAmount = 16, capacity = 32): AsyncLoadBuffer {.inline.} =
    ## `file` has to last as long as the reader
    var buf = newString(loadAmount) # save allocations by capturing this in the loader, array would need constant load amount
    let loader = proc (): Future[string] {.async.} =
      buf.setLen(loadAmount)
      let n = await readBuffer(file, addr buf[0], loadAmount)
      buf.setLen(n)
      result = buf
    result = initAsyncLoadBuffer(loader, capacity)

proc callLoader*(buffer: var AsyncLoadBuffer): Future[int] {.async.} =
  ## for internal use, only called if buffer loader is known not to be nil
  ## returns number of moved chars
  # probably better not to inline
  result = 0
  let ex = await buffer.loader()
  if ex.len == 0:
    buffer.loader = nil
    return result
  let moved = buffer.data.smartResizeAdd(ex, buffer.freeBefore)
  if moved:
    result = buffer.freeBefore
    buffer.freeBefore = 0

proc loadOnce*(buffer: var AsyncLoadBuffer): Future[int] {.async.} =
  ## returns number of moved chars
  # is there a way to inline this
  result = 0
  if not buffer.loader.isNil:
    result = await buffer.callLoader()

proc callLoaderBy*(buffer: var AsyncLoadBuffer, n: int): Future[int] {.async.} =
  ## for internal use, only called if buffer loader is known not to be nil
  ## returns number of moved chars
  # probably better not to inline
  when defined(js):
    # https://github.com/nim-lang/Nim/issues/25716
    {.push warning[ResultShadowed]: off.}
    var result = 0
    {.pop.}
  else:
    result = 0
  var left = n
  while left > 0:
    let ex = await buffer.loader()
    if ex.len == 0:
      buffer.loader = nil
      return result
    let moved = buffer.data.smartResizeAdd(ex, buffer.freeBefore)
    if moved:
      result += buffer.freeBefore
      buffer.freeBefore = 0
    left -= ex.len
  when defined(js):
    return result

proc loadBy*(buffer: var AsyncLoadBuffer, n: int): Future[int] {.async.} =
  ## returns number of moved chars
  # is there a way to inline this
  result = 0
  if not buffer.loader.isNil:
    result = await buffer.callLoaderBy(n)

{.pop.}
