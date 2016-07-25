use Mojo::Base;
use Test::More;
use Test::Mojo;

my $t = Test::Mojo->new('Asr');
my $schema = $t->app->schema;
my $auser_login = 'auser';
my $auser_password = '$PBKDF2$HMACSHA1:10000:V1vkyg==$KYm4g9zuezKKOQ2lrIapwBqoqH0=';
my $dbrebase = `carton exec -- sqitch rebase -y db:pg://test:test\@localhost/test > /dev/null`;

if ($dbrebase) {
   BAIL_OUT($dbrebase);
}

$schema->resultset('User')->create({
      login => $auser_login,
      password => $auser_password
});

ok my $auser = $schema->resultset('User')->find(
   {login => 'auser'},
   {key => 'user_login_key'}
);
isnt $auser, undef, 'found created test user';
ok $auser->id gt 0, 'got a positive id';
is $auser->login, $auser_login, 'got a login';
is $auser->password, $auser_password, 'got a login';

$t->post_ok('/auth/login', json => {username => 'auser', password => 'secret'})
   ->status_is(204, 'got correct status code')
   ->header_like('Set-Cookie' => qr/^mojolicious=.*$/, 'got session cookie')
   ->content_is('', 'got correct content value');

$t->get_ok('/api')
   ->status_is(200, 'got correct status code')
   ->json_has('/_links/self/href')
   ->json_is('/_links/self/templated' => Mojo::JSON::false)
   ->json_has('/_links/sites/href')
   ->json_is('/_links/sites/templated' => Mojo::JSON::true)
   ->json_has('/_links/users/href')
   ->json_is('/_links/users/templated' => Mojo::JSON::true);

$t->get_ok('/api/users')
   ->status_is(200, 'got correct status code')
   ->json_has('/_links/self/href')
   ->json_is('/_links/self/templated' => Mojo::JSON::true)
   ->json_has('/_links/search/href')
   ->json_is('/_links/search/templated' => Mojo::JSON::false);

$t->get_ok('/api/sites')
   ->status_is(200, 'got correct status code')
   ->json_has('/_links/self/href')
   ->json_is('/_links/self/templated' => Mojo::JSON::true)
   ->json_has('/_links/search/href')
   ->json_is('/_links/search/templated' => Mojo::JSON::false);

done_testing;
