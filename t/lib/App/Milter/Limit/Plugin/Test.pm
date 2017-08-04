# COPYRIGHT

package App::Milter::Limit::Plugin::Test;

use strict;
use warnings;
use base qw(App::Milter::Limit::Plugin);

sub init {
    # driver init
}

# the test driver merely returns whatever numbers are in the from address as
# the number of hits, or "1"
sub query {
    my ($self, $from) = @_;

    $from =~ s/[^0-9]//g;

    return $from || 1;
}

1;
