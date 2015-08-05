package Test::Controller::Account;
use Mojo::Base 'Mojolicious::Controller';
use Modern::Perl;

sub list_account{
  my $self = shift;
  #say 'hello';
  #$self->render(text=>'list accound');
  #$self->app->log->debug('test begin');
  $self->render(json=>{list=>'list accound'});
}

sub create_account{
  my $self = shift;
  $self->render(json=>{create=>'create accound'});
}

sub delete_account{
  my $self = shift;
  $self->render(json=>{delete=>'create accound'});
}

sub read_account{
  my $self = shift;
  $self->render(json=>{read =>'create accound'});
}

sub update_account{
  my $self = shift;
  $self->render(json=>{update=>'create accound'});
}
1;
