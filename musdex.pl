#!/usr/bin/env perl
use strict;
use warnings;
use DBI;
use File::Find;
use MP3::Tag;
use feature 'say';

# Create database
my $db = DBI->connect('DBI:SQLite:dbname=music.db');
my $ctab = qq(
    CREATE TABLE music (
    artist TEXT,
    title TEXT,
    album TEXT,
    year TEXT,
    genre TEXT
    ));
$db->do($ctab);
my $statement = $db->prepare('INSERT INTO music (artist, title, album, year, genre) VALUES (?, ?, ?, ?, ?)');

# Sub to feed to File::Find sub
sub music_indexer
{
    # my $file = $File::Find::name;
    my $file = $_;

    if ($file =~ /\.mp3$/)
    {
        my $mp3 = MP3::Tag->new($file);
        my $tag = $mp3->autoinfo();
        $statement->execute($tag->{artist}, $tag->{title}, $tag->{album}, $tag->{year}, $tag->{genre});
    }
}

# Main part of script
find(\&music_indexer, '.');
