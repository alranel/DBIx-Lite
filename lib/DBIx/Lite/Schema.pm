package DBIx::Lite::Schema;
use strict;
use warnings;

use DBIx::Lite::Schema::Table;

sub new {
    my $class = shift;
    my (%params) = @_;
    
    my $self = {
        tables => {},
    };
    
    if (my $tables = delete $params{tables}) {
        foreach my $table_name (keys %$tables) {
            $tables->{$table_name}{name} = $table_name;
            $self->{tables}{$table_name} = DBIx::Lite::Schema::Table->new($tables->{$table_name});
        }
    }
    
    !%params
        or die "Unknown options: " . join(', ', keys %params) . "\n";
    
    bless $self, $class;
    $self;
}

sub table {
    my $self = shift;
    my $table_name = shift;
    $self->{tables}{$table_name} ||= DBIx::Lite::Schema::Table->new(name => $table_name);
    return $self->{tables}{$table_name};
}

sub one_to_many {
    my $self = shift;
    my ($from, $to, $their_accessor) = @_;
    
    $from && $from =~ /^(.+)\.(.+)$/
        or die "Relationship keys must be defined in table.column format\n";
    my $from_table = $self->table($1);
    my $from_key = $2;
    
    $to && $to =~ /^(.+)\.(.+)$/
        or die "Relationship keys must be defined in table.column format\n";
    my $to_table = $self->table($1);
    my $to_key = $2;
    
    $from_table->{has_many}{ $to_table->{name} } = [ $to_table->{name}, { $from_key => $to_key } ];
    $to_table->{has_one}{ $their_accessor } = [ $from_table->{name}, { $to_key => $from_key } ]
        if $their_accessor;
}

1;

=head1 OVERVIEW

This class holds the very loose schema definitions that enable some advanced
features of L<DBIx::Lite>. Note that you can do all main operations, including
searches and manipulations, with no need to define any schema.

An empty DBIx::Lite::Schema is created every time you create a L<DBIx::Lite>
object. Then you can access it to customize it. Otherwise, you can prepare a 
Schema object and reutilize it across multiple connections:

    my $schema = DBIx::Lite::Schema->new;
    my $conn1 = DBIx::Lite->new(schema => $schema)->connect(...);
    my $conn2 = DBIx::Lite->new(schema => $schema)->connect(...);

=method new

The constructor takes no arguments.

=method table

This method accepts a table name and returs the L<DBIx::Lite::Schema::Table>
object corresponding to the requested table. You can then call methods on it.

    $schema->table('books')->autopk('id');

=method one_to_many

This methods sets up a 1-to-N relationship between two tables. Just pass two
table names to it, appending the relation key column name:

    $schema->one_to_many('authors.id' => 'books.author_id');

This will have the following effects:

=over 4

=item provide a C<books> accessor method in the authors Result objects

=item provide a C<books> accessor method in the authors ResultSet objects

=item allow to call C<$author->insert_related('books', {...})>

=back

If you supply a third argument, it will be used to set up the reverse accessor
method. For example:

    $schema->one_to_many('authors.id' => 'books.author_id', 'author');

will install a C<author> accessor method in the books Result objects.

Note that relationships can be chained:

    $dbix->schema->one_to_many('authors.id' => 'books.author_id');
    $dbix->schema->one_to_many('books.id' => 'chapters.books_id');
    my @chapters = $dbix
        ->table('authors')
        ->search({ country => 'IT' })
        ->books
        ->chapters
        ->search({ page_count => { '>' => 20 } })
        ->all;

You can use the same approach to traverse many-to-many relationships.

=cut
