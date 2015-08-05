use Data::Dumper;
use Modern::Perl;

my $a=':aaid:bbid:ccid';


#my @arr = $a=~/:(.+?)id/g;
say join "_", $a=~/:(.+?)ide/g;
#say join "_", @arr
#say Dumper \@arr;
