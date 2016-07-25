package Asr::Schema::Result::UserRole;

use Modern::Perl;
use base 'DBIx::Class::Core';

__PACKAGE__->table('user_role');
__PACKAGE__->add_columns(
   'user_id' => {
      data_type => 'integer',
      is_nullable => 0
   },
   'role_id' => {
      data_type => 'int',
      is_nullable => 0
   }
);
__PACKAGE__->set_primary_key(qw<user_id role_id>);
__PACKAGE__->belongs_to(user => 'Asr::Schema::Result::User',{'foreign.id' => 'self.user_id'});
__PACKAGE__->belongs_to(role => 'Asr::Schema::Result::Role',{'foreign.id' => 'self.role_id'});

1;
