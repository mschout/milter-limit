=head1 NAME

App::Milter::Limit::Config - Milter Limit configuration object

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

package App::Milter::Limit::Config;

use strict;
use base qw(Class::Singleton Class::Accessor);
use Config::Tiny;

__PACKAGE__->mk_accessors(qw(config));

=head1 CONSTRUCTOR

=over 4

=item instance($config_file): Config::Tiny

read the ini style configuration from C<$config_file> and returns the C<Config::Tiny> object

=back

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

    my $conf = $self->global;
    if (my $user = $$conf{user}) {
        $$conf{user} = App::Milter::Limit::Util::get_uid($user);
    }

    if (my $group = $$conf{group}) {
        $$conf{group} = App::Milter::Limit::Util::get_gid($group);
    }
}

=head1 METHODS

The following methods are available:

=over 4

=item instance(): Config::Tiny

get the configuration object.

=item global(): hashref

get the global configuration section

=cut

sub global {
    my $self = shift;
    $self->instance->config->{_};
}

=item section($name): hashref

get the configuration for the given section name

=cut

sub section {
    my ($self, $name) = @_;
    $self->instance->config->{$name};
}

=item set_defaults($section, %defaults): void

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

=head1 SEE ALSO

L<Config::Tiny>

=cut

1;
