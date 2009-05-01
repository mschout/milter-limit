=head1 NAME

Milter::Limit - Sendmail Milter that limits messages by sender

=head1 SYNOPSIS

 my $config = Milter::Limit::Config->instance('/etc/mail/milter-limit.conf');
 my $milter = Milter::Limit->instance('BerkeleyDB');
 $milter->register;
 $milter->main

=head1 DESCRIPTION

This milter limits the number of messages sent by SMTP envelope sender within a
specified time period.  The number of messages and length of time in which the
maximum number of messages can be sent is configurable in the configuration
file.  Once the limit is reached, messages will be rejected from that sender
until the time period has elapsed.

=cut

package Milter::Limit;

use strict;
use base qw(Class::Accessor Class::Singleton);
use Milter::Limit::Config;
use Milter::Limit::Log;
use Sendmail::PMilter ':all';
use Sys::Syslog ();
use Carp;

our $VERSION = '0.10';

__PACKAGE__->mk_accessors(qw(driver milter));

=head1 CONSTRUCTOR

=over 4

=item instance($driver)

This gets the milter object, constructing it if necessary.  C<$driver> is the
name of the driver that you wish to use.  Currently only BerkelyDB is
available, but additional drivers can be created by writing a plugin module.
See C<Milter::Limit::Plugin::BerkeleyDB> for an example plugin.

=back

=cut

sub _new_instance {
    my ($class, $driver) = @_;

    croak "usage: new(driver)" unless defined $driver;

    my $self = $class->SUPER::_new_instance();

    $self->init($driver);

    return $self;
}

sub init {
    my ($self, $driver) = @_;

    $self->_init_log;

    $self->milter(new Sendmail::PMilter);

    $self->_init_driver($driver);
}

# initialize logging
sub _init_log {
    my $self = shift;

    my $conf = $self->config->section('log');
    $$conf{identity} ||= 'milter-limit';
    $$conf{facility} ||= 'mail';

    Sys::Syslog::openlog($$conf{identity}, $$conf{options}, $$conf{facility});
    info("syslog initialized");

    $SIG{__WARN__} = sub {
        Sys::Syslog::syslog('warning', "warning: ".join('', @_));
    };

    $SIG{__DIE__}  = sub {
        Sys::Syslog::syslog('crit', "fatal: ".join('',@_));
        die @_;
    };
}

sub _init_driver {
    my ($self, $driver) = @_;

    my $driver_class = "Milter::Limit::Plugin::$driver";

    eval "require $driver_class";
    if ($@) {
        die "failed to load $driver_class: $@\n";
    }
    debug("loaded driver $driver");

    $self->driver($driver_class->instance);
}

=head1 METHODS

The following methods are available

=over 4

=item register()

Registers the milter with sendmail and sets up the milter handlers.
See L<Milter::PMilter::register()>.

=cut

sub register {
    my $self = shift;

    my $milter = $self->milter;

    my $conf = $self->config->global;

    $milter->auto_setconn($$conf{name})
        or croak "auto_setconn failed";

    my %callbacks = (
        envfrom => \&_envfrom_callback
    );

    $milter->register($$conf{name}, \%callbacks, SMFI_CURR_ACTS);

    debug("registered as $$conf{name}");
}

=item main()

Main milter loop.

=cut

sub main {
    my $self = shift;

    my $milter = $self->milter;

    my $conf = $self->config->global;

    my $dispatcher = Sendmail::PMilter::prefork_dispatcher(
        max_children           => $$conf{max_children} || 5,
        max_requests_per_child => $$conf{max_requests_per_child} || 100);

    $milter->set_dispatcher($dispatcher);

    info("starting");

    $milter->main;
}

sub _envfrom_callback {
    my ($ctx, $from) = @_;

    $from =~ s/(?:^\<)|(?:\>$)//g;

    my $self = __PACKAGE__->instance();

    my $conf = $self->config->global;

    my $count = $self->driver->query($from);
    debug("$from [$count/$$conf{limit}]");

    if ($count > $$conf{limit}) {
        info("$from exceeded message limit");
        $ctx->setreply(550, '5.7.1', 'Message limit exceeded');
        return SMFIS_REJECT;
    }
    else {
        return SMFIS_CONTINUE;
    }
}

=item Milter::Limit::Config config()

shortcut method to get the configuration object.

=cut

# shortcut to get the config.
sub config {
    Milter::Limit::Config->instance;
}

=back

=head1 SOURCE

You can contribute to or fork this project via github:

http://github.com/mschout/milter-limit.git

=head1 BUGS / FEEDBACK

Please report any bugs or feature requests to
bug-milter-limit@rt.cpan.org, or through the web interface at
http://rt.cpan.org

I welcome feedback, patches and comments.

=head1 AUTHOR

Michael Schout <mschout@gkg.net>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 Michael Schout.  All rights reserved.

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. The full text of this license can be found in
the LICENSE file included with this module.

=cut

1;
