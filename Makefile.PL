use ExtUtils::MakeMaker;
WriteMakefile(
   NAME => 'Asr',
   AUTHOR => {
      'Carlos Ramos Gómez',
      'Carlos Jiménez Bendaña',
   },
   LICENSE => 'AGPLv3',
   ABSTRACT_FROM => 'lib/Asr.pm',
   VERSION_FROM => 'lib/Asr.pm',
   EXE_FILES => [qw( script/asrl )],
   META_MERGE => {
      resources => {
         bugtracker => 'https://github.com/albatrostech/asr/issues',
         homepage => 'https://github.com/albatrostech/asr',
         repository => 'https://github.com/albatrostech/asr.git',
      },
   },
   MIN_PERL_VERSION => '5.10.0',
   TEST_REQUIRES => {
      'Test::More' => '0.88'
   },
   BUILD_REQUIRES => {
      'Pod::Markdown' => '2.00',
      'SQL::Translator' => '0.11',
   },
   PREREQ_PM => {
      'perl' => 'v5.10.0',
      'App::Sqitch' => '0.9993',
      'ActiveRecord::Simple' => '0.65',
      'Crypt::PBKDF2' => '0.1509',
      'Data::Validate::IP' => '0.14',
      'DateTime' => '0.75',
      'DateTime::Format::Pg' => '0.16',
      'DBI' => '1.622',
      'DBD::Pg' => '2.19',
      'Data::HAL' => '1.00',
      'Mojolicious' => '6.18',
      'Mojolicious::Plugin::Authentication' => '1.26',
      'Mojolicious::Plugin::Database' => '1.08',
      'SQL::Abstract::More' => '1.26',
   },
   test => { TESTS => 't/*.t' },
);
