when (NimMajor, NimMinor) >= (1, 4):
  when (compiles do: import nimbleutils):
    import nimbleutils
    # https://github.com/metagn/nimbleutils

when not declared(buildDocs):
  {.error: "docs task not implemented, need nimbleutils".}

# run from project root

import std/[os, strutils]

let srcDir = "src"
var files: seq[FilePath] = @[]
for dir in [srcDir, srcDir / "fleu"]: # ignore includes dir
  for kind, f in walkDir(dir):
    if kind == pcFile and f.endsWith(".nim"):
      files.add f
buildDocs(files, gitUrl = "https://github.com/holo-nim/fleu", rootDir = srcDir)
