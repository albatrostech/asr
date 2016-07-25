package Asr;

=encoding utf8

=head1 NAME

ASR - Albatros Surfing Reports

=head1 VERSION

2.0.0-beta1

=head1 DESCRIPTION

B<ASR> parses squid access log and upload the data to a database. This data is
then expose as a rest web service which is in turn used by the web application
to present it to the end user.

=head1 INSTALLATION

This documentation assumes you are using B<Debian GNU/Linux 8> or one of it's
derivatives. Otherwise you will have to adapt the procedure to your specific
OS.

=head2 Install Required Software

The following software packages are required to install and run B<ASR>,
preferably they should be from your distribution package repository.

        sudo apt-get install build-essential perl perl-doc carton postgresql postgresql-server-dev-all supervisor

=head3 What's all that

=over 4

=item Build Tools

Standard build tools are required to build some CPAN packages. In B<Debian>
this is provided by the B<build-essential> package.

=item Perl

B<ASR>'s I<Loader> and I<Back-end> are written in Perl. In B<Debian> we need
the B<perl> and B<perl-doc> packages.

=item PostgreSQL

B<ASR> needs a RDBMS system to store its data. Currently only PostgreSQL is
supported as data store. Also in order to build the Perl driver for PostgreSQL
we need the development headers. In B<Debian> this is provided by the packages
B<postgresql> and B<postgresql-server-dev-all>.

=item Carton

Carton is used to install CPAN packages without polluting your system Perl
environment and easily executing programs which make use of these packages. In
B<Debian> this tool is provided by the B<carton> package.

=item Supervisor

Supervisor is a process manager that will start your I<Back-end> automatically.
In B<Debian> this tool is provided by the B<supervisor> package. Of course this
could be achieved with any other process manager like B<daemontools>,
B<upstart> or B<systemd>.

=back

=head2 Unpack and Configure Software

The software can be installed anywhere you like and can be run by any user.
Although it's B<not> recommended to run it as B<root>. In this document we have
decided to install the software at I</opt/asr-1.0> and run it as the user
B<www-data>.

        sudo tar xf asr-1.0.tar.gz -C /opt/
        cd /opt/asr-1.0
        sudo carton install --deployment

After the software is unpacked and its dependencies installed we need to edit
the configuration file and change the database connection information.  Edit
the file I<asr.json> and change the parameters under the B<db> key to match the
database we just created, in our example it should look like this:

        "db": {
           "name": "asr",
           "host": "localhost",
           "username": "asr",
           "password": "secret",
           "options": {
              "pg_enable_utf8": 1,
              "AutoCommit": 0,
              "RaiseError": 1
           }
        }

=head2 Create Database

The database can be created with the following commands. Make sure you replace
C<secret> with a more secure password and use that in the rest of the
configuration.

        sudo -u postgres psql -c "CREATE USER asr WITH ENCRYPTED PASSWORD 'secret'"
        sudo -u postgres psql -c "CREATE DATABASE asr OWNER asr"
        carton exec -- sqitch deploy db:pg://asr:secret@localhost/asr

=head2 Process Existing Data

While data processing will be done automatically, there might be some previous
log files you want to load right away. This process has two steps:

=over 4

=item Load Logs

First we load the logs into the access_log table. This is done by feeding log
data to the I<Loader>'s standard input like this:

        cd /opt/asr-1.0
        zcat /var/log/squid3/access.log.*.gz | sudo -u www-data carton exec -- perl script/asrl -f asr.json --no-materialize

=item Summarize Loaded Data

Once the data is loaded, it needs to be summarized in order to be used by the
I<Back-end>. To summarized the data, we need to know which days we just loaded
in order to execute the C<materialize_user_site_hourly> database procedure with
the proper parameters. Find out the days with the following command:

        psql -h localhost -U asr -c "select cast(ltime as date) from access_log group by 1 order by 1"

Once we know the days we can call the summarizing procedure. To summarize a
single day use the following database query:

        psql -h localhost -U asr -c "select materialize_user_site_hourly(false, '<date>')"

To summarize multiple consecutive days, use the following database query:

        psql -h localhost -U asr -c "select materialize_user_site_hourly(false, '<start_date>', '<end_date>')"

=back

=head2 Automatic Data Processing

