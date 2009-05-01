=head1 NAME

Milter::Limit::Log - logging functions for Milter::Limit

=head1 SYNOPSIS

 use Milter::Limit::Log;

 debug("whatever");
 info("something interesting happened");

=head1 DESCRIPTION

This module provides syslog wrapper functions.  Syslog is setup automatically
when you create a L<Milter::Limit> object.  Once that has been done, these
functions can be used for logging purposes.

=cut

package Milter::Limit::Log;

use strict;
use base 'Exporter';
use Sys::Syslog ();

our @EXPORT = qw(debug info);

=head1 FUNCTIONS

All functions are exported by default.

=over 4

=item debug(@msg)

log a message at level debug

=cut

sub debug {
    Sys::Syslog::syslog('warning', join '', @_);
}

=item info(@msg)

log a message at level info

=cut

sub info {
    Sys::Syslog::syslog('info', join '', @_);
}

=back

=head1 NOTE

warn() is also available, and will log a message at level warning becuase
C<$SIG{__WARN__}> is set by C<Milter::Limit>.

=head1 AUTHOR

Michael Schout <mschout@gkg.net>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 Michael Schout.  All rights reserved.

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. The full text of this license can be found in
the LICENSE file included with this module.

=cut

1;
