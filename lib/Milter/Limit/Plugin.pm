package Milter::Limit::Plugin;

use strict;
use base 'Class::Singleton';

sub query {
    die __PACKAGE__." does not implement query()\n";
}

1;

__END__
