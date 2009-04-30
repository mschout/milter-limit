package Milter::Limit;

use strict;
use base qw(Class::Accessor Class::Singleton);
use Sendmail::PMilter ':all';
use Carp;

__PACKAGE__->mk_accessors(qw(driver milter));

sub _new_instance {
    my ($class, $driver) = @_;
    warn "_new_instance($driver)\n";

    croak "usage: new(driver)" unless defined $driver;

    my $driver_class = "Milter::Limit::Plugin::$driver";

    eval "require $driver_class";

    my $driver_instance = $driver_class->instance();

    my $self = $class->SUPER::_new_instance();

    $self->driver($driver_instance);
    $self->milter(new Sendmail::PMilter);

    warn "$self driver: ", $self->driver, "\n";
    warn "$self milter: ", $self->milter, "\n";

    return $self;
}

sub register {
    my $self = shift;

    my $milter = $self->milter;

    $milter->auto_setconn('milter-limit') or croak "auto_setconn failed";

    my %callbacks = (
        envfrom => \&_envfrom_callback
    );

    $milter->register('milter-limit', \%callbacks, SMFI_CURR_ACTS);
}

sub main {
    my $self = shift;

    my $milter = $self->milter;

    my $dispatcher = Sendmail::PMilter::prefork_dispatcher(
        max_children           => 5,
        max_requests_per_child => 100);

    $milter->set_dispatcher($dispatcher);
    $milter->main;
}

sub _envfrom_callback {
    my ($ctx, $from) = @_;

    my $self = __PACKAGE__->instance();

    my $count = $self->driver->query($from);
    warn "$from: $count\n";

    if ($count > 100) {
        $ctx->setreply(550, '5.7.1', 'Message limit exceeded');
        return SMFIS_REJECT;
    }
    else {
        return SMFIS_CONTINUE;
    }
}

1;
