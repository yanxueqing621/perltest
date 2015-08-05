package Mojolicious::Plugin::REST;
 
# ABSTRACT: Mojolicious Plugin for RESTful operations
our $VERSION = '0.006'; # VERSION
use Mojo::Base 'Mojolicious::Plugin';   #继承plugin插件
use Mojo::Exception;
use Lingua::EN::Inflect 1.895 qw/PL/;   #将英文单词的单数变复数
 
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
};    #将http操作转化为crud
 
has install_hook => 1;   #该类的属性 install_hook
 
sub register {
    my $self    = shift; #该类本身，有自己的属性和方法
    my $app     = shift; # mojolious  app类
    my $options = { @_ ? ( ref $_[0] ? %{ $_[0] } : @_ ) : () }; #传进来的参数
 
    # prefix, version, stuff...
    #增加前缀如prefix和version 例如：$self->plugin( 'REST' => { prefix => 'api', version => 'v1' } );
    my $url_prefix = '';
    foreach my $modifier (qw(prefix version)) {
          $options->{$modifier} and $url_prefix .= "/" . $options->{$modifier};
    }
 
    # method name for bridged actions...
    my $method_chained = $options->{method_chained} // 'chained';
    
    #通过参数替换默认的http2crud 
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
 
    $app->routes->add_shortcut(
        rest_routes => sub {
 
            my $routes = shift;
 
            my $params = { @_ ? ( ref $_[0] ? %{ $_[0] } : @_ ) : () };
 
            Mojo::Exception->throw('Route name is required in rest_routes') unless defined $params->{name};
 
            # name setting
            my $route_name = $params->{name};
            my ( $route_name_lower, $route_name_plural, $route_id );
            $route_name_lower  = lc $route_name;
            $route_name_plural = PL( $route_name_lower, 10 );
            $route_id          = ":" . $route_name_lower . "Id";
 
            # under setting
            my $under_name = $params->{under};
            my ( $under_name_lower, $under_name_plural, $under_id );
            if ( defined($under_name) and $under_name ne '' ) {
                $under_name_lower  = lc $under_name;
                $under_name_plural = PL( $under_name_lower, 10 );
                $under_id          = ":" . $under_name_lower . "Id";
            }
 
            # controller
            my $controller = $params->{controller} // ucfirst($route_name_lower);
 
            foreach my $collection_method ( sort keys( %{ $http2crud->{collection} } ) ) {
                next
                    if ( defined $params->{methods}
                    && index( $params->{methods}, substr( $http2crud->{collection}->{$collection_method}, 0, 1 ) )
                    == -1 );
 
                my $url           = "/$route_name_plural";
                my $action_suffix = "_" . $route_name_lower;
                if ( defined($under_name) ) {
                    $url           = "/$under_name_plural/$under_id" . $url;
                    $action_suffix = "_" . $under_name_lower . $action_suffix;
                }
 
                $url = $url_prefix . $url;
                my $action = $http2crud->{collection}->{$collection_method} . $action_suffix;
 
                if ( defined($under_name) ) {
                    my $bridge_controller = ucfirst($under_name_lower);
                    my $bridge
                        = $routes->bridge($url)->to( controller => $bridge_controller, action => $method_chained )
                        ->name("${bridge_controller}::${method_chained}()")
                        ->route->via($collection_method)->to( controller => $controller, action => $action )
                        ->name("${controller}::${action}()");
                }
                else {
                    $routes->route($url)->via($collection_method)->to( controller => $controller, action => $action )
                        ->name("${controller}::${action}()");
 
                }
 
            }
            foreach my $resource_method ( sort keys( %{ $http2crud->{resource} } ) ) {
                next
                    if ( defined $params->{methods}
                    && index( $params->{methods}, substr( $http2crud->{resource}->{$resource_method}, 0, 1 ) ) == -1 );
 
                my $ids = [];
 
                if ( defined( $params->{types} ) ) {
                    $ids = $params->{types};
                }
                else {
                    push @$ids, $route_id;
                }
 
                foreach my $id (@$ids) {
                    if ( defined( $params->{types} ) ) {
                        $controller = $params->{controller} // ucfirst($route_name_lower);
                        $controller .= '::' . ucfirst($id);
                    }
 
                    my $url           = "/$route_name_plural/$id";
                    my $action_suffix = "_" . $route_name_lower;
                    if ( defined($under_name) ) {
                        $url           = "/$under_name_plural/$under_id" . $url;
                        $action_suffix = "_" . $under_name_lower . $action_suffix;
                    }
                    $url = $url_prefix . $url;
                    my $action = $http2crud->{resource}->{$resource_method} . $action_suffix;
 
                    if ( defined($under_name) ) {
                        my $bridge_controller = ucfirst($under_name_lower);
                        my $bridge
                            = $routes->bridge($url)->to( controller => $bridge_controller, action => $method_chained )
                            ->name("${bridge_controller}::${method_chained}()")
                            ->route->via($resource_method)->to( controller => $controller, action => $action )
                            ->name("${controller}::${action}()");
 
                    }
                    else {
                        $routes->route($url)->via($resource_method)->to( controller => $controller, action => $action )
                            ->name("${controller}::${action}()");
                    }
 
                }
 
            }
 
        }
    );
 
}
 
1;
 
__END__
