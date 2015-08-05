# create your custom model class
package MyModel;
use Mojo::Base "Mandel";
1;
 
# create a document class
package MyModel::Cat;
use Mandel::Document;
use Types::Standard 'Str';
field name => ( isa => Str, builder => sub { "value" } );
field 'type';
belongs_to dog=> 'MyModel::Dog';
belongs_to person=> 'MyModel::Person';
1;
 
# create a document class
package MyModel::Dog;
use Mandel::Document;
use Types::Standard 'Str';
field name => ( isa => Str, builder => sub { "dog" } );
field 'type';
belongs_to person => 'MyModel::Person';
has_many cats => 'MyModel::Cat';
1;
 
# create another document class
package MyModel::Person;
use Mandel::Document;
use Types::Standard 'Int';
field [qw( name )];
field age => ( isa => Int );
has_many cats => 'MyModel::Cat';
has_many dogs => 'MyModel::Dog';
1;

# use the model in your application
package main;
use Data::Dumper;
use Modern::Perl;
my $connection = MyModel->connect("mongodb://localhost/my_db");
my $persons = $connection->collection('person');
my $cats = $connection->collection('cat');
my $dogs = $connection->collection('dog');
my $p1 = $persons->create({ name => 'Bruce', age => 30 })->save;
my $c1 = $cats->create({ name => 'Bruce', age => 30 })->save;
my $d1 = $dogs->create({ name => 'Bruce', age => 30 })->save;
$c1->person($p1);
say Dumper $c1->person->data;

=cut
my $cat = $p1->add_cats({ name => 'cat', type =>'jiafeimao'});
my $dog= $p1->add_dogs({ type =>'dog'});
say Dumper $dog->data->{_id};
$dog->($dog->data->{_id});
say Dumper $cat->person->data;
