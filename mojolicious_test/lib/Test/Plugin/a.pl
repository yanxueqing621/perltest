sub aa{
  my $options = { ref $_[0] ? %{ $_[0] } : @_ };
  use Data::Dumper;
  use Modern::Perl;
  say ref $options;
  say Dumper $options;
}

aa();
print "##############\n\n";
aa('a','b','c','d');
print "##############\n\n";
aa({1=>111,2=>222});
