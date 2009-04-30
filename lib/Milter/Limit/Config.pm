package Milter::Limit::Config;

use strict;
use base qw(Class::Singleton Class::Accessor);
use Config::Tiny;

__PACKAGE__->mk_accessors(qw(config));

sub _new_instance {
    my ($class, $config_file) = @_;

    my $config = Config::Tiny->read($config_file)
        or die "failed to read config file: ", Config::Tiny->errstr;

    # set defaults
    $config->{_}{name} ||= 'milter-limit';

    return $class->SUPER::_new_instance({config => $config});
}

sub global {
    my $self = shift;
    $self->instance->config->{_};
}

sub section {
    my ($self, $name) = @_;
    $self->instance->config->{$name};
}

1;
