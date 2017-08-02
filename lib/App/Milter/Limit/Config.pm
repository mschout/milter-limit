package App::Milter::Limit::Config;

# ABSTRACT: Milter Limit configuration object

use strict;
use warnings;

use base qw(Class::Singleton Class::Accessor);
use Config::Tiny;

__PACKAGE__->mk_accessors(qw(config));

=begin Pod::Coverage

init

=end Pod::Coverage

=method instance $config_file

reads the ini style configuration from C<$config_file> and returns the
C<Config::Tiny> object

=cut

sub _new_instance {
    my ($class, $config_file) = @_;

    my $config = Config::Tiny->read($config_file)
        or die "failed to read config file: ", Config::Tiny->errstr;

    # set defaults
    $config->{_}{name} ||= 'milter-limit';
    $config->{_}{state_dir} ||= '/var/run/milter-limit';

    my $self = $class->SUPER::_new_instance({config => $config});

    $self->init;

    return $self;
}

sub init {
    my $self = shift;

    no warnings 'uninitialized';

    my $conf = $self->global;
    if (my $user = $$conf{user}) {
        $$conf{user} = App::Milter::Limit::Util::get_uid($user);
    }

    if (my $group = $$conf{group}) {
        $$conf{group} = App::Milter::Limit::Util::get_gid($group);
    }
}

=method instance

get the configuration I<Config::Tiny> object.

=method global

get global configuration section (hashref)

=cut

sub global {
    my $self = shift;
    $self->instance->config->{_};
}

=method section

get the configuration for the given section name

=cut

sub section {
    my ($self, $name) = @_;
    $self->instance->config->{$name};
}

=method set_defaults $section, %defaults

set default values for a config section.  This will fill in the values from
C<%defaults> in the given C<$section> name if the keys are not already set.
Most likely you would call this as part of your plugin's C<init()> method to
set plugin specific defaults.

=cut

sub set_defaults {
    my ($self, $section, %defaults) = @_;

    $section = '_' if $section eq 'global';

    my $conf = $self->instance->config->{$section}
        or die "config section [$section] does not exist in the config file\n";

    for my $key (keys %defaults) {
        unless (defined $$conf{$key}) {
            $$conf{$key} = $defaults{$key};
        }
    }
}

1;

__END__

=head1 SYNOPSIS

 # pass config file name first time.
 my $conf = App::Milter::Limit::Config->instance('/etc/mail/milter-limit.conf');

 # after that, just call instance()
 $conf = App::Milter::Limit::Config->instance();

 # global config section
 my $global = $conf->global;
 my $limit = $global->{limit};

 # log section
 my $log_conf = $conf->section('log');
 my $ident = $log_conf->{identity};

 # driver section
 my $driver = $conf->section('driver');
 my $home = $driver->{home};

=head1 DESCRIPTION

C<App::Milter::Limit::Config> is holds the configuration data for milter-limit.  The
configuration data is read from an ini-style config file as a C<Config::Tiny>
object.

=cut

=head1 SEE ALSO

L<Config::Tiny>
