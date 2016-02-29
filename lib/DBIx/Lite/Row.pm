package DBIx::Lite::Row;
use strict;
use warnings;

use Carp qw(croak);
use Clone qw(clone);
use vars qw($AUTOLOAD);
$Carp::Internal{$_}++ for __PACKAGE__;

sub _pk {
    my $self = shift;
    my $selfs = $self->__dbix_lite_row_storage;
    
    my @keys = $selfs->{table}->pk
        or croak "No primary key defined for table " . $selfs->{table}{name};
    
    grep(!exists $selfs->{data}{$_}, @keys)
        and croak "No primary key data retrieved for table " . $selfs->{table}{name};
    
    return { map +($_ => $selfs->{data}{$_}), @keys };
}

sub __dbix_lite_row_storage { $_[0] }

sub hashref {
    my $self = shift;
    my $selfs = $self->__dbix_lite_row_storage;
    
    return clone $selfs->{data};
}

sub update {
    my $self = shift;
    my $update_cols = shift or croak "update() requires a hashref";
    my $selfs = $self->__dbix_lite_row_storage;
    
    $selfs->{dbix_lite}->table($selfs->{table}{name})->search($self->_pk)->update($update_cols);
    $selfs->{data}{$_} = $update_cols->{$_} for keys %$update_cols;
    $self;
}

sub delete {
    my $self = shift;
    my $selfs = $self->__dbix_lite_row_storage;
    
    $selfs->{dbix_lite}->table($selfs->{table}{name})->search($self->_pk)->delete;
    undef $self;
}

sub insert_related {
    my $self = shift;
    my ($rel_name, $insert_cols) = @_;
    $rel_name or croak "insert_related() requires a table name";
    $insert_cols //= {};
    my $selfs = $self->__dbix_lite_row_storage;
    
    my ($table_name, $my_key, $their_key) = $self->_relationship($rel_name)
        or croak "No $rel_name relationship defined for " . $selfs->{table}{name};
    
    return $selfs->{dbix_lite}
        ->table($table_name)
        ->insert({ $their_key => $selfs->{data}{$my_key}, %$insert_cols });
}

sub _relationship {
    my $self = shift;
    my ($rel_name) = @_;
    my $selfs = $self->__dbix_lite_row_storage;
    
    my ($rel_type) = grep $selfs->{table}{$_}{$rel_name}, qw(has_one has_many)
        or return ();
    
    my $rel = $selfs->{table}{$rel_type}{$rel_name};
    my ($table_name, $my_key, $their_key) = ($rel->[0], %{ $rel->[1] });
    
    exists $selfs->{data}{$my_key}
        or croak "No $my_key key retrieved from " . $selfs->{table}{name};
    
    return ($table_name, $my_key, $their_key, $rel_type);
}

sub get {
    my $self = shift;
    my $key = shift or croak "get() requires a column name";
    my $selfs = $self->__dbix_lite_row_storage;
    
    return $selfs->{data}{$key};
}

sub AUTOLOAD {
    my $self = shift or return undef;
    my $selfs = $self->__dbix_lite_row_storage;
    
    # Get the called method name and trim off the namespace
    (my $method = $AUTOLOAD) =~ s/.*:://;
	
    if (exists $selfs->{data}{$method}) {
        return $selfs->{data}{$method};
    }
    
    if (my ($table_name, $my_key, $their_key, $rel_type) = $self->_relationship($method)) {
        my $rs = $selfs->{dbix_lite}
            ->table($table_name)
            ->search({ "me.$their_key" => $selfs->{data}{$my_key} });
        return $rel_type eq 'has_many' ? $rs : $rs->single;
    }
    
    croak sprintf "No %s method is provided by this %s (%s) object",
        $method, ref($self), $selfs->{table}{name};
}

sub DESTROY {}

1;

=head1 OVERVIEW

This class is not supposed to be instantiated manually. You usually get your 
first Result objects by calling one of retrieval methods on a L<DBIx::Lite::ResultSet>
object.

Accessor methods will be provided automatically for all retrieved columns and for 
related tables (see docs for L<DBIx::Lite::Schema>).

    my $book = $dbix->table('books')->find({ id => 10 });
    print $book->title;
    print $book->author->name;

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

=for Pod::Coverage get _pk

=cut
