package Milter::Limit::Log;

use strict;
use base 'Exporter';
use Sys::Syslog ();

our @EXPORT = qw(debug info);

sub debug {
    Sys::Syslog::syslog('warning', join '', @_);
}

sub info {
    Sys::Syslog::syslog('info', join '', @_);
}

1;
