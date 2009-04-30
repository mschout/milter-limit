package Milter::Limit::Util;

use strict;
use POSIX qw(setsid);

sub daemonize {
    my $pid = fork and exit 0;

    my $sid = setsid();

    # detach from controlling TTY
    $SIG{HUP} = 'IGNORE';
    $pid = fork and exit 0;

    # clear umask
    umask 0;

    open STDIN,  '+>/dev/null';
    open STDOUT, '+>&STDIN';
    open STDERR, '+>&STDIN';

    return $sid;
}

1;
