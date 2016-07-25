use Mojo::Base;
use Test::More;
use Test::Mojo;

plan tests => 37;

my $t = Test::Mojo->new('Asr');
my $schema = $t->app->schema;
my $tuser_login = 'tuser';
my $tuser_password = 'oldsecret';
my $tuser_hash = '$PBKDF2$HMACSHA1:10000:JrK4rA==$3QIoyQPYG+EnO0MOOSQ9wHFRb2w=';
my $tuser_newsecret = 'newsecret';
my $dbrebase = `carton exec -- sqitch rebase -y db:pg://test:test\@localhost/test > /dev/null`;

if ($dbrebase) {
   BAIL_OUT($dbrebase);
}

$schema->resultset('User')->create({
      login => $tuser_login,
      password => $tuser_hash
});

ok my $tuser = $schema->resultset('User')->find(
   {login => 'tuser'},
   {key => 'user_login_key'}
);
isa_ok $tuser, 'Asr::Schema::Result::User', 'found created test user';
ok $tuser->id gt 0, 'got a positive id';
is $tuser->login, $tuser_login, 'got a login';
isnt $tuser->password, undef, 'got a password';

$t->get_ok('/auth/me')
   ->status_is(401, 'got correct status code')
   ->json_has('/timestamp', 'got timestamp value')
   ->json_is('/status' => '401', 'got correct status value')
   ->json_is('/message' => 'Authentication required', 'got correct message value');

$t->post_ok('/auth/login', json => {username => 'tuser', password => 'badsecret'})
   ->status_is(401, 'got correct status code')
   ->json_has('/timestamp', 'got timestamp value')
   ->json_is('/status' => '401', 'got correct status value')
   ->json_is('/message' => 'Invalid login', 'got correct message value');

$t->post_ok('/auth/login', json => {
      username => 'tuser',
      password => $tuser_password
   })
   ->status_is(204, 'got correct status code')
   ->header_like('Set-Cookie' => qr/^mojolicious=.*$/, 'got session cookie')
   ->content_is('', 'got correct content value');

$t->get_ok('/auth/me')
   ->status_is(200, 'got correct status code');

$t->post_ok('/auth/passwd', json => {
      oldPassword => $tuser_password,
      newPassword => $tuser_newsecret
   })
   ->status_is(204, 'got correct status code')
   ->content_is('', 'got correct content value');

$t->post_ok('/auth/login', json => {
      username => 'tuser',
      password => $tuser_newsecret
   })
   ->status_is(204, 'got correct status code')
   ->header_like('Set-Cookie' => qr/^mojolicious=.*$/, 'got session cookie')
   ->content_is('', 'got correct content value');

$t->get_ok('/auth/logout')
   ->status_is(204, 'got correct status code')
   ->header_like('Set-Cookie' => qr/^mojolicious=.*?; expires=.*$/, 'got session cookie')
   ->content_is('', 'got correct content value');

$t->get_ok('/auth/me')
   ->status_is(401, 'got correct status code')
   ->json_has('/timestamp', 'got timestamp value')
   ->json_is('/status' => '401', 'got correct status value')
   ->json_is('/message' => 'Authentication required', 'got correct message value');

done_testing;
