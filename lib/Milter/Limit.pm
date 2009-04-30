package Milter::Limit;

use strict;
use base qw(Class::Accessor Class::Singleton);
use Milter::Limit::Config;
use Milter::Limit::Log;
use Sendmail::PMilter ':all';
use Sys::Syslog ();
use Carp;

__PACKAGE__->mk_accessors(qw(driver milter));

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
    debug("$count messages from $from");

    if ($count > $$conf{limit}) {
        info("$from exceeded message limit");
        $ctx->setreply(550, '5.7.1', 'Message limit exceeded');
        return SMFIS_REJECT;
    }
    else {
        return SMFIS_CONTINUE;
    }
}

# shortcut to get the config.
sub config {
    Milter::Limit::Config->instance;
}

1;
