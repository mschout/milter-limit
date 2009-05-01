=head1 NAME

Milter::Limit::Plugin::BerkeleyDB - Berkeley DB backend for Milter::Limit

=head1 SYNOPSIS

 my $milter = Milter::Limit->instance('BerkeleyDB');

=head1 DESCRIPTION

This module implements the C<Milter::Limit> backend using a BerkeleyDB data
store.

=head1 CONFIGURATION

The C<[driver]> section of the configuration file must specify the following items:

=over 4

=item home

The directory where the database files should be stored.

=item file

The database filename

=item mode [optional]

The file mode for the database files (default 0644).

=back

=cut

package Milter::Limit::Plugin::BerkeleyDB;

use strict;
use base qw(Milter::Limit::Plugin Class::Accessor);
use BerkeleyDB qw(DB_CREATE DB_INIT_MPOOL DB_INIT_CDB);
use File::Path qw(mkpath);
use Fatal qw(mkpath);

__PACKAGE__->mk_accessors(qw(_db));

sub init {
    my $self = shift;

    my $conf = Milter::Limit::Config->section('driver');

    my $env = BerkeleyDB::Env->new(
        -Home     => $$conf{home},
        -Flags => DB_CREATE | DB_INIT_MPOOL | DB_INIT_CDB);

    my $db = BerkeleyDB::Hash->new(
        -Filename => $$conf{file},
        -Mode     => $$conf{mode} || 0644,
        -Env      => $env,
        -Flags    => DB_CREATE) or die "failed to open BerkeleyDB";

    $self->_db($db);
}

sub query {
    my ($self, $from) = @_;

    my $conf = Milter::Limit::Config->global;

    my $val;
    $self->_db->db_get($from, $val);

    unless (defined $val) {
        # initialize new record for sender
        $val = join ':', time, 0;
    }

    my ($start, $count) = split ':', $val;

    # reset counter if it is expired
    if ($start < time - $$conf{expire}) {
        $count = 0;
        $start = time;
    }

    # update database for this sender.
    $val = join ':', $start, ++$count;
    $self->_db->db_put($from, $val);

    return $count;
}

=head1 AUTHOR

Michael Schout <mschout@gkg.net>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 Michael Schout.  All rights reserved.

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. The full text of this license can be found in
the LICENSE file included with this module.

=cut

1;
