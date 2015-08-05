sub aa{
  $op = shift;
  $b = $op->{prefix} || 'default';
  print "###$b ###\n";
}

aa();
aa({prefix=>'api'});
