# NAME

ASR - Albatros Surfing Reports

# VERSION

2.0.0-beta1

# DESCRIPTION

**ASR** parses squid access log and upload the data to a database. This data is
then expose as a rest web service which is in turn used by the web application
to present it to the end user.

# INSTALLATION

This documentation assumes you are using **Debian GNU/Linux 8** or one of it's
derivatives. Otherwise you will have to adapt the procedure to your specific
OS.

## Install Required Software

The following software packages are required to install and run **ASR**,
preferably they should be from your distribution package repository.

        sudo apt-get install build-essential perl perl-doc carton postgresql postgresql-server-dev-all supervisor

### What's all that

- Build Tools

    Standard build tools are required to build some CPAN packages. In **Debian**
    this is provided by the **build-essential** package.

- Perl

    **ASR**'s _Loader_ and _Back-end_ are written in Perl. In **Debian** we need
    the **perl** and **perl-doc** packages.

- PostgreSQL

    **ASR** needs a RDBMS system to store its data. Currently only PostgreSQL is
    supported as data store. Also in order to build the Perl driver for PostgreSQL
    we need the development headers. In **Debian** this is provided by the packages
    **postgresql** and **postgresql-server-dev-all**.

- Carton

    Carton is used to install CPAN packages without polluting your system Perl
    environment and easily executing programs which make use of these packages. In
    **Debian** this tool is provided by the **carton** package.

- Supervisor

    Supervisor is a process manager that will start your _Back-end_ automatically.
    In **Debian** this tool is provided by the **supervisor** package. Of course this
    could be achieved with any other process manager like **daemontools**,
    **upstart** or **systemd**.

## Unpack and Configure Software

The software can be installed anywhere you like and can be run by any user.
Although it's **not** recommended to run it as **root**. In this document we have
decided to install the software at _/opt/asr-1.0_ and run it as the user
**www-data**.

        sudo tar xf asr-1.0.tar.gz -C /opt/
        cd /opt/asr-1.0
        sudo carton install --deployment

After the software is unpacked and its dependencies installed we need to edit
the configuration file and change the database connection information.  Edit
the file _asr.json_ and change the parameters under the **db** key to match the
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

## Create Database

The database can be created with the following commands. Make sure you replace
`secret` with a more secure password and use that in the rest of the
configuration.

        sudo -u postgres psql -c "CREATE USER asr WITH ENCRYPTED PASSWORD 'secret'"
        sudo -u postgres psql -c "CREATE DATABASE asr OWNER asr"
        carton exec -- sqitch deploy db:pg://asr:secret@localhost/asr

## Process Existing Data

While data processing will be done automatically, there might be some previous
log files you want to load right away. This process has two steps:

- Load Logs

    First we load the logs into the access\_log table. This is done by feeding log
    data to the _Loader_'s standard input like this:

            cd /opt/asr-1.0
            zcat /var/log/squid3/access.log.*.gz | sudo -u www-data carton exec -- perl script/asrl -f asr.json --no-materialize

- Summarize Loaded Data

    Once the data is loaded, it needs to be summarized in order to be used by the
    _Back-end_. To summarized the data, we need to know which days we just loaded
    in order to execute the `materialize_user_site_hourly` database procedure with
    the proper parameters. Find out the days with the following command:

            psql -h localhost -U asr -c "select cast(ltime as date) from access_log group by 1 order by 1"

    Once we know the days we can call the summarizing procedure. To summarize a
    single day use the following database query:

            psql -h localhost -U asr -c "select materialize_user_site_hourly(false, '<date>')"

    To summarize multiple consecutive days, use the following database query:

            psql -h localhost -U asr -c "select materialize_user_site_hourly(false, '<start_date>', '<end_date>')"

## Automatic Data Processing

**Squid**'s logrotate configuration file normally found at
_/etc/logrotate.d/squid3_ should be modified in order to load the logs once
they are rotated. The _Loader_ assumes logs to be loaded daily and so it will
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
midnight will remain in the access\_log table and will be processed together
with the rest of today's data tomorrow and so on.

## Automatic Start Up

The following configuration file _/etc/supervisor/conf.d/asr.conf_ should be
created in order to have supervisor start the _Back-end_ on system start up.

        [program:asr]
        user=www-data
        group=www-data
        directory=/opt/asr-1.0
        command=carton exec -- hypnotoad -f script/asr
        stdout_logfile=/var/log/supervisor/%(program_name)s.log
        stderr_logfile=/var/log/supervisor/%(program_name)s.log
        autorestart=true

