package Milter::Limit::Plugin::BerkeleyDB;

use strict;
use base qw(Milter::Limit::Plugin Class::Accessor);
use BerkeleyDB qw(DB_CREATE DB_INIT_MPOOL DB_INIT_CDB);
use File::Path qw(mkpath);
use Fatal qw(mkpath);

__PACKAGE__->mk_accessors(qw(_db));

sub _new_instance {
    my $class = shift;

    my $self = $class->SUPER::_new_instance();

    $self->_init;

    return $self;
}

sub _init {
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

1;
