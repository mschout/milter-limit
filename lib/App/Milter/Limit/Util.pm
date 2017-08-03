package App::Milter::Limit::Util;

# ABSTRACT: utility functions for App::Milter::Limit

=head1 DESCRIPTION

This module provides utility functions for App::Milter::Limit.

=cut

use strict;
use warnings;

use POSIX qw(setsid);
use File::Path 2.0 ();
use App::Milter::Limit::Config;

=func daemonize

This daemonizes the program.  When you call this, the program will fork(),
detach from the controlling TTY, close STDIN, STDOUT, and STDERR, and change to
the root directory.

=cut

sub daemonize {
    my $pid = fork and exit 0;

    my $sid = setsid();

    # detach from controlling TTY
    $SIG{HUP} = 'IGNORE';
    $pid = fork and exit 0;

    # reset umask
    umask 027;

    chdir '/' or die "can't chdir: $!";

    open STDIN,  '+>/dev/null';
    open STDOUT, '+>&STDIN';
    open STDERR, '+>&STDIN';

    return $sid;
}

=func get_uid ($username)

return the UID for the given C<$username>

=cut

sub get_uid {
    my $user = shift;

    unless ($user =~ /^\d+$/) {
        my $uid = getpwnam($user);
        unless (defined $uid) {
            die qq{no such user "$user"\n};
        }

        return $uid;
    }
    else {
        return $user;
    }
}

=func get_gid ($groupname)

return the GID for the given C<$groupname>

=cut

sub get_gid {
    my $group = shift;

    unless ($group =~ /^\d+$/) {
        my $gid = getgrnam($group);
        unless (defined $gid) {
            die qq{no such group "$group"\n};
        }

        return $gid;
    }
    else {
        return $group;
    }
}

=func make_path ($path)

create the given directory path if necessary, creating intermediate directories
as necessary.  The final directory will be C<chown()>'ed as the user/group from
the config file.

=cut

sub make_path {
    my $path = shift;

    unless (-d $path) {
        File::Path::make_path($path, { mode => 0755 });
    }

    my $conf = App::Milter::Limit::Config->global;

    if (defined @$conf{qw(user group)}) {
        chown $$conf{user}, $$conf{group}, $path
            or die "chown($path): $!";
    }
}

1;

__END__
