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
use Milter::Limit::Util;

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

    Milter::Limit::Util::make_path($$conf{state_dir});

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
