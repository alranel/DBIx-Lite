
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Chained and minimal ORM",
  "AUTHOR" => "Alessandro Ranellucci <aar\@cpan.org>",
  "BUILD_REQUIRES" => {
    "DBD::SQLite" => "1.29",
    "Test::More" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "DBIx-Lite",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "DBIx::Lite",
  "PREREQ_PM" => {
    "Clone" => 0,
    "DBIx::Connector" => 0,
    "Data::Page" => 0,
    "List::MoreUtils" => 0,
    "SQL::Abstract::More" => 0
  },
  "VERSION" => "0.12",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.56) } ) {
  my $br = delete $WriteMakefileArgs{BUILD_REQUIRES};
  my $pp = $WriteMakefileArgs{PREREQ_PM};
  for my $mod ( keys %$br ) {
    if ( exists $pp->{$mod} ) {
      $pp->{$mod} = $br->{$mod} if $br->{$mod} > $pp->{$mod};
    }
    else {
      $pp->{$mod} = $br->{$mod};
    }
  }
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);



