package Asr::Schema::Result::User;

use Modern::Perl;
use base 'DBIx::Class::Core';

use Data::FormValidator;

__PACKAGE__->load_components(qw'Helper::Row::ToJSON Validation');

__PACKAGE__->table('user');
__PACKAGE__->validation(
   module => 'Data::FormValidator',
   auto => 0,
   filter => 0,
   profile => {
      required => [qw/login name password/]
   }
);
__PACKAGE__->add_columns(
   'id' => {
      data_type => 'integer',
      is_auto_increment => 1,
      is_nullable => 0
   },
   'login' => {
      data_type => 'varchar',
      size => 64,
      is_nullable => 0
   },
   'name' => {
      data_type => 'varchar',
      size => 255,
      is_nullable => 0
   },
   'password' => {
      data_type => 'varchar',
      size => 64,
      is_nullable => 0,
      is_serializable => 0,
      accessor => '_password'
   },
   'created' => {
      data_type => 'timestamp',
      is_nullable => 0
   },
   'modified' => {
      data_type => 'timestamp',
      is_nullable => 0
   }
);
__PACKAGE__->set_primary_key('id');
__PACKAGE__->add_unique_constraints(
   user_login_key => [qw<login>]
);
__PACKAGE__->has_many(user_roles => 'Asr::Schema::Result::UserRole',{'foreign.user_id' => 'self.id'});
__PACKAGE__->many_to_many(roles => 'user_roles', 'role');

sub password {
   my $self = shift;
   my $pbkdf2 = Crypt::PBKDF2->new(
      encoding => 'crypt',
      iterations => 10000,
      salt_len => 5
   );

   return $self->_password($pbkdf2->generate(shift)) if @_;

   return $self->_password;
}

1;