After this, restart supervisor and **ASR**'s _Back-end_ should be listening at
[http://localhost:3000](http://localhost:3000).

## Web Interface

At this point the software should be available at [http://localhost:3000/](http://localhost:3000/) and
you should be able to login with the credentials `admin/secret`. If you want
to expose the web interface to your network you have multiple choices:

### Hypnotoad

The _Back-end_ software is run by the **Hypnotoad** web server. You could use
this same web server to serve the _Front-end_ application. This is the
simplest way to do it and it only requires to change the `listen` parameter of
the `hypnotoad` key of the configuration file _asr.json_ to look like this:

        "hypnotoad": {
           "listen" : ["http://0.0.0.0:3000"],
           "workers": 2
        }

This way the backend web server will listen on all IP addresses and you will be
able to access the application from your network. If your server has multiple
network interfaces it's recommended that you change the setup to only listen on
your internal IP.

### Nginx

You can also use Nginx to expose **ASR**'s _Front-end_ and proxy the API
requests to the _Back-end_ server. For that you could add a couple of
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

Adjust the locations to your liking in case you don't want the **ASR** as your
root application.

In this setup, it's also required to inform the _Back-end_ web server it's
being proxy to correctly generate URLs, modify _asr.json_ like this:

        "hypnotoad": {
            "listen" : ["http://127.0.0.1:3000"],
            "workers": 2,
            "proxy": 1
        }

### Apache

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

As with Nginx we need to inform the _Back-end_ web server it's being proxy to
correctly generate URLs, modify _asr.json_ like this:

        "hypnotoad": {
            "listen" : ["http://127.0.0.1:3000"],
            "workers": 2,
            "proxy": 1
        }

# DEVELOPMENT

## Big Picture

There are three main components (_Loader_, _Back-end_ and _Front-end_) in
the program explained next.

### Loader

The `asrl` script parses Squid's `access.log` file and uploads it to the
`access_log` table. Also it handles dirty tasks like figuring out the domain
of the URL. And finally it summarizes the data from the `access_log` table
into the `user_site_hourly` table. The `user_site_hourly` table holds data
summarized by user and site. Also the time gets truncated and summarized by
hour.

### Back-end

The _Back-end_ is a [Mojolicious](http://mojolicious.org/) application that
handles the process of exposing the data in the `user_site_hourly` table as a
REST web service using `JSON+HAL` as data format. The _Back-end_ only
generates `JSON` and serve static resources when necessary. No HTML is ever
generated by the _Back-end_.

### Front-end

The _Front-end_ is an [AngularJS](https://angularjs.org/) single page
application that interacts with the back-end via AJAX.

## Get The Code

        git clone https://github.com/albatrostech/asr.git && cd asr

## Required Tools

Beside the system packages required for running the software explained in the
installation section, you will also need these:

        sudo apt-get install build-essential perl perl-doc carton postgresql postgresql-server-dev-all

Node.js is required to build the _Front-End_, **Debian**'s current node package
is a bit old so we can either use [nvm](https://github.com/creationix/nvm) or
install the package from
[NodeSource](https://github.com/nodesource/distributions) like this:

        echo "deb https://deb.nodesource.com/node_6.x jessie main" | sudo tee /etc/apt/sources.list.d/nodesource.list
        sudo apt-key adv --keyserver pool.sks-keyservers.net --recv-keys 4096R/68576280
        sudo apt-get update
        sudo apt-get install nodejs

After that we should have fairly recent `node` and `npm` binaries, let's make
sure of that:

        npm -v
        node -v

If you are using a system wide **Node.js** install, make sure _/usr/local/bin_
is in your path and that you user is part of the `staff` system group. Then
run the following command to install the required tools from
[NPM](https://npmjs.com/):

        npm -g install grunt-cli bower

## Required Packages

Multiple Perl, Node and Bower packages are required, those will be installed
inside the application directory and will not touch the rest of the system.
Keep in mind these commands can be run un parallel.

        bower install
        npm install
        carton install

## Build Front-end

This command will build the _Front-end_ and place it under there _public_
directory.

        grunt clean build

## Run Back-end Devel Server

We can now run the development server which will also expose the content of the
_public_ directory as static resources

        carton exec -- morbo scripts/asr

Now the application should be accessible at [http://localhost:3000/](http://localhost:3000/)

## Run Front-end Devel Server

When working on the _Front-end_ it's better to use grunt's `serve` task. This
will serve the _Front-end_ on a different port and proxy the requests directed
to the _Back-end_ to the `morbo` server. So make sure you leave `morbo`
running.

        grunt serve

## Testing

### Back-End Tests

To run the backend-tests use the following command:

        MOJO_MODE=test carton exec -- prove -l

# TODO

- Front-end testing

    Write _Front-End_ tests.

- Setup Travis CI
- Use DBIx::Class

    Move to DBIx::Class from SQL-Abstract-More.

- Bundle Carton

    Explore the possibility of bundling carton with the distribution  so it's not
    required to have it on the OS.

- Support other RDBMS

    Add support for **MySQL** and **SQLite**

- Atomic Data Loading

    The loader could provide an option \`-s|--safe\` to run the data insertion inside
    a transaction to have all or nothing loading.

- Convert Loader to a Mojolicious Command

    Investigate pro/cons of moving the loader script to a mojo command.

- Add support for DENIED lines

    A new field should be added to the `user_site_hourly` table to hold the
    [SquidCode](http://wiki.squid-cache.org/SquidFaq/SquidLogs#Squid_result_codes). This code should be taken into account when generating statistics.
    Specifically, DENIED should not count towards the user or site stats. Instead
    it should have its own section. Also other codes should probably not be
    accounted and might deserve their own section as well.

# AUTHORS

- Carlos Ramos Gómez
- Carlos Jiménez Bendaña

# COPYRIGHT AND LICENSE

Copyright (C) 2015, Albatros Technology.

This program is free software; you can redistribute it and/or modify it under
the terms of the AGPLv3 license.
