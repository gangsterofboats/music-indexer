#!/usr/bin/tclsh
package require tdbc::sqlite3

# Parse arguments
set inputPath [lindex $argv 1]
set outputPath [lindex $argv 3]

# Ensure directory paths end in slashes
if {[string index $inputPath end] != "/"} {
    append inputPath "/"
}
if {[string index $outputPath end] != "/"} {
    append outputPath "/"
}

# Setup the database
set dbPath [append outputPath "music.db"]
set dbC [tdbc::sqlite3::connection create db $dbPath]
set stmt [$dbC prepare {CREATE TABLE music (id INTEGER PRIMARY KEY, artist TEXT, title TEXT, album TEXT, year TEXT, genre TEXT)}]
$stmt execute
$stmt close

# Main part of script
set artists [glob -directory $inputPath *]
foreach artist $artists {
    set albums [glob -dir $artist *]
    foreach album $albums {
        set mp3s [glob -dir $album *.mp3]
        foreach mp3 $mp3s {
            set info [exec id3v2 -l "$mp3"]
            set info [split $info "\n"]
            set info [lsearch -all -inline -regexp $info "TIT2|TPE1|TALB|TYER|TCON"]
            set tags [dict create \
                      title [regsub -all {^(.*?)\)\: } [lindex $info 0] ""] \
                      artist [regsub -all {^(.*?)\)\: } [lindex $info 1] ""] \
                      album [regsub -all {^(.*?)\)\: } [lindex $info 2] ""] \
                      year [regsub -all {^(.*?)\)\: } [lindex $info 3] ""] \
                      genre [regsub -all {^(.*?)\)\: } [lindex $info 4] ""] \
                     ]
            dict set tags genre [regsub -all { \(\d+\)$} [dict get $tags genre] ""]
            set stmt [$dbC prepare {INSERT INTO music (artist, title, album, year, genre) VALUES (:artist, :title, :album, :year, :genre)}]
            $stmt execute $tags
            $stmt close
        }
    }
}
$dbC close
