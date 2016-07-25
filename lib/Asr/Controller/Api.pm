package Asr::Controller::Api;

use Modern::Perl;
use Mojo::Base 'Mojolicious::Controller';

use DBI;
use Data::HAL;
use DateTime;
use SQL::Abstract::More;

my $sqla = SQL::Abstract::More->new();

sub root {
   my $c = shift;
   my $result = Data::HAL->new();
   my $links = [
      {relation => 'self', templated => 0, href => '/api'},
      {relation => 'users', templated => 1, href => '/api/users', params => '{?size,index,sort,start,end}'},
      {relation => 'sites', templated => 1, href => '/api/sites', params => '{?size,index,sort,start,end}'}
   ];

   $result->links(&_generate_hal_links($c, $links));

   $c->render(text => $result->as_json, format => 'haljson');
}

sub _generate_hal_links {
   my $c = shift;
   my $links = shift;
   my $result = [];

   for(@{$links}) {
      my $link;
      my $href = $c->url_for($$_{href})->to_abs->to_string;

      if ($$_{templated}) {
         $href .= $$_{params};
      }

      $link = Data::HAL::Link->new(
         templated => $$_{templated},
         relation => $$_{relation},
         href => $href
      );

      push(@{$result}, $link);
   }

   return $result;
}

sub users {
   my $c = shift;
   my $links = [
      {relation => 'self', templated => 1, href => '/api/users', params => '{?size,index,sort,start,end}'},
      {relation => 'search', templated => 0, href => '/api/users/search'}
   ];
   my $result;
   &_sanitize_params($c);

   #The failed validation method requires Mojolicious 6.0
   $c->stash(message => "The following parameters failed validation: @{$c->validation->failed}");

   return $c->render(template => 'client_error', status => 400)
      if $c->validation->has_error;

   $result = &_get_data($c, 'remote_user', 'users');

   $result->links(&_generate_hal_links($c, $links));

   $c->render(text => $result->as_json, format => 'haljson');
}

sub sites {
   my $c = shift;
   my $links = [
      {relation => 'self', templated => 1, href => '/api/sites', params => '{?size,index,sort,start,end}'},
      {relation => 'search', templated => 0, href => '/api/sites/search'}
   ];
   my $result;
   &_sanitize_params($c);
   $c->stash(message => "The following parameters failed validation: @{$c->validation->failed}");

   return $c->render(template => 'client_error', status => 400)
      if $c->validation->has_error;

   $result = &_get_data($c, 'site', 'sites');

   $result->links(&_generate_hal_links($c, $links));

   $c->render(text => $result->as_json, format => 'haljson');
}

sub users_search {
   my $c = shift;
   my $result = Data::HAL->new();
   my $links = [
      {relation => 'self', templated => 0, href => '/api/users/search'},
      {relation => 'findBySite', templated => 1, href => '/api/users/search/findBySite', params => '{?size,index,sort,start,end,site}'}
   ];

   $result->links(&_generate_hal_links($c, $links));

   $c->render(text => $result->as_json, format => 'haljson');
}

sub sites_search {
   my $c = shift;
   my $result = Data::HAL->new();
   my $links = [
      {relation => 'self', templated => 0, href => '/api/sites/search'},
      {relation => 'findByUser', templated => 1, href => '/api/sites/search/findByUser', params => '{?size,index,sort,start,end,user}'}
   ];

   $result->links(&_generate_hal_links($c, $links));

   $c->render(text => $result->as_json, format => 'haljson');
}

sub find_by_site {
   my $c = shift;
   my $links = [{
      relation => 'self',
      templated => 1,
      href => '/api/users/search/findBySite',
      params => '{?size,index,sort,start,end,site}'
   }];
   my $result;
   &_sanitize_params($c);
   $c->validation->required('site');
   $c->stash(message => "The following parameters failed validation: @{$c->validation->failed}");

   return $c->render(template => 'client_error', status => 400)
      if $c->validation->has_error;

   $result = &_get_data($c, 'remote_user', 'users', $c->validation->param('site'), 'site');

   $result->links(&_generate_hal_links($c, $links));

   $c->render(text => $result->as_json, format => 'haljson');
}

sub find_by_user {
   my $c = shift;
   my $links = [{
      relation => 'self',
      templated => 1,
      href => '/api/sites/search/findByUser',
      params => '{?size,index,sort,start,end,user}'
   }];
   my $result;
   &_sanitize_params($c);
   $c->validation->required('user');
   $c->stash(message => "The following parameters failed validation: @{$c->validation->failed}");

   return $c->render(template => 'client_error', status => 400)
      if $c->validation->has_error;

   $result = &_get_data($c, 'site', 'sites', $c->validation->param('user'), 'remote_user');

   $result->links(&_generate_hal_links($c, $links));

   $c->render(text => $result->as_json, format => 'haljson');
}

sub find_user {
   my $c = shift;
   my $links = [{
      relation => 'self',
      templated => 1,
      href => '/api/users/search/findUser',
      params => '{?start,end,user}'
   }];
   my $result;
   &_sanitize_params($c);
   $c->validation->required('user');
   $c->stash(message => "The following parameters failed validation: @{$c->validation->failed}");

   return $c->render(template => 'client_error', status => 400)
      if $c->validation->has_error;

   $result = &_get_data($c, 'remote_user', 'users', $c->validation->param('user'), 'remote_user');

   $result->links(&_generate_hal_links($c, $links));

   $c->render(text => $result->as_json, format => 'haljson');
}

