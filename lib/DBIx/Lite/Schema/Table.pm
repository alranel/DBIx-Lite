package DBIx::Lite::Schema::Table;
use strict;
use warnings;

sub new {
    my $class = shift;
    my (%params) = @_;
    
    my $self = {
        class           => undef,
        resultset_class => undef,
        pk              => delete $params{pk} || [],
        has_many        => {},
        has_one         => {},
    };
    
    for (qw(name)) {
        $self->{$_} = delete $params{$_} or die "$_ argument needed\n";
    }
    
    if ($self->{autopk} = delete $params{autopk}) {
        !ref $self->{autopk} or die "autopk only accepts a single column\n";
        $self->{pk} = [$self->{autopk}];
    }
    
    !%params
        or die "Unknown options: " . join(', ', keys %params) . "\n";
    
    bless $self, $class;
    $self;
}

sub pk {
    my $self = shift;
    my $val = shift;
    
    if ($val) {
        $self->{pk} = [ grep defined $_, (ref $val eq 'ARRAY' ? @$val : $val) ];
        return $self;
    }
    return @{$self->{pk}};
}

sub autopk {
    my $self = shift;
    my $val = shift;
    
    if ($val) {
        $self->{autopk} = $val;
        $self->{pk} = [$val];
        return $self;
    }
    return $self->{autopk};
}

sub class {
    my $self = shift;
    my $class = shift;
    
    if ($class) {
        $self->{class} = $class;
        return $self;
    }
    
    return undef if !$self->{class};
    $self->_init_package($self->{class}, 'DBIx::Lite::Row');
    return $self->{class};
}

sub resultset_class {
    my $self = shift;
    my $class = shift;
    
    if ($class) {
        $self->{resultset_class} = $class;
        return $self;
    }
    
    return undef if !$self->{resultset_class};
    $self->_init_package($self->{resultset_class}, 'DBIx::Lite::ResultSet');
    return $self->{resultset_class};
}

sub _init_package {
    my $self = shift;
    my ($package, $base) = @_;
    
    return if $package->isa($base);
    
    # check that no $base method would be overwritten by the package
    {
        no strict 'refs';
        my %subroutines = map { $_ => 1 }
            grep defined &{"$package\::$_"}, keys %{"$package\::"};
        
        my @base_subroutines = grep defined &{"$base\::$_"}, keys %{"$base\::"};
        for (@base_subroutines) {
            die "$package defines a '$_' subroutine/method; cannot use it as custom class\n"
                if $subroutines{$_};
        }
    }
    
    {
        no strict 'refs';
        push @{$package."::ISA"}, $base;
    }
}

1;

=head1 OVERVIEW

This class holds the very loose table definitions that enable some advanced
features of L<DBIx::Lite>. Note that you can do all main operations, including
searches and manipulations, with no need to define any schema.

This class is not supposed to be instantiated manually. You usually get your 
Table objects by calling the C<table()> method on a L<DBIx::Lite::Schema> object:

    my $table = $dbix->schema->table('books');

=head2 pk

This method accepts a list of fields to be used as the table primary key. Setting
a primary key enables C<update()> and C<delete()> methods on L<DBIx::Lite::Row>
objects.

    $dbix->schema->table('books')->pk('id');

=head2 autopk

This method works like L<pk> but also marks the supplied column name as an 
autoincrementing key. This will trigger the retrieval of the autoincremented
id upon creation of new records with the C<insert()> method.
C<autopk()> only accepts a single column.

    $dbix->schema->table('books')->autopk('id');

You probably want to use C<autopk()> for most tables, and only use L<pk> for those
many-to-many relationship tables not having an autoincrementing id:

    $dbix->schema->one_to_many('users.id' => 'users_tasks.user_id');
    $dbix->schema->one_to_many('tasks.id' => 'users_tasks.task_id');
    $dbix->schema->table('users')->autopk('id');
    $dbix->schema->table('tasks')->autopk('id');
    $dbix->schema->table('users_tasks')->pk('user_id', 'task_id');

=head2 class

This method accepts a package name that DBIx::Lite will use for this table's 
Result objects. You don't need to declare such package name anywhere else, as
DBIx::Lite will create that class for you.

    $dbix->schema->table('books')->class('My::Book');
    my $book = $dbix->table('books')->find({ id => 2 });
    # $book is a My::Book

The class will subclass L<DBIx::Lite::Row>. You can also supply an existing package
name or declare your methods inline:

    $dbix->schema->table('books')->class('My::Book');
    
    sub My::Book::get_page_count {
        my $self = shift;
        return $self->page_count;
    }

=head2 resultset_class

This method accepts a package name that DBIx::Lite will use for this table's 
ResultSet objects. You don't need to declare such package name anywhere else, as
DBIx::Lite will create that class for you.

    $dbix->schema->table('books')->resultset_class('My::Book::ResultSet');
    my $books_rs = $dbix->table('books')->search({ year => 2012 });
    # $books_rs is a My::Book::ResultSet

The class will subclass L<DBIx::Lite::ResultSet>. You can also supply an existing 
package name or declare your methods inline:

    $dbix->schema->table('books')->resultset_class('My::Book::ResultSet');
    
    sub My::Book::ResultSet::get_multilanguage {
        my $self = shift;
        return $self->search({ multilanguage => 1 });
    }

=for Pod::Coverage new

=cut
