package Asr::Controller::Auth;

use Modern::Perl;
use Mojo::Base 'Mojolicious::Controller';

use Asr::Core::Auth qw(change_password);
use Asr::Schema::Result::User;
use Mojolicious::Validator;

sub passwd {
   my $self = shift;
   my $json = $self->req->json // {};

   $self->validation->input($json);
   $self->validation->required('oldPassword');
   $self->validation->required('newPassword');

   if ($self->validation->has_error) {

      # Respond 400 for invalid parameters
      return $self->stash(
         message => "The following parameters failed validation: "
           . @{$self->validation->failed}
      )->render(
         template => 'client_error',
         status   => 400
      );
   }

   if (&change_password($self, $json->{oldPassword}, $json->{newPassword})) {
      #For valid credentials respond 204 with empty body,
      #this will set the auth cookie
      $self->render(status => 204, data => '');
   }
   else {
      #For invalid credentials respond with a 401 and error message
      return $self->stash(
         message => 'Invalid login'
      )->render(
         status   => 400,
         template => 'client_error',
      );
   }
}

sub me {
   my $self = shift;
   my $result;

   $result = $self->current_user->TO_JSON;

   @{$${result}{roles}} = map { $_->name } $self->current_user->roles;

   $self->render(json => $result);
}

sub ajax_logout {
   my $self = shift;

   if ($self->is_user_authenticated) {
      $self->logout;
   }

   $self->render(data => '', status => 204);
}

sub ajax_login {
   my $self = shift;
   my $val = Mojolicious::Validator->new->validation;
   my $json = $self->req->json // {};

   $val->input($json);
   $val->required('username');
   $val->required('password');

   if ($val->has_error) {
      #Respond 400 for invalid parameters
      return $self->stash(
         message => "The following parameters failed validation: @{$val->failed}"
      )->render(
         template => 'client_error',
         status   => 400
      );
   }

   if ($self->authenticate($json->{username}, $json->{password})) {
      #For valid credentials respond 204 with empty body,
      #this will set the auth cookie
      return $self->render(status => 204, data => '');
   } else {
      #For invalid credentials respond with a 401 and error message
      $self->stash(message => 'Invalid login');
      return $self->render(
         status   => 401,
         template => 'unauthorized',
      );
   }
}

1;
