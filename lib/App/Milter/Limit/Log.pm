package App::Milter::Limit::Log;

# ABSTRACT: logging functions for App::Milter::Limit

use strict;
use base 'Exporter';
use Sys::Syslog ();

our @EXPORT = qw(debug info);

=func debug @msg

log a message at level debug

=cut

sub debug {
    Sys::Syslog::syslog('warning', join '', @_);
}


=func info @msg

log a message at level info

=cut

sub info {
    Sys::Syslog::syslog('info', join '', @_);
}

1;

__END__

=head1 SYNOPSIS

 use App::Milter::Limit::Log;

 debug("whatever");
 info("something interesting happened");

=head1 DESCRIPTION

This module provides syslog wrapper functions.  Syslog is setup automatically
when you create a L<App::Milter::Limit> object.  Once that has been done, these
functions can be used for logging purposes.

=func warn @msg

log a message a level warn.  C<App::Milter::Limit> provides this via C<$SIG{__WARN__}>.
