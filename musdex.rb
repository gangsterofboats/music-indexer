#!/usr/bin/env ruby
require 'id3tag'
require 'sqlite3'

db = SQLite3::Database.new 'music.db'

db.execute <<SQL
  CREATE TABLE music (
    artist TEXT,
    title TEXT,
    album TEXT,
    year TEXT,
    genre TEXT
  );
SQL

mp3s = Dir.glob('**/*.mp3')
mp3s.each do |file|
  ID3Tag.read(File.open(file, 'rb')) do |tag|
    db.execute('INSERT INTO music (artist, title, album, year, genre) VALUES (?, ?, ?, ?, ?)', [tag.artist, tag.title, tag.album, tag.year, tag.genre])
  end
end
