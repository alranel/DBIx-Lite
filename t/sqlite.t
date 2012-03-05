#!/usr/bin/perl -w

use strict;
use warnings;

use Test::More tests => 4;
use DBIx::Lite;

my $dbix = DBIx::Lite->new( abstract => { quote_char => '`', name_sep => '.' } );
$dbix->connect('dbi:SQLite:dbname=t/test.db', '', '');

$dbix->dbh->do('DROP TABLE IF EXISTS books');
$dbix->dbh->do('CREATE TABLE books (id NUMBER, title TEXT, year NUMBER, key NUMBER)');

$dbix->table('books')->insert({ id => 1, title => 'Camel Tales', year => 2012, key => 1 });
$dbix->table('books')->insert({ id => 2, title => 'Camel Adventures', year => 2010, key => 0 });

{
    my $count = $dbix->table('books')->count;
    is $count, 2, 'row count';
}

{
    my $book = $dbix->table('books')->find({ year => 2010 });
    isa_ok $book, 'DBIx::Lite::Row';
    is $book->id, 2, 'fetch result';
}

{
    my @titles = $dbix->table('books')->order_by('+title')->get_column('title');
    is_deeply \@titles, ['Camel Adventures', 'Camel Tales'], 'get_column';
}

__END__
