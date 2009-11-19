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

=item table [optional]

Table name that will store the statistics (default milter).

=back

=cut

package Milter::Limit::Plugin::SQLite;

use strict;
use base qw(Milter::Limit::Plugin Class::Accessor);
use DBI;
use DBIx::Connector;
use File::Path qw(make_path);
use File::Spec;
use Fatal qw(make_path);

__PACKAGE__->mk_accessors(qw(_conn table));

sub init {
    my $self = shift;

    my $conf = Milter::Limit::Config->section('driver');

    $self->init_home;

    # set table name
    $self->table($$conf{table} || 'milter');

    # setup the database
    $self->init_database;
}

sub init_home {
    my $self = shift;

    my $driver_conf = Milter::Limit::Config->section('driver');

    my $home = $$driver_conf{home};

    unless (-d $home) {
        make_path($home, { mode => 0755 });
    }

    # set ownership on home directory (SQLite needs to create files in here).
    my $global_conf = Milter::Limit::Config->global;

    my $uid = $$global_conf{user};
    my $gid = $$global_conf{group};

    chown $uid, $gid, $home or die "chown($home): $!";
}

sub db_file {
    my $self = shift;

    my $conf = Milter::Limit::Config->section('driver');

    return File::Spec->catfile($$conf{home}, $$conf{file});
}

sub _dbh {
    my $self = shift;

    return $self->_conn->dbh;
}

sub init_database {
    my $self = shift;

    # setup connection to the database.
    my $db_file = $self->db_file;

    my $conn = DBIx::Connector->new("dbi:SQLite:dbname=$db_file", '', '', {
        PrintError => 0,
        AutoCommit => 1 })
        or die "failed to initialize SQLite: $!";

    $self->_conn($conn);

    # prevent world read permissions.
    my $old_umask = umask 027;

    unless ($self->table_exists($self->table)) {
        $self->create_table($self->table);
    }

    umask $old_umask;

    my $global_conf = Milter::Limit::Config->global;

    my $uid = $$global_conf{user};
    my $gid = $$global_conf{group};

    chown $uid, $gid, $db_file or die "chown($db_file): $!";
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

    my $start = $$rec{first_seen} || time;
    my $count = $$rec{messages} || 0;

    # reset counter if it is expired
    if ($start < time - $$conf{expire}) {
        $self->_delete($from);
        return 0;
    }

    # update database for this sender.
    $self->_update($from);

    return $count + 1;
}

# return true if the given db table exists.
sub table_exists {
    my ($self, $table) = @_;

    $self->_dbh->do("select 1 from $table limit 0")
        or return 0;

    return 1;
}

# create the given table as the stats table.
sub create_table {
    my ($self, $table) = @_;

    my $dbh = $self->_dbh;

    $dbh->do(qq{
        create table $table (
            sender varchar (255),
            first_seen timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
            messages integer NOT NULL DEFAULT 0,
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

    my $query = qq{
        select
            sender,
            messages,
            strftime('%s',first_seen) as first_seen
        from
            $table
        where
            sender = ?
    };

    return $self->_dbh->selectrow_hashref($query, undef, $sender);
}

sub _update {
    my ($self, $sender) = @_;

    my $table = $self->table;

    my $query = qq{update $table set messages = messages + 1 where sender = ?};

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
