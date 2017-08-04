# COPYRIGHT

package App::Milter::Limit::Plugin;

# ABSTRACT: Milter Limit driver plugin base class

use strict;
use warnings;
use base 'Class::Singleton';

use App::Milter::Limit::Config;

sub _new_instance {
    my $class = shift;

    my $self = $class->SUPER::_new_instance(@_);

    $self->init(@_);

    return $self;
}

=method config_get ($section, $name)

Get a configuration value from the given section with the given name.  If
C<$section> is C<global> then the global config section is used.

=cut

sub config_get {
    my ($self, $section, $name) = @_;

    my $conf = $section eq 'global'
             ? App::Milter::Limit::Config->global
             : App::Milter::Limit::Config->section($section);

    return $$conf{$name};
}

=method config_defaults ($section, %defaults)

set default values for the given configuration section.

See: L<App::Milter::Limit::Config/set_defaults>

=cut

sub config_defaults {
    my ($self, $section, %defaults) = @_;

    App::Milter::Limit::Config->set_defaults($section, %defaults);
}

=method init

initialize the driver.  Called when the driver class is first constructed.

=cut

sub init {
    my $self = shift;
    die ref($self)." does not implement init()\n";
}

=method query ($sender)

lookup a sender, and update the counters for it.  This is called when a message
is seen for a sender.  Returns the number of messages seen for the sender in
the configured expire time period.

=cut

sub query {
    my $self = shift;
    die ref($self)." does not implement query()\n";
}

1;

__END__

=head1 SYNOPSIS

 # in your driver module:
 package App::Milter::Limit::Plugin::FooBar;

 use base 'App::Milter::Limit::Plugin';

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

This module is the base class for C<App::Milter::Limit> backend plugins.

=head2 Required Methods

All plugins must implement at least the following methods:

=over 4

=item * init

=item * query

=back
