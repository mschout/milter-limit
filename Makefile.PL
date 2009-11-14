use 5.008;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME => 'Milter::Limit',
    VERSION_FROM => 'lib/Milter/Limit.pm',
    EXE_FILES => ['bin/milter-limit'],
    PREREQ_PM    => {
        'Class::Accessor'   => 0,
        'Class::Singleton'  => 0,
        'Sys::Syslog'       => 0,
        'Config::Tiny'      => 0,
        'DBD::SQLite'       => 0,  # not sure what min version we need
        'Sendmail::PMilter' => 0.90,
        'Pod::Usage'        => 0,
        'File::Pid'         => 0
    },
    ($] >= 5.005 ?
      (ABSTRACT_FROM => 'lib/Milter/Limit.pm',
       AUTHOR        => 'Michael Schout <mschout@cpan.org>') : ()),
);

1;
