package Asr::Controller::Utils;

use Modern::Perl;
use parent qw(Exporter);

use Data::HAL;

our @EXPORT_OK = qw(generate_hal_links validate_paging_params in_array parse_sort_params);

sub generate_hal_links {
   my ($c, $links) = @_;
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

sub in_array {
   my ($val, @args) = @_;

   $val eq $_ and return 1 for @args;
   return 0;
}

sub validate_paging_params {
   my ($c, @columns) = @_;

   $c->validation->optional('size')->like(qr/^\d+$/)->is_valid;
   $c->validation->optional('index')->like(qr/^\d+$/)->is_valid;
   $c->validation->optional('sort')->like(qr/^\w+\.(?:asc|desc)+$/)->in_columns(@columns)->is_valid;
}

sub parse_sort_params {
   #TODO:
   #  - Change this to accept the list of sorting params instead of the mojo context
   #  - Allow using multiple sort params
   my $c = shift;
   my ($column, $dir);
   my %result = ();
   my $params = $c->validation->every_param('sort');

   for(@{$params}) {
      ($column, $dir) = split('\.');

      $column = lc($column);

      if (lc($dir) eq 'asc') {
         $result{'-asc'} = $result{'-asc'} // [];
         push (@{$result{'-asc'}}, $column);
      } else {
         $result{'-desc'} = $result{'-desc'} // [];
         push (@{$result{'-desc'}}, $column);
      }
   }

   return \%result;
}

1;
__END__

=head1 NAME

Asr::Controller::Utils - Common controller utilities.

=head2 Functions

=over

=item parse_sort_params(I<LIST>):  I<HASHREF>

=back

=cut
