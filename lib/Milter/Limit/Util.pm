=head1 NAME

Milter::Limit::Util - utility functions for Milter::Limit

=head1 SYNOPSIS

 use Milter::Limit::Util;

 Milter::Limit::Util::daemonize();

=head1 DESCRIPTION

This module provides utility functions for Milter::Limit.

=cut

package Milter::Limit::Util;

use strict;
use POSIX qw(setsid);
use File::Path ();
use Milter::Limit::Config;

=head1 FUNCTIONS

=over 4

=item daemonize()

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

=item get_uid($username): int

lookup the UID for a username

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

=item get_gid($groupname): int

lookup the GID for a group name

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

=item make_path($path): void

create the given directory path if necessary, creating intermediate directories
as necessary.  The final directory will be C<chown()>'ed as the user/group from
the config file.

=cut

sub make_path {
    my $path = shift;

    unless (-d $path) {
        File::Path::make_path($path, { mode => 0755 });
    }

    my $conf = Milter::Limit::Config->global;

    chown $$conf{user}, $$conf{group}, $path
        or die "chown($path): $!";
}

=back

=head1 SOURCE

You can contribute or fork this project via github:

http://github.com/mschout/milter-limit

 git clone git://github.com/mschout/milter-limit.git

=head1 AUTHOR

Michael Schout E<lt>mschout@cpan.orgE<gt>

=head1 COPYRIGHT & LICENSE

Copyright 2009 Michael Schout.

This program is free software; you can redistribute it and/or modify it under
the terms of either:

=over 4

=item *

the GNU General Public License as published by the Free Software Foundation;
either version 1, or (at your option) any later version, or

=item *

the Artistic License version 2.0.

=back

=cut

1;
