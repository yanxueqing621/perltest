package Test;
use Mojo::Base 'Mojolicious';
use Modern::Perl;
use Data::Dumper;

# This method will run once at server start
sub startup {
  my $self = shift;
  $self->secrets(['mojolicious']);
  
  
  my $r = $self->routes;
  # Documentation browser under "/perldoc"
  $self->plugin('REST2' => { prefix => 'api'});
  my $out = $r->rest_routes(name => 'Account')->rest_routes(name=>'topic')->rest_routes(name=>'reply');
  # Router

  # Normal route to controller
  my $route = $r->get('/aa')->to('example#welcome');

}

1;
