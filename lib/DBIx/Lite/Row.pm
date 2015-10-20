package DBIx::Lite::Row;
use strict;
use warnings;

use Carp qw(croak);
use Clone qw(clone);
use vars qw($AUTOLOAD);
$Carp::Internal{$_}++ for __PACKAGE__;

sub _new {
    my $class = shift;
    my (%params) = @_;
    
    my $self = {};
    
    for (qw(dbix_lite table data)) {
        $self->{$_} = delete $params{$_} or croak "$_ argument needed";
    }
    
    !%params
        or croak "Unknown options: " . join(', ', keys %params);
    
    bless $self, $class;
    $self;
}

sub pk {
    my $self = shift;
    
    my @keys = $self->{table}->pk
        or croak "No primary key defined for table " . $self->{table}{name};
    
    grep(!exists $self->{data}{$_}, @keys)
        and croak "No primary key data retrieved for table " . $self->{table}{name};
    
    return { map +($_ => $self->{data}{$_}), @keys };
}

sub hashref {
    my $self = shift;
    
    return clone $self->{data};
}

sub update {
    my $self = shift;
    my $update_cols = shift or croak "update() requires a hashref";
    
    $self->{dbix_lite}->table($self->{table}{name})->search($self->pk)->update($update_cols);
    $self->{data}{$_} = $update_cols->{$_} for keys %$update_cols;
    $self;
}

sub delete {
    my $self = shift;
    
    $self->{dbix_lite}->table($self->{table}{name})->search($self->pk)->delete;
    undef $self;
}

sub insert_related {
    my $self = shift;
    my ($rel_name, $insert_cols) = @_;
    $rel_name or croak "insert_related() requires a table name";
    
    my ($table_name, $my_key, $their_key) = $self->_relationship($rel_name)
        or croak "No $rel_name relationship defined for " . $self->{table}{name};
    
    return $self->{dbix_lite}
        ->table($table_name)
        ->insert({ $their_key => $self->{data}{$my_key}, %$insert_cols });
}

sub _relationship {
    my $self = shift;
    my ($rel_name) = @_;
    
    my ($rel_type) = grep $self->{table}{$_}{$rel_name}, qw(has_one has_many)
        or return ();
    
    my $rel = $self->{table}{$rel_type}{$rel_name};
    my ($table_name, $my_key, $their_key) = ($rel->[0], %{ $rel->[1] });
    
    exists $self->{data}{$my_key}
        or croak "No $my_key key retrieved from " . $self->{table}{name};
    
    return ($table_name, $my_key, $their_key, $rel_type);
}

sub get {
    my $self = shift;
    my $key = shift or croak "get() requires a column name";
    return $self->{data}{$key};
}

sub AUTOLOAD {
    my $self = shift or return undef;
    
    # Get the called method name and trim off the namespace
    (my $method = $AUTOLOAD) =~ s/.*:://;
	
    if (exists $self->{data}{$method}) {
        return $self->{data}{$method};
    }
    
    if (my ($table_name, $my_key, $their_key, $rel_type) = $self->_relationship($method)) {
        my $rs = $self->{dbix_lite}
            ->table($table_name)
            ->search({ "me.$their_key" => $self->{data}{$my_key} });
        return $rel_type eq 'has_many' ? $rs : $rs->single;
    }
    
    croak sprintf "No %s method is provided by this %s (%s) object",
        $method, ref($self), $self->{table}{name};
}

sub DESTROY {}

1;

=head1 OVERVIEW

This class is not supposed to be instantiated manually. You usually get your 
first Result objects by calling some retrieval methods on a L<DBIx::Lite::ResultSet>
object.

Accessor methods will be provided automatically for all retrieved columns and for 
related tables (see docs for L<DBIx::Lite::Schema>).

    my $book = $dbix->table('books')->find({ id => 10 });
    print $book->title;

=head2 hashref

This method returns a hashref containing column values.

    my $hashref = $book->hashref;
    print "$_ = $hashref->{$_}\n" for keys %$hashref;

=head2 update

This method is only available if you specified a primary key for the table
(see docs for L<DBIx::Lite::Schema>).

It accepts a hashref of column values and it will perform a SQL C<UPDATE> command.

=head2 delete

This method is only available if you specified a primary key for the table
(see docs for L<DBIx::Lite::Schema>).

It will perform a SQL C<DELETE> command.

=head2 insert_related

This method is only available if you specified a primary key for the table
(see docs for L<DBIx::Lite::Schema>).

It accepts the name of the relted column you want to insert into, and a hashref
of the column values to pass to the C<INSERT> command. It will return the inserted
object.

    $dbix->schema->one_to_many('authors.id' => 'books.author_id');
    my $book = $author->insert_related('books', { title => 'Camel Tales' });

=for Pod::Coverage get pk

=cut
