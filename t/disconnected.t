#!/usr/bin/perl -w

 use strict;
 use warnings;

 use Test::More tests => 2;
 use DBIx::Lite;

 my $dbix = DBIx::Lite->new(driver_name => 'Pg');

{
    my ($sql) = eval { $dbix->table('authors')->select('id')->select_sql };
    ok !$@, 'no exception thrown';
    if ($@) {
        diag $@;
    }
    is $sql, 'SELECT me.id FROM authors AS me';
}

 __END__