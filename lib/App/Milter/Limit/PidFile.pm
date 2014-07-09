package App::Milter::Limit::PidFile;

# ABSTRACT: Milter Limit Pid file class

use strict;
use Proc::PID::File;
use App::Milter::Limit::Config;
use App::Milter::Limit::Log;
use App::Milter::Limit::Util;

my $Pid;

=method running

If the program is running already, returns true.  Otherwise, returns false,
and writes the pid file, and changes its permissions to the user/group
specified in the milter limit configuration file.  When the program exits, the
pid file will be removed automatically.

=cut

sub running {
    my $class = shift;

    my $conf = App::Milter::Limit::Config->global;

    App::Milter::Limit::Util::make_path($$conf{state_dir});

    $Pid = Proc::PID::File->new;

    $Pid->file(dir => $$conf{state_dir});

    if ($Pid->alive) {
        $Pid = undef;
        return 1;
    }

    $Pid->touch;

    # chown the file so we can unlink it
    chown $$conf{user}, $$conf{group}, $Pid->{path};

    return 0;
}

1;

__END__

=head1 SYNOPSIS

 die "already running" if App::Milter::Limit::PidFile->running;

=head1 DESCRIPTION

This class manages the milter limit PID file.
