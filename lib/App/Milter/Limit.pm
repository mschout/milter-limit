=head1 NAME

App::Milter::Limit - Sendmail Milter that limits messages by sender

=head1 SYNOPSIS

 my $config = App::Milter::Limit::Config->instance('/etc/mail/milter-limit.conf');
 my $milter = App::Milter::Limit->instance('BerkeleyDB');
 $milter->register;
 $milter->main

=head1 DESCRIPTION

This milter limits the number of messages sent by SMTP envelope sender within a
specified time period.  The number of messages and length of time in which the
maximum number of messages can be sent is configurable in the configuration
file.  Once the limit is reached, messages will be rejected from that sender
until the time period has elapsed.

=cut

package App::Milter::Limit;

use strict;
use base qw(Class::Accessor Class::Singleton);

use Carp;
use App::Milter::Limit::Config;
use App::Milter::Limit::Log;
use App::Milter::Limit::Util;
use Sendmail::PMilter ':all';
use Sys::Syslog ();

our $VERSION = '0.10';

__PACKAGE__->mk_accessors(qw(driver milter));

=head1 CONSTRUCTOR

=over 4

=item instance($driver)

This gets the milter object, constructing it if necessary.  C<$driver> is the
name of the driver that you wish to use.  Currently only BerkelyDB is
available, but additional drivers can be created by writing a plugin module.
See C<App::Milter::Limit::Plugin::BerkeleyDB> for an example plugin.

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

    $self->_init_statedir;

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

# initialize the configured state dir.
# default: /var/run/milter-limit
sub _init_statedir {
    my $self = shift;

    my $conf = $self->config->global;

    App::Milter::Limit::Util::make_path($$conf{state_dir});
}

sub _init_driver {
    my ($self, $driver) = @_;

    my $driver_class = "App::Milter::Limit::Plugin::$driver";

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

# drop user/group privs.
sub _drop_privileges {
    my $self = shift;

    my $conf = $self->config->global;

    if (defined $$conf{group}) {
        ($(,$)) = ($$conf{group}, $$conf{group});
    }

    if (defined $$conf{user}) {
        ($<,$>) = ($$conf{user}, $$conf{user});
    }
}

=item main()

Main milter loop.

=cut

sub main {
    my $self = shift;

    $self->_drop_privileges;

    my $milter = $self->milter;

    my $conf = $self->config->global;

    my %dispatch_args = (
        max_children           => $$conf{max_children} || 5,
        max_requests_per_child => $$conf{max_requests_per_child} || 100
    );

    my $driver = $self->driver;

    # add child_init hook if necessary
    if ($driver->can('child_init')) {
        debug("child_init hook registered");
        $dispatch_args{child_init} = sub { $driver->child_init };
    }

    # add child_exit hook if necessary
    if ($driver->can('child_exit')) {
        debug("child_exit hook registered");
        $dispatch_args{child_exit} = sub { $driver->child_exit };
    }

    my $dispatcher = Sendmail::PMilter::prefork_dispatcher(%dispatch_args);

    $milter->set_dispatcher($dispatcher);

    info("starting");

    $milter->main;
}

sub _envfrom_callback {
    my ($ctx, $from) = @_;

    # strip angle brackets
    $from =~ s/(?:^\<)|(?:\>$)//g;

    # do not restrict NULL sender (bounces)
    unless (length $from) {
        return SMFIS_CONTINUE;
    }

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

=item App::Milter::Limit::Config config()

shortcut method to get the configuration object.

=cut

# shortcut to get the config.
sub config {
    App::Milter::Limit::Config->instance;
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
