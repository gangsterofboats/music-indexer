#!/usr/bin/env python
import glob
from mutagen.mp3 import MP3
import sqlite3

# Create database
db = sqlite3.connect('music.db')
c = db.cursor()

c.execute('''
CREATE TABLE music (
    id INTEGER PRIMARY KEY,
    artist TEXT,
    title TEXT,
    album TEXT,
    year TEXT,
    genre TEXT
)''')

# Glob mp3s
mp3s = glob.glob('**/*.mp3', recursive=True)

# Main part of script
for mp3 in mp3s:
    info = MP3(mp3)
    tag = {'artist': str(info['TPE1']), 'title': str(info['TIT2']), 'album': str(info['TALB']), 'year': str(info['TDRC']), 'genre': str(info['TCON'])}
    c.execute('INSERT INTO music (artist, title, album, year, genre) VALUES (?, ?, ?, ?, ?)', (tag['artist'], tag['title'], tag['album'], tag['year'], tag['genre']))

db.commit()
db.close()
