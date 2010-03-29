use 5.008;
use ExtUtils::MakeMaker;

my %conf = (
    NAME         => 'App::Milter::Limit',
    VERSION_FROM => 'lib/App/Milter/Limit.pm',
    EXE_FILES    => ['bin/milter-limit'],
    PREREQ_PM    => {
        'Class::Accessor'   => 0,
        'Class::Singleton'  => 0,
        'Config::Tiny'      => 0,
        'DBD::SQLite'       => 0,      # not sure what min version we need
        'File::Path'        => 2.00,
        'File::Pid'         => 0,
        'Pod::Usage'        => 0,
        'Sendmail::PMilter' => 0.98,
        'Sys::Syslog'       => 0
    }
);

if (MM->can('signature_target')) {
    $conf{SIGN} = 1;
}

if ($] >= 5.005) {
  $conf{ABSTRACT_FROM} = 'lib/App/Milter/Limit.pm';
  $conf{AUTHOR}        = 'Michael Schout <mschout@cpan.org>';
}

if ($ExtUtils::MakeMaker::VERSION >= 6.48) {
    $conf{META_MERGE} = {
        resources => {
            repository => 'http://github.com/mschout/milter-limit'
        }
    };
}

WriteMakefile(%conf);

1;
