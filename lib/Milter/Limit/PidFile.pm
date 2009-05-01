=head1 NAME

Milter::Limit::PidFile - Pid file class

=head1 SYNOPSIS

 die "already running" if Milter::Limit::PidFile->running;

=head1 DESCRIPTION

This class manages the milter limit PID file.

=cut

package Milter::Limit::PidFile;

use strict;
use File::Pid;
use Milter::Limit::Config;
use Milter::Limit::Log;

my $Pid;

=head1 METHODS

=over 4

=item running()

If the program is running already, returns true.  Otherwise, returns false,
and writes the pid file, and changes its permissions to the user/group
specified in the milter limit configuration file.  When the program exits, the
pid file will be removed automatically.

=cut

sub running {
    my $class = shift;

    my $conf = Milter::Limit::Config->global;

    my $me = File::Pid->program_name;

    my $pid_file = "$$conf{state_dir}/$me.pid";

    $Pid = File::Pid->new({file => $pid_file});

    if ($Pid->running) {
        $Pid = undef;
        return 1;
    }

    $Pid->write;

    # chown the file so we can unlink it
    chown $$conf{user}, $$conf{group}, $Pid->file;

    return 0;
}

# unlink the pid file when we exit.
END {
    if (defined $Pid) {
        debug("removing pid file: ", $Pid->file);
        $Pid->remove;
    }
}

=back

=head1 AUTHOR

Michael Schout <mschout@gkg.net>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 Michael Schout.  All rights reserved.

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. The full text of this license can be found in
the LICENSE file included with this module.

=cut

1;
