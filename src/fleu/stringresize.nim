import std/strbasics

const fleuResizeFallbackInfiniteCapacity* {.booldefine.} = false
  ## if string capacity is not available, assumes
  ## strings have infinite capacity, so used data is never freed
  ## 
  ## off by default, instead the next power of 2 from the length is used

when not declared(capacity):
  when fleuResizeFallbackInfiniteCapacity:
    template capacity(s: string): int {.used.} = high(int)
  else:
    from std/math import nextPowerOfTwo
    template capacity(s: string): int {.used.} =
      min(nextPowerOfTwo(s.len), 4)

{.push checks: off, stacktrace: off.}

proc smartResizeAdd*(s: var string, a: openArray[char], freeBefore: int): bool {.inline.} =
  ## adds `a` to `s`; if operation would result in resize, deletes characters
  ## before `freeBefore` and returns `true`, otherwise returns `false`
  when false:
    # shim previously used for nimscript/vm/js
    s.add(a)
    result = false
  else:
    if freeBefore != 0 and s.len + a.len > s.capacity:
      # XXX splice for js
      let realSLen = s.len - freeBefore
      for i in 0 ..< realSLen:
        s[i] = s[i + freeBefore]
      s.setLen(realSLen + a.len)
      for i in 0 ..< a.len:
        s[i + realSLen] = a[i]
      result = true
    else:
      s.add(a)
      result = false

proc smartResizeAdd*(s: var string, a: char, freeBefore: int): bool {.inline.} =
  ## adds `a` to `s`; if operation would result in resize, deletes characters
  ## before `freeBefore` and returns `true`, otherwise returns `false`
  when nimvm:
    # shim previously used for nimscript/vm/js
    s.add(a)
    result = false
  else:
    if freeBefore != 0 and s.len + 1 > s.capacity:
      # XXX splice for js
      let realSLen = s.len - freeBefore
      for i in 0 ..< realSLen:
        s[i] = s[i + freeBefore]
      s.setLen(realSLen + 1)
      s[realSLen] = a
      result = true
    else:
      s.add(a)
      result = false

{.pop.}
