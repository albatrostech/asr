package Asr::Core::Auth;

use Modern::Perl;
use parent qw(Exporter);

use Crypt::PBKDF2;
use Asr::Schema::Result::User;

our @EXPORT_OK = qw(get_user_id get_user change_password);

sub get_user_id {
   my ($c, $login, $password, $extradata) = @_;
   my $pbkdf2 = Crypt::PBKDF2->new(encoding => 'crypt');

   my $user = $c->schema->resultset('User')->find({login => $login}, {
         key => 'user_login_key',
         columns => [qw(id password)]
      }
   );

   if (defined($user) and $pbkdf2->validate($user->password, $password)) {
      return $user->id;
   } else {
      return;
   }
}

sub get_user {
   my ($self, $uid) = @_;

   return $self->schema->resultset('User')->find($uid);
}

sub change_password {
   my ($c, $old_password, $new_password) = @_;
   my $pbkdf2 = Crypt::PBKDF2->new(encoding => 'crypt');

   my $user = $c->schema->resultset('User')->find({
         login => $c->current_user->login
      }, {
         key => 'user_login_key',
         columns => [qw(id password)]
      }
   );

   if (defined($user) and $pbkdf2->validate($user->password, $old_password)) {
      $user->password($new_password);
      $user->update;
      return 1;
   } else {
      return 0;
   }
}

sub has_privilege {
   # Not yet implemented.
   my ($self, $privilege) = @_;

   return 0;
}


sub has_role {
   # Not yet implemented.
   my ($self, $role, $extradata) = @_;

   return grep { $role eq $_->name } $self->current_user->roles;
}

sub user_privileges {
   # Not yet implemented.
   my ($self, $extradata) = @_;

   return;
}

sub user_roles {
   # Not yet implemented.
   my ($self, $extradata) = @_;

   return;
}

1;
