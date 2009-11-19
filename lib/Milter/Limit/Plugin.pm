=head1 NAME

Milter::Limit::Plugin - Milter::Limit driver plugin base class

=head1 SYNOPSIS

 # in your driver module:
 package Milter::Limit::Plugin::FooBar;

 use base 'Milter::Limit::Plugin';

 sub init {
     my $self = shift;

     # initialize your driver
 }

 sub query {
     my ($self, $sender) = @_;

     # hand waving

     return $message_count;
 }

=head1 DESCRIPTION

This module is the base class for C<Milter::Limit> backend plugins.

=cut

package Milter::Limit::Plugin;

use strict;
use base 'Class::Singleton';
use Milter::Limit::Config;

sub _new_instance {
    my $class = shift;

    my $self = $class->SUPER::_new_instance(@_);

    $self->init(@_);

    return $self;
}

=head1 METHODS

The following methods are available to plugin subclasses:

=over 4

=item config_get($section, $name)

Get a configuration value from the given section with the given name.  If
C<$section> is C<global> then the global config section is used.

=cut

sub config_get {
    my ($self, $section, $name) = @_;

    my $conf = $section eq 'global'
             ? Milter::Limit::Config->global
             : Milter::Limit::Config->section($section);

    return $$conf{$name};
}

=item config_defaults($section, %defaults)

set default values for the given configuration section.

See: L<Milter::Limit::Config/set_defaults>

=cut

sub config_defaults {
    my ($self, $section, %defaults) = @_;

    Milter::Limit::Config->set_defaults($section, %defaults);
}

=back

All plugin subclasses must implement the following methods:

=over 4

=item init()

initialize the driver.  Called when the driver class is first constructed.

=cut

sub init {
    my $self = shift;
    die ref($self)." does not implement init()\n";
}

=item query($sender): int

lookup a sender, and update the counters for it.  This is called when a message
is seen for a sender.  Return value is the number of messages seen for the
sender in the configured expire time period.

=cut

sub query {
    my $self = shift;
    die ref($self)." does not implement query()\n";
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

L<Milter::Limit::Plugin::SQLite>

=cut

1;

__END__
