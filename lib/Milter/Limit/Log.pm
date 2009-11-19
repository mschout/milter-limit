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
