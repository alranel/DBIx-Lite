#!/usr/bin/perl -w

use strict;
use warnings;

use Test::More tests => 2;
use DBIx::Lite;

my $dbix = DBIx::Lite->new;
my ($sql) = eval { $dbix->table('authors')->select('id')->select_sql };
{ local $TODO = 'disconnected SQL generation currently broken';
ok !$@, 'no exception thrown';
is $sql, 'SELECT me.id FROM authors AS me';
}

__END__
