#!/usr/bin/env perl6
use DBIish;
use File::Find;

sub MAIN (Str :i($input), Str :o($output))
{
    # Parse paths and ensure they end in slashes
    my %options = input => $input, output => $output;
    %options<input> = %options<input> ~ '/' unless %options<input>.match(/\/$/);
    %options<output> = %options<output> ~ '/' unless %options<output>.match(/\/$/);

    # Create database
    my $db_file = %options<output> ~ 'music.db';
    my $db = DBIish.connect('SQLite', database => $db_file);
    my $db_setup = $db.do(q:to/SQL/);
        CREATE TABLE music (
            artist TEXT,
            title TEXT,
            album TEXT,
            year TEXT,
            genre TEXT
        )
        SQL
    my $db_update = $db.prepare('INSERT INTO music (artist, title, album, year, genre) VALUES (?, ?, ?, ?, ?)');

    my @mp3s = find(dir => %options<input>, name => /.mp3$/ );
    for @mp3s -> $file
    {
        my $info = qq:x/id3v2 -l "$file"/;
        my @tags = $info.lines.grep(/TIT2|TPE1|TALB|TYER|TCON/);
        for @tags { $_.=subst(/^(.*?)\)\: /, ''); $_.=subst(/\(\d+\)$/, ''); $_.=trim; }
        my %tag = <title artist album year genre> Z=> @tags;
        $db_update.execute(%tag<artist>, %tag<title>, %tag<album>, %tag<year>, %tag<genre>);
    }
}
