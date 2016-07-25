use Mojo::Base;
use Test::More;
use Test::Mojo;

plan tests => 122;

my $t = Test::Mojo->new('Asr');
my $schema = $t->app->schema;
my $test_login = 'testadmin';
my $test_password = '$PBKDF2$HMACSHA1:10000:V1vkyg==$KYm4g9zuezKKOQ2lrIapwBqoqH0=';
my $dbrebase = `carton exec -- sqitch rebase -y db:pg://test:test\@localhost/test > /dev/null`;

if ($dbrebase) {
   BAIL_OUT($dbrebase);
}

$schema->resultset('User')->create({
      login => $test_login,
      password => $test_password
});

ok my $dadmin = $schema->resultset('User')->find(
   {login => 'admin'},
   {key => 'user_login_key'}
), 'default admin user exist';
ok $dadmin->id eq 0, 'default admin has uid 0';
is $dadmin->login, 'admin', 'got a login';
isnt $dadmin->password, undef, 'got a password';

ok my $tadmin = $schema->resultset('User')->find(
   {login => $test_login},
   {key => 'user_login_key'}
), 'test admin user exists';
isnt $tadmin, undef, 'found created test user';
ok $tadmin->id gt 0, 'got a positive id';
is $tadmin->login, $test_login, 'got a login';
is $tadmin->password, $test_password, 'got a login';

$t->get_ok('/admin')
   ->status_is(401, 'got correct status code')
   ->json_has('/timestamp', 'got timestamp value')
   ->json_is('/status' => '401', 'got correct status value')
   ->json_is('/message' => 'Authentication required', 'got correct message value');

$t->post_ok('/auth/login', json => {username => $dadmin->login, password => 'secret'})
   ->status_is(204, 'got correct status code')
   ->header_like('Set-Cookie' => qr/^mojolicious=.*$/, 'got session cookie')
   ->content_is('', 'got correct content value');

$t->get_ok('/admin')
   ->status_is(200, 'got correct status code')
   ->json_has('/_links/self/href')
   ->json_is('/_links/self/templated' => Mojo::JSON::false)
   ->json_has('/_links/roles/href')
   ->json_is('/_links/roles/templated' => Mojo::JSON::true)
   ->json_has('/_links/users/href')
   ->json_is('/_links/users/templated' => Mojo::JSON::true);

$t->get_ok('/admin/users')
   ->status_is(200, 'got correct status code')
   ->json_has('/_links/self/href')
   ->json_is('/_links/self/templated' => Mojo::JSON::true)
   ->json_has('/_links/search/href')
   ->json_is('/_links/search/templated' => Mojo::JSON::false)
   ->json_has('/_embedded/users')
   ->json_has('/page/index')
   ->json_like('/page/index', qr/^\d+$/)
   ->json_has('/page/size')
   ->json_like('/page/size', qr/^\d+$/)
   ->json_has('/page/totalItems')
   ->json_like('/page/totalItems', qr/^\d+$/);

$t->get_ok('/admin/users?sort=id.desc')
   ->status_is(200, 'got correct status code')
   ->json_has('/_links/self/href')
   ->json_is('/_links/self/templated' => Mojo::JSON::true)
   ->json_has('/_links/search/href')
   ->json_is('/_links/search/templated' => Mojo::JSON::false)
   ->json_has('/_embedded/users/0')
   ->json_is('/_embedded/users/0/id' => $tadmin->id)
   ->json_is('/_embedded/users/0/login' => $tadmin->login)
   ->json_has('/_embedded/users/1')
   ->json_is('/_embedded/users/1/id' => $dadmin->id)
   ->json_is('/_embedded/users/1/login' => $dadmin->login)
   ->json_has('/page/index')
   ->json_like('/page/index', qr/^\d+$/)
   ->json_has('/page/size')
   ->json_like('/page/size', qr/^\d+$/)
   ->json_has('/page/totalItems')
   ->json_like('/page/totalItems', qr/^\d+$/);

$t->get_ok('/admin/users?sort=login.desc')
   ->status_is(200, 'got correct status code')
   ->json_has('/_links/self/href')
   ->json_is('/_links/self/templated' => Mojo::JSON::true)
   ->json_has('/_links/search/href')
   ->json_is('/_links/search/templated' => Mojo::JSON::false)
   ->json_has('/_embedded/users/0')
   ->json_is('/_embedded/users/0/id' => $tadmin->id)
   ->json_is('/_embedded/users/0/login' => $tadmin->login)
   ->json_has('/_embedded/users/1')
   ->json_is('/_embedded/users/1/id' => $dadmin->id)
   ->json_is('/_embedded/users/1/login' => $dadmin->login)
   ->json_has('/page/index')
   ->json_like('/page/index', qr/^\d+$/)
   ->json_has('/page/size')
   ->json_like('/page/size', qr/^\d+$/)
   ->json_has('/page/totalItems')
   ->json_like('/page/totalItems', qr/^\d+$/);

$t->get_ok('/admin/users?sort=invalid.desc')
   ->status_is(400, 'should get invalid request due to invalid column')
   ->json_has('/status')
   ->json_has('/message')
   ->json_has('/timestamp');

$t->get_ok('/admin/users?sort=login.desc&size=1&index=1')
   ->status_is(200, 'got correct status code')
   ->json_has('/_links/self/href')
   ->json_is('/_links/self/templated' => Mojo::JSON::true)
   ->json_has('/_links/search/href')
   ->json_is('/_links/search/templated' => Mojo::JSON::false)
   ->json_has('/_embedded/users')
   ->json_is('/_embedded/users/id' => $tadmin->id)
   ->json_is('/_embedded/users/login' => $tadmin->login)
   ->json_has('/page/index')
   ->json_is('/page/index' => 1)
   ->json_has('/page/size')
   ->json_is('/page/size' => 1)
   ->json_has('/page/totalItems')
   ->json_is('/page/totalItems' => 2);

$t->get_ok('/admin/users?sort=login.desc&size=1&index=2')
   ->status_is(200, 'got correct status code')
   ->json_has('/_links/self/href')
   ->json_is('/_links/self/templated' => Mojo::JSON::true)
   ->json_has('/_links/search/href')
   ->json_is('/_links/search/templated' => Mojo::JSON::false)
   ->json_has('/_embedded/users')
   ->json_is('/_embedded/users/id' => $dadmin->id)
   ->json_is('/_embedded/users/login' => $dadmin->login)
   ->json_has('/page/index')
   ->json_is('/page/index' => 2)
   ->json_has('/page/size')
   ->json_is('/page/size' => 1)
   ->json_has('/page/totalItems')
   ->json_is('/page/totalItems' => 2);

$t->get_ok('/admin/users?size=invalid')
   ->status_is(400, 'should get invalid request due to invalid column')
   ->json_has('/status')
   ->json_has('/message')
   ->json_has('/timestamp');

$t->get_ok('/admin/users?index=invalid')
   ->status_is(400, 'should get invalid request due to invalid column')
   ->json_has('/status')
   ->json_has('/message')
   ->json_has('/timestamp');

$t->get_ok('/api/roles')
   ->status_is(404, 'got correct status code');

done_testing;
