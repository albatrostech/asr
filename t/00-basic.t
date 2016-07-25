use Mojo::Base;
use Test::More;
use Test::Mojo;

my $t = Test::Mojo->new('Asr');
my $mode = $t->app->mode;
my $dbdeploy = `carton exec -- sqitch deploy db:pg://test:test\@localhost/test > /dev/null`;

if ($dbdeploy) {
   BAIL_OUT("Database deployment failed, error: $dbdeploy");
}

if ('test' ne $mode) {
   BAIL_OUT("Incorrect mode '$mode', should be 'test'. Forgot to set MOJO_MODE=test ?");
}
$t->get_ok('/')->status_is(200);

done_testing;
