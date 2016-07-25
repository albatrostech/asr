package Asr::Schema::Result::Role;

use Modern::Perl;
use base 'DBIx::Class::Core';

__PACKAGE__->load_components('Helper::Row::ToJSON');

__PACKAGE__->table('role');
__PACKAGE__->add_columns(
	'id' => {
		data_type => 'integer',
		is_auto_increment => 1,
      is_nullable => 0
	},
   'name' => {
      data_type => 'varchar',
      size => 64,
      is_nullable => 0
   },
	'description' => {
		data_type => 'varchar',
		size => 64,
		is_nullable => 0
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
__PACKAGE__->add_unique_constraint(
   role_name_key => [qw<name>]
);
__PACKAGE__->has_many(user_roles => 'Asr::Schema::Result::UserRole',{'foreign.role_id' => 'self.id'});
__PACKAGE__->many_to_many(users => 'user_roles', 'user');

1;
