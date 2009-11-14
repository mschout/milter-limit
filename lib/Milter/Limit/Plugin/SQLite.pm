=head1 NAME

Milter::Limit::Plugin::SQLite - SQLite backend for Milter::Limit

=head1 SYNOPSIS

 my $milter = Milter::Limit->instance('SQLite');

=head1 DESCRIPTION

This module implements the C<Milter::Limit> backend using a SQLite data
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

package Milter::Limit::Plugin::SQLite;

use strict;
use base qw(Milter::Limit::Plugin Class::Accessor);
use DBI;
use File::Path qw(mkpath);
use File::Spec;
use Fatal qw(mkpath);

__PACKAGE__->mk_accessors(qw(_dbh table));

sub init {
    my $self = shift;

    my $conf = Milter::Limit::Config->section('driver');

    unless (-d $$conf{home}) {
        mkpath $$conf{home};
    }

    my $db_file = File::Spec->catfile($$conf{home}, $$conf{file});

    $self->table($$conf{table});

    my $dbh = DBI->connect("dbi:SQLite:dbname=$db_file", '', '', {
        PrintError      => 0,
        AutoCommit      => 1,
        InactiveDestroy => 1 })
        or die "failed to initialize SQLite: $!";

    $self->_dbh($dbh);

    $self->database_setup;
}

sub database_setup {
    my $self = shift;

    unless ($self->table_exists($self->table)) {
        $self->create_table($self->table);
    }
}

sub query {
    my ($self, $from) = @_;

    $from = lc $from;

    my $conf = Milter::Limit::Config->global;

    my $rec = $self->_retrieve($from);

    unless (defined $rec) {
        # initialize new record for sender
        $rec = $self->_create($from)
            or return 0;    # I give up
    }

    my $start = $$rec{first_seen};
    my $count = $$rec{messages};

    # reset counter if it is expired
    if ($start < time - $$conf{expire}) {
        $self->_delete($from);
        return 0;
    }

    # update database for this sender.
    $self->_update($from);

    return $count + 1;
}

sub table_exists {
    my ($self, $table) = @_;

    $self->_dbh->do("select 1 from $table limit 0")
        or return 0;

    return 1;
}

sub create_table {
    my ($self, $table) = @_;

    my $dbh = $self->dbh;

    $dbh->do(qq{
        create table $table (
            sender varchar (255),
            first_seen timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
            messages integer,
            PRIMARY KEY (sender)
        )
    }) or die "failed to create table $table: $DBI::errstr";

    $dbh->do(qq{
        create index ${table}_first_seen_key on $table (first_seen)
    }) or die "failed to create first_seen index: $DBI::errstr";
}

## CRUD methods
sub _create {
    my ($self, $sender) = @_;

    my $table = $self->table;

    $self->_dbh->do(qq{insert or replace into $table (sender) values (?)},
        undef, $sender)
        or warn "failed to create sender record: $DBI::errstr";

    return $self->_retrieve($sender);
}

sub _retrieve {
    my ($self, $sender) = @_;

    my $table = $self->table;

    my $query = q{select * from $table where sender = ?};

    return $self->_dbh->selectrow_hashref($query, undef, $sender);
}

sub _update {
    my ($self, $sender) = @_;

    my $table = $self->table;

    my $query = q{update $table set messages = messages + 1 where sender = ?};

    return $self->_dbh->do($query, undef, $sender);
}

sub _delete {
    my ($self, $sender) = @_;

    my $table = $self->table;

    $self->_dbh->do(qq{delete from $table where sender = ?}, undef, $sender)
        or warn "failed to delete $sender: $DBI::errstr";
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
