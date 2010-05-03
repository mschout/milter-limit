
use strict;
use warnings;



use ExtUtils::MakeMaker 6.31;



my %WriteMakefileArgs = (
                       'test' => {
                                   'TESTS' => 't/*.t'
                                 },
                       'NAME' => 'App::Milter::Limit',
                       'DISTNAME' => 'App-Milter-Limit',
                       'CONFIGURE_REQUIRES' => {
                                                 'ExtUtils::MakeMaker' => '6.31'
                                               },
                       'AUTHOR' => 'Michael Schout <mschout@cpan.org>',
                       'BUILD_REQUIRES' => {
                                             'Module::Signature' => '0',
                                             'Test::More' => '0',
                                             'Socket' => '0'
                                           },
                       'ABSTRACT' => 'Sendmail Milter that limits message rate by sender',
                       'EXE_FILES' => [
                                        'bin/milter-limit'
                                      ],
                       'VERSION' => '0.52',
                       'PREREQ_PM' => {
                                        'Getopt::Long' => '0',
                                        'Pod::Usage' => '0',
                                        'FindBin' => '0',
                                        'Class::Accessor' => '0',
                                        'Sys::Syslog' => '0',
                                        'Exporter' => '0',
                                        'Carp' => '0',
                                        'Class::Singleton' => '0',
                                        'POSIX' => '0',
                                        'Sendmail::PMilter' => '0.98',
                                        'File::Path' => '2.0',
                                        'File::Pid' => '0',
                                        'Config::Tiny' => '0'
                                      },
                       'LICENSE' => 'perl'
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



