# Package

version       = "0.1.0"
author        = "metagn"
description   = "data streaming using a dynamic buffer"
license       = "MIT"
srcDir        = "src"


# Dependencies

requires "nim >= 1.6.0"

when (NimMajor, NimMinor) >= (1, 4):
  when (compiles do: import nimbleutils):
    import nimbleutils
    # https://github.com/metagn/nimbleutils

task docs, "build docs for all modules":
  exec "nim r ci/build_docs.nim"

task tests, "run tests for multiple backends and defines":
  exec "nim r ci/run_tests.nim"
