#!/usr/bin/perl -w

 use strict;
 use warnings;

 use Test::More tests => 14;
 use DBIx::Lite;

 my $dbix = DBIx::Lite->new(driver_name => 'Pg');

{
    my ($sql) = eval { $dbix->table('authors')->select('id')->select_sql };
    ok !$@, 'no exception thrown';
    if ($@) {
        diag $@;
    }
    is $sql, 'SELECT me.id FROM authors AS me', 'simple select';
}

{
    my ($sql) = $dbix->table('authors')->select_sql;
    is $sql, 'SELECT me.* FROM authors AS me', 'basic';
}

{
    my ($sql) = $dbix->table('authors')->select('id')->distinct->select_sql;
    is $sql, 'SELECT DISTINCT me.id FROM authors AS me', 'distinct';
}

{
    my ($sql) = $dbix->table('authors')->select('id')->distinct('name')->select_sql;
    is $sql, 'SELECT DISTINCT ON (name) me.id FROM authors AS me', 'distinct on';
}

{
    my ($sql) = $dbix->table('authors')->select('id')->distinct(\'lower(name)')->select_sql;
    is $sql, 'SELECT DISTINCT ON (lower(name)) me.id FROM authors AS me', 'distinct on with expression';
}

{
    my ($sql) = $dbix->table('authors')->table_alias('target')->select('id')->select_sql;
    is $sql, 'SELECT target.id FROM authors AS target', 'custom table alias';
}

{
    my ($sql) = $dbix->table('authors')
        ->with(t => \"SELECT 1 AS id")
        ->select('id')
        ->select_sql;
    is $sql, 'WITH t AS (SELECT 1 AS id) SELECT me.id FROM authors AS me', 'select with CTE';
}

{
    my ($sql, @bind) = $dbix->table('authors')
        ->with(t => \"SELECT 1 AS id, 'Larry' AS name")
        ->insert_sql({ id => 1, name => 'Larry' });
    is $sql, q{WITH t AS (SELECT 1 AS id, 'Larry' AS name) INSERT INTO authors ( id, name) VALUES ( ?, ? )},
        'insert with CTE';
    is_deeply \@bind, [1, 'Larry'], 'insert with CTE bind values';
}

{
    my ($sql, @bind) = $dbix->table('authors')
        ->with(t => \"SELECT 1 AS id")
        ->search({ id => 1 })
        ->update_sql({ name => 'Larry' });
    is $sql, 'WITH t AS (SELECT 1 AS id) UPDATE authors SET name = ? WHERE ( id = ? )',
        'update with CTE';
    is_deeply \@bind, ['Larry', 1], 'update with CTE bind values';
}

{
    my ($sql, @bind) = $dbix->table('authors')
        ->with(t => \"SELECT 1 AS id")
        ->search({ id => 1 })
        ->delete_sql;
    is $sql, 'WITH t AS (SELECT 1 AS id) DELETE FROM authors WHERE ( id = ? )',
        'delete with CTE';
    is_deeply \@bind, [1], 'delete with CTE bind values';
}

 __END__