B<Squid>'s logrotate configuration file normally found at
I</etc/logrotate.d/squid3> should be modified in order to load the logs once
they are rotated. The I<Loader> assumes logs to be loaded daily and so it will
call the summarize procedure automatically for yesterday's data.

        /var/log/squid3/*.log {
            daily
            compress
            #delaycompress
            rotate 7
            missingok
            nocreate
            sharedscripts
            postrotate
                test ! -e /var/run/squid3.pid || test ! -x /usr/sbin/squid3 || /usr/sbin/squid3 -k rotate
            endscript
            lastaction
                cd /opt/asr-1.0 && zcat /var/log/squid3/access.log.1.gz | sudo -u www-data carton exec -- perl script/asrl -f asr.json
            endscript
        }

Don't worry if your logs are not rotated exactly at midnight. Data newer than
midnight will remain in the access_log table and will be processed together
with the rest of today's data tomorrow and so on.

=head2 Automatic Start Up

The following configuration file I</etc/supervisor/conf.d/asr.conf> should be
created in order to have supervisor start the I<Back-end> on system start up.

        [program:asr]
        user=www-data
        group=www-data
        directory=/opt/asr-1.0
        command=carton exec -- hypnotoad -f script/asr
        stdout_logfile=/var/log/supervisor/%(program_name)s.log
        stderr_logfile=/var/log/supervisor/%(program_name)s.log
        autorestart=true

After this, restart supervisor and B<ASR>'s I<Back-end> should be listening at
L<http://localhost:3000>.

=head2 Web Interface

At this point the software should be available at L<http://localhost:3000/> and
this could be enough for your setup. If you want to expose the web interface to
your network you have multiple choices:

=head3 Hypnotoad

The I<Back-end> software is run by the B<Hypnotoad> web server. You could use
this same web server to serve the I<Front-end> application. This is the
simplest way to do it and it only requires to change the B<listen> parameter of
the B<hypnotoad> key of the configuration file I<asr.json> to look like this:

        "hypnotoad": {
           "listen" : ["http://0.0.0.0:3000"],
           "workers": 2
        }

This way the backend web server will listen on all IP addresses and you will be
able to access the application from your network. If your server has multiple
network interfaces it's recommended that you change the setup to only listen on
your internal IP.

=head3 Nginx

You can also use Nginx to expose B<ASR>'s I<Front-end> and proxy the API
requests to the I<Back-end> server. For that you could add a couple of
locations to your Nginx configuration like this:

        location /api {
            include proxy_params;
            proxy_pass  http://localhost:3000/api;
        }
        location / {
            root /opt/asr-1.0/public;
            index index.html;
            try_files $uri $uri/ =404;
        }

Adjust the locations to your liking in case you don't want the B<ASR> as your
root application.

In this setup, it's also required to inform the I<Back-end> web server it's
being proxy to correctly generate URLs, modify I<asr.json> like this:

        "hypnotoad": {
            "listen" : ["http://127.0.0.1:3000"],
            "workers": 2,
            "proxy": 1
        }

=head3 Apache

Apache can also be used as Reverse Proxy in the same way as Nginx.  For that we
need to enable some apache modules like this:

       sudo a2enmod proxy proxy_http headers

And place the following directives inside your virtual host and restart apache

        DocumentRoot /opt/asr-1.0/public
        ProxyPreserveHost On
        ProxyPass /api http://localhost:3000/api
        ProxyPassReverse /api http://localhost:3000/api
        #If apache's virtual host uses https uncomment the following line
        #RequestHeader set X-Forwarded-Proto "https"

As with Nginx we need to inform the I<Back-end> web server it's being proxy to
correctly generate URLs, modify I<asr.json> like this:

        "hypnotoad": {
            "listen" : ["http://127.0.0.1:3000"],
            "workers": 2,
            "proxy": 1
        }

=head1 DEVELOPMENT

=head2 Big Picture

There are three main components (I<Loader>, I<Back-end> and I<Front-end>) in
the program explained next.

=head3 Loader

The C<asrl> script parses Squid's C<access.log> file and uploads it to the
C<access_log> table. Also it handles dirty tasks like figuring out the domain
of the URL. And finally it summarizes the data from the C<access_log> table
into the C<user_site_hourly> table. The C<user_site_hourly> table holds data
summarized by user and site. Also the time gets truncated and summarized by
hour.

=head3 Back-end

The I<Back-end> is a L<Mojolicious|http://mojolicious.org/> application that
handles the process of exposing the data in the C<user_site_hourly> table as a
REST web service using C<JSON+HAL> as data format. The I<Back-end> only
generates C<JSON> and serve static resources when necessary. No HTML is ever
generated by the I<Back-end>.

=head3 Front-end

The I<Front-end> is an L<AngularJS|https://angularjs.org/> single page
application that interacts with the back-end via AJAX.

=head2 Get The Code

        git clone https://github.com/albatrostech/asr.git && cd asr

=head2 Required Tools

Beside the system packages required for running the software explained in the
installation section, you will also need these:

        sudo apt-get install build-essential perl perl-doc carton postgresql postgresql-server-dev-all

Node.js is required to build the I<Front-End>, B<Debian>'s current node package
is a bit old so we can either use L<nvm|https://github.com/creationix/nvm> or
install the package from
L<NodeSource|https://github.com/nodesource/distributions> like this:

        echo "deb https://deb.nodesource.com/node_6.x jessie main" | sudo tee /etc/apt/sources.list.d/nodesource.list
        sudo apt-key adv --keyserver pool.sks-keyservers.net --recv-keys 4096R/68576280
        sudo apt-get update
        sudo apt-get install nodejs

After that we should have fairly recent C<node> and C<npm> binaries, let's make
sure of that:

        npm -v
        node -v

If you are using a system wide B<Node.js> install, make sure I</usr/local/bin>
is in your path and that you user is part of the C<staff> system group. Then
run the following command to install the required tools from
L<NPM|https://npmjs.com/>:

        npm -g install grunt-cli bower

=head2 Required Packages

Multiple Perl, Node and Bower packages are required, those will be installed
inside the application directory and will not touch the rest of the system.
Keep in mind these commands can be run un parallel.

        bower install
        npm install
        carton install

=head2 Build Front-end

This command will build the I<Front-end> and place it under there I<public>
directory.

        grunt clean build

=head2 Run Back-end Devel Server

We can now run the development server which will also expose the content of the
I<public> directory as static resources

        carton exec -- morbo scripts/asr

Now the application should be accessible at L<http://localhost:3000/>

=head2 Run Front-end Devel Server

When working on the I<Front-end> it's better to use grunt's C<serve> task. This
will serve the I<Front-end> on a different port and proxy the requests directed
to the I<Back-end> to the C<morbo> server. So make sure you leave C<morbo>
running.

        grunt serve

=head2 Testing

=head3 Back-End Tests

To run the backend-tests use the following command:

        MOJO_MODE=test carton exec -- prove -l

=head1 TODO

=over 4

=item * Front-end testing

Write I<Front-End> tests.

=item * Setup Travis CI

=item * Use DBIx::Class

Move to DBIx::Class from SQL-Abstract-More.

=item * Bundle Carton

Explore the possibility of bundling carton with the distribution  so it's not
required to have it on the OS.

=item * Support other RDBMS

Add support for B<MySQL> and B<SQLite>

=item * Atomic Data Loading

The loader could provide an option `-s|--safe` to run the data insertion inside
a transaction to have all or nothing loading.

=item * Convert Loader to a Mojolicious Command

Investigate pro/cons of moving the loader script to a mojo command.

=item * Add support for DENIED lines

A new field should be added to the C<user_site_hourly> table to hold the
L<SquidCode|http://wiki.squid-cache.org/SquidFaq/SquidLogs#Squid_result_codes>. This code should be taken into account when generating statistics.
Specifically, DENIED should not count towards the user or site stats. Instead
it should have its own section. Also other codes should probably not be
accounted and might deserve their own section as well.

=back

=head1 AUTHORS

=over 4

=item Carlos Ramos Gómez

=item Carlos Jiménez Bendaña

=back

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2015, Albatros Technology.

This program is free software; you can redistribute it and/or modify it under
the terms of the AGPLv3 license.

=cut

use Modern::Perl;
use Mojo::Base 'Mojolicious';

use Mojolicious::Plugin::Database;
use Mojolicious::Plugin::Authentication;

use Asr::Core::Auth;
use Asr::Schema;

our $VERSION = '1.0.0';

has schema => sub {
   my $self = shift;
   my $conf = _get_connection_options($self->config);
   my $schema = Asr::Schema->connect(
      $conf->{dsn},
      $conf->{username},
      $conf->{password},
      $conf->{options}
   );

   return $schema;
};

# This method will run once at server start
sub startup {
   my $self = shift;
   push @{$self->commands->namespaces}, 'Asr::Command';
   $self->plugin('JSONConfig', {helper => 'config'});
   my $conf = _get_connection_options($self->config);

   $self->types->type(haljson => 'application/hal+json; charset=utf8');
   $self->renderer->default_format('json');

   $self->helper(schema => sub { $self->app->schema });

   $self->plugin('HeaderCondition');

   $self->plugin('Database', {
         dsn      => $conf->{dsn},
         username => $conf->{username},
         password => $conf->{password},
         options  => $conf->{options},
         helper   => 'db',
   });

   $self->plugin('Authentication', {
        autoload_user => 1,
        # session_key => 'wickedapp',
        load_user =>  \&Asr::Core::Auth::get_user,
        validate_user => \&Asr::Core::Auth::get_user_id,
        fail_render => {status => 401, template => 'unauthorized'},
   });

   $self->plugin('Authorization', {
        has_priv =>  \&Asr::Core::Auth::has_privilege,
        is_role => \&Asr::Core::Auth::has_role,
        user_privs => \&Asr::Core::Auth::user_privileges,
        user_role => \&Asr::Core::Auth::user_roles,
        fail_render => {status => 401, template => 'unauthorized'},
   });

   #Custom checks for validation
   $self->app->validator->add_check(
      in_columns => sub {
         #Having a sort param value of id.asc this will assert if the column
         #column 'id' exists in the provided list
         my ($validation, $name, $value) = (shift, shift, split('\.', shift));

         $value eq $_ and return for @_;
         return 1;
      }
   );

   #Serve index.html at the application root
   $self->routes->get('/' => sub {
        shift->reply->static('index.html');
   });

   #Authentication Routes
   my $auth_routes = $self->routes->under('/auth');
   $auth_routes->get('/logout')->to('auth#ajax_logout');
   $auth_routes->get('/me')
      ->over(authenticated => 1)
      ->to('auth#me');
   $auth_routes->post('/login')
      ->over(headers => {'Content-type' => qr'^application/json(?:;charset=.*$)*'i})
      ->to('auth#ajax_login');
   $auth_routes->post('/passwd')
      ->over(headers => {'Content-type' => qr'^application/json(?:;charset=.*$)*'i})
      ->over(authenticated => 1)
      ->to('auth#passwd');
#    #Login route to handle form data instead of json
#    $auth_routes->post('/login')
#         ->over(headers => {'Content-type' => qr'^application/x-www-form-urlencoded$'i})
#         ->to('auth#form_login');

   #Admin Routes
   my $admin_routes = $self->routes->under('/admin')->over(authenticated => 1);
   $admin_routes->get('/')->to('admin#root')->name('root');

   my $admin_users_routes = $admin_routes->get('/users')->name('users');
   $admin_users_routes->get('/')->to('admin#users')->name('self');
   $admin_users_routes->get(qr'/(\d+)')->to('admin#user')->name('user');

   #API Routes
   my $api_routes = $self->routes->under('/api')->over(authenticated => 1);
   $api_routes->get('/')->to('api#root')->name('root');

   #API Admin Routes
   my $api_admin_routes = $api_routes->get('/admin')->name('admin');
   $api_admin_routes->get('/')->to('Admin#index')->name('self');

   my $api_admin_users_routes = $api_admin_routes->get('/users')->name('users');
   $api_admin_users_routes->get('/')->to('Admin::Users#list')->name('api_admin_users_get');
   $api_admin_users_routes->get(qr'/users/(\d+)')->to('Admin::Users#read')->name('api_admin_user_get');

   my $api_users_routes = $api_routes->get('/users')->name('users');
   $api_users_routes->get('/')->to('api#users')->name('self');
   $api_users_routes->get('/search')->to('api#users_search')->name('search');
   $api_users_routes->get('/search/findBySite')->to('api#find_by_site')->name('findBySite');
   $api_users_routes->get('/search/findUser')->to('api#find_user')->name('findUser');

   my $api_sites_routes = $api_routes->get('/sites')->name('sites');
   $api_sites_routes->get('/')->to('api#sites')->name('self');
   $api_sites_routes->get('/search')->to('api#sites_search')->name('search');
   $api_sites_routes->get('/search/findByUser')->to('api#find_by_user')->name('findByUser');
   $api_sites_routes->get('/search/findSite')->to('api#find_site')->name('findSite');
}

sub _get_connection_options {
   my $conf = shift;
   my $dbname = $conf->{db}{name};
   my $dbhost = $conf->{db}{host};
   my $type = $conf->{db}{type};
   my (%result, %options);

   if ('pgsql' eq $type) {
      my $port = $conf->{db}{port} // 5432;
      $result{dsn} = "dbi:Pg:database=$dbname;host=$dbhost;port=$port";
      $options{quote_char} = '"';
      $options{pg_enable_utf8} = 1;
   } elsif ('mysql' eq $type) {
      my $port = $conf->{db}{port} // 3306;
      $result{dsn} = "dbi:mysql:database=$dbname;host=$dbhost;port=$port";
      $options{quote_char} = '`';
      $options{mysql_enable_utf8} = 1;
   } elsif ('sqlite' eq $type) {
      $result{dsn} = "dbi:SQLite:dbname=$dbname";
      $options{quote_char} = '`';
      $options{sqlite_unicode} = 1;
   } else {
      die 'No database type specified in configuration file.';
   }

   $options{name_sep} = '.';
   $options{RaiseError} = 1;
   $result{username} = $conf->{db}{username};
   $result{password} = $conf->{db}{password};
   $result{options} = \%options;

   return \%result;
}

1;
