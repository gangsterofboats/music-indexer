#!/usr/bin/env nim
# import math, ospaths
import db_sqlite, os, osproc, parseopt, re, sequtils, strutils

# Parse arguments
var options: tuple[inputPath: string, outputPath: string]
for kind, key, val in getopt():
  case kind
  of cmdArgument:
    continue
  of cmdLongOption, cmdShortOption:
    case key
    of "input", "i": options.inputPath = val
    of "output", "o": options.outputPath = val
  of cmdEnd: assert(false)

# Ensure directory paths end in slashes
if options.inputPath[^1] != '/':
  options.inputPath = options.inputPath & "/"
if options.outputPath[^1] != '/':
  options.outputPath = options.outputPath & "/"

# Create database
var dbFile = options.outputPath & "music.db"
var db = open(dbFile, nil, nil, nil)
db.exec(sql("""CREATE TABLE music (
            id INTEGER PRIMARY KEY,
            artist TEXT,
            title TEXT,
            album TEXT,
            year TEXT,
            genre TEXT
        )"""))

# Main part of program
for file in walkDirRec(options.inputPath):
  if file.contains(re"mp3") == true:
    var info = execProcess("id3v2 -l \"$1\"" % [file])
    var tags = splitLines(info)
    tags = filter(tags, proc(item: string): bool = contains(item, re"TIT2|TPE1|TALB|TYER|TCON"))
    for i in mitems(tags):
      i = i.replace(re"^(.*?)\)\: ", "")
      i = i.replace(re" \(\d+\)$", "")
    db.exec(sql"INSERT INTO music (artist, title, album, year, genre) VALUES (?, ?, ?, ?, ?)", tags[1], tags[0], tags[2], tags[3], tags[4])
db.close()