sub find_site {
   my $c = shift;
   my $links = [{
      relation => 'self',
      templated => 1,
      href => '/api/sites/search/findSite',
      params => '{?start,end,site}'
   }];
   my $result;
   &_sanitize_params($c);
   $c->validation->required('site');
   $c->stash(message => "The following parameters failed validation: @{$c->validation->failed}");

   return $c->render(template => 'client_error', status => 400)
      if $c->validation->has_error;

   $result = &_get_data($c, 'site', 'sites', $c->validation->param('site'), 'site');

   $result->links(&_generate_hal_links($c, $links));

   $c->render(text => $result->as_json, format => 'haljson');
}

sub _get_totals {
   my ($c, $data_column, %where) = @_;
   my ($sth, $sql, $rv, @bind);
   my @result;

   ($sql, @bind) = $sqla->select(
      -columns  => [
         'SUM(total_bytes)|total_bytes',
         'SUM(total_time)|total_time'
      ],
      -from     => 'user_site_hourly',
      -where    => \%where,
   );

   $sth = $c->db->prepare($sql) or $c->reply->exception(DBI->errstr());
   $sqla->bind_params($sth, @bind);
   $sth->execute() or $c->reply->exception(DBI->errstr());

   push(@result, ($sth->fetchrow_array())[0,1]);

   ($sql, @bind) = $sqla->select(
      -columns  => [ -distinct => $data_column],
      -from     => 'user_site_hourly',
      -where    => \%where,
   );

   $sth = $c->db->prepare($sql) or $c->reply->exception(DBI->errstr());
   $sqla->bind_params($sth, @bind);
   $rv = $sth->execute() or $c->reply->exception(DBI->errstr());

   push(@result, $rv);

   return @result;
}

sub _get_data {
   my ($c, $data_column, $relation, $search_by, $search_column) = @_;
   my ($sql, @bind, $sth, $rv);
   my ($total_bytes, $total_time, $total_items);
   my $result;
   my $config = $c->config;
   my $page_size = $c->param('size') // $config->{page_size};
   my $page_index = $c->param('index') // $config->{page_index};
   my $start_date = $c->param('start') // undef;
   my $end_date = $c->param('end') // DateTime->now;
   my $sort = $c->every_param('sort');
   my @order = &_parse_sort($sort) if $sort;
   my %where;

   if($search_by){
      $where{$search_column} = $search_by;
   }
   if($start_date) {
      $where{local_time} = {-between => [$start_date, $end_date]};
   }

   #Get totals
   ($total_bytes, $total_time, $total_items) = &_get_totals($c, $data_column, %where);

   if($total_bytes and $total_time) {
      ($sql, @bind) = $sqla->select(
         -columns  => [
            $data_column,
            'SUM(total_bytes)|total_bytes',
            'SUM(total_time)|total_time',
            "SUM(total_bytes) * 100 / $total_bytes|bytes_percent",
            "SUM(total_time) * 100 / $total_time|time_percent"
         ],
         -from     => 'user_site_hourly',
         -where    => \%where,
         -group_by => [$data_column],
         -order_by => \@order,
         -page_size => $page_size,
         -page_index => $page_index
      );

      $sth = $c->db->prepare($sql) or $c->reply->exception(DBI->errstr());
      $sqla->bind_params($sth, @bind);
      $rv = $sth->execute() or $c->reply->exception(DBI->errstr());

      $result = Data::HAL->new(
         resource => {
            page => {
               size => $page_size,
               index => $page_index,
               totalItems => ($total_items eq '0E0') ? 0 : $total_items * 1
            }
         },
         links => [],
         embedded => []
      );

      while(my @row = $sth->fetchrow_array()) {
         my %resource;
         my $embedded;
         my $selfLink = [{
            relation => 'self',
            templated => 1,
            href => "/api/$relation/$row[0]",
            params => '{?start,end}'
         }];

         $resource{$data_column} = $row[0];
         $resource{bytes} = $row[1] * 1;
         $resource{seconds} = $row[2] * 1;
         $resource{bytes_percent} = sprintf("%.8f", $row[3]) * 1;
         $resource{seconds_percent} = sprintf("%.8f", $row[4]) * 1;

         $embedded = Data::HAL->new(resource => \%resource, relation => $relation, links => []);
         $embedded->links(&_generate_hal_links($c, $selfLink));
         push(@{$result->embedded}, $embedded);
      }
   } else {
      $result = Data::HAL->new(
      resource => {
         page => {}
      },
      links => [],
      embedded => []
      );
   }

   return $result;
}

sub _parse_sort {
   my $sort_params = shift;
   my $c = shift;
   my @result;

   for(@{$sort_params}) {
      my ($column, $sort_dir) = split('\.');

      $column = &_sanitize_column(lc($column));

      if ($column and $sort_dir) {
         my $sort = (lc($sort_dir) eq 'asc') ? "+$column" : "-$column";
         push(@result, $sort);
      } else {
         $c->validation->error($column => ['incorrect']);
      }
   }

   return @result;
}

sub _sanitize_column {
   my $column = shift;
   my @avialable_columns = ('remote_user', 'site', 'total_bytes', 'total_time', 'bytes_percent', 'time_percent');

   return grep { return $_ if $_ eq $column } @avialable_columns;
}

sub _sanitize_params {
   my $c = shift;
   my $sort = $c->every_param('sort');
   &_parse_sort($sort, $c) if $sort;
   $c->stash(sort_message => "The following parameters are incorrect: @{$c->validation->failed}");

   $c->validation->optional('size')->like(qr/^\d+$/)->is_valid;
   $c->validation->optional('index')->like(qr/^\d+$/)->is_valid;
   $c->validation->optional('start')->like(qr/^\d{4}-\d\d-\d\d$/)->is_valid;
   $c->validation->optional('end')->like(qr/^\d{4}-\d\d-\d\d$/)->is_valid;
}

1;
