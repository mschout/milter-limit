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

    my $env = BerkeleyDB::Env->new(
        -Flags => DB_CREATE | DB_INIT_MPOOL | DB_INIT_CDB);

    my $db = BerkeleyDB::Hash->new(
        -Filename => '/var/db/milter-limit/stats.db',
        -Mode     => 0644,
        -Env      => $env,
        -Flags    => DB_CREATE) or die "failed to open BerkeleyDB";

    $self->_db($db);
}

sub query {
    my ($self, $from) = @_;

    my $val;

    $self->_db->db_get($from, $val);

    unless (defined $val) {
        # initialize new record for sender
        $val = join ':', time, 0;
    }

    my ($start, $count) = split ':', $val;

    # reset counter if it is expired
    if ($start < time - 3600 * 24) {
        $count = 0;
        $start = time;
    }

    # update database for this sender.
    $val = join ':', $start, ++$count;
    $self->_db->db_put($from, $val);

    return $count;
}

1;
