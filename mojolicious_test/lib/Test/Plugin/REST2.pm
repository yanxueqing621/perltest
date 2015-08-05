package Test::Plugin::REST2;
use Modern::Perl;
use Mojo::Base 'Mojolicious::Plugin';
use Mojo::Exception;
use Lingua::EN::Inflect 1.895 qw/PL/;

# VERSION
# ABSTRACT: Mojolious::Plugin::REST2

=head1 SYNOPSIS

  use Mojolious::Plugin::REST2
  ..


=head1 DESCRIPTION

=cut

my $http2crud = {
    collection => {
        get  => 'list',
        post => 'create',
    },
    resource => {
        get    => 'read',
        put    => 'update',
        delete => 'delete'
    },
};

=head1 install_hook

=cut
 

has install_hook => 1;

sub register {
  my $self = shift;
  my $app = shift;
  my $options = { ref $_[0] ? %{ $_[0] } : @_};
  my $url_prefix = $options->{prefix} ? '/'.$options->{prefix} : '';

  # override default http2crud mapping from options...
  if ( exists( $options->{http2crud} ) ) {
      foreach my $method_type ( keys( %{$http2crud} ) ) {
          next unless exists $options->{http2crud}->{$method_type};
          foreach my $method ( keys( %{ $http2crud->{$method_type} } ) ) {
              next unless exists $options->{http2crud}->{$method_type}->{$method};
              $http2crud->{$method_type}->{$method} = $options->{http2crud}->{$method_type}->{$method};
          }
      }
  }

  # install app hook if not disabled...
  $self->install_hook(0) if ( defined( $options->{hook} ) and $options->{hook} == 0 );
  if ( $self->install_hook ) {
      $app->hook(
          before_render => sub {
              my $c = shift;
              my $path_substr = substr "" . $c->req->url->path, 0, length $url_prefix;
              if ( $path_substr eq $url_prefix ) {
                  my $json = $c->stash('json');
                  unless ( defined $json->{data} ) {
                      $json->{data} = {};
                      $c->stash( 'json' => $json );
                  }
              }
          }
      );
  }
  
  $app->routes->add_short_cut(   
    rest_routes => sub{
      my $routes = shift;
      my $params = { ref $_[0] ? %{ $_[0] } : @_ };
      Mojo::Exception->throw('Route name is required in rest_routes') unless defined $params->{name};
      $url_prefix = $routes->to_string || $url_prefix;

      # name setting
      my $route_name = $params->{name};
      my ( $route_name_lower, $route_name_plural, $route_id );
      $route_name_lower = lc $route_name;
      $route_name_plural = PL( $route_name_lower, 10);
      $route_id = ':'. $route_name_lower . "Id";

      # name prefix
      my $name_prefix = join "_", $url_prefix =~/:(.+?)Id/g;
    
      # collection routes
      for my $collection_method ( keys %{ $http2crud->{collection} } ){
        $params->{methods} 
          and index( $params->{methods}, substr( $http2crud->{collection}->{$collection_method}, 0, 1 ) ) == -1 
          and next;
        my $collection_crud = $http2crud->{collection}->{$collection_method};
        my $action = $name_prefix 
          ? $collection_crud . "_" . $name_prefix . "_" . $route_name_lower
          : $collection_crud . "_" . $route_name_lower;
        $routes->route("$url_prefix/$route_name_plural")
          ->via($collection_method)
          ->to("${route_name_lower}#$action")
          ->name($action);
      }
        
      # resoures routes
      for my $resource_method ( keys %{ $http2crud->{resource} } ){
        $params->{methods} 
          and index( $params->{methods}, substr( $http2crud->{resource}->{$resource_method}, 0, 1 ) ) == -1 
          and next;
        my $resource_crud = $http2crud->{resource}->{$resource_method};
        my $action = $name_prefix 
          ? $resource_crud . "_" . $name_prefix . "_" . $route_name_lower
          : $resource_crud . "_" . $route_name_lower;
        $routes->route("$url_prefix/$route_name_plural/$route_id")
          ->via($resource_crud)
          ->to("${route_name_lower}#$action")
          ->name($action);
      }
    }
  );
}


1;
