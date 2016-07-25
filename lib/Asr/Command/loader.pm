package Asr::Command::loader;

use Modern::Perl;
use Mojo::Base 'Mojolicious::Command';

has description   => 'This program loads a squid access.log file into the asrl database.';
has usage         => "Usage: Loader\n";
has text          => sub { shift->slurp };

sub run {
	my ($self, @args) = @_;
	my $app = $self->app;
	my $config = $app->config;
}

1;

__END__

=encoding utf8

=head1 NAME

asrl - Albatros Squid Reports Loader

=head1 SYNOPSIS

asrl [OPTION ...] [FILE ...]

Where FILE is the path to the squid F<access.log> file to load. If no FILE is given then asrl will default to reading from STDIN. All non argument options can be negated by appending a 'no' at the begining e.g. B<--no-materialize>.

=head2 Option Summary

=over 4

=item B<--help|-h>

Prints help and exit.

=item B<--safe|-s>

Single database transaction. I<UNIMPLEMEMNTED>

=item B<--progress|-p>

Display progress bar. I<UNIMPLEMEMNTED>

=item B<--dry-run|-n>

Does not modify the database.

=item B<--resume|-r>

Resume incompletely uploaded file. I<USE WITH CAUTION, READ THE MANUAL>

=item B<--config-file|-f>

Configuration file to use.

=item B<--materialize|-m>

Excute database sumarizing procedures.

=item B<--keep-detail|-k>

Keed the detail data in the access_log table.

=back

=head1 DESCRIPTION

This program loads a squid access.log file into the asrl database.

=head1 OPTIONS AND ARGUMENTS

=over 4

=item B<--help>

Prints this help and exit. No arguments allowed.

=item B<--safe>

Wraps all database changes in a single transaction. Enabled by default. No arguments allowed. I<UNIMPLEMENTED>

=item B<--progress>

Prints a nice progress bar with ETA for interactive use. Disabled by default. No arguments allowed. I<UNIMPLEMEMNTED>

=item B<--dry-run>

In this mode the program does not interact with the database in any way. So things like B<--materialize> or B<--resume> will be silently ignored. Usefull for testing corrupted log files without touching the database. Disabled by default. No arguments allowed.

=item B<--resume>

I<USE WITH CAUTION>. This option allows asrl to be able to resume an incomplete upload. It's possible to loose data with this option due to the possibility to have multiple log entries at the same milisecond. Since this option will resume the upload the the next milisecond of the current MAX value of the database. Disabled by default, No arguments allowed.

=item B<--config-file>

Sets configuration file to use. Defaults to F</etc/asr.conf>. String arguments required.

=item B<--materialize>

This flag will automatically call the materialize_user_site_hourly procedure in the database to make yesterday's data available for reporting. Enabled by default. No arguments allowed.

=item B<--keep-detail>

If materialize is specified, this flag will determine whether or not to keep the details in the access_log table. This will considerably slow down the materialization process because it will also link each detail record in access_log to the it's corresponding  master record in user_site_hourly. Disabled by default. No arguments allowed.

=back

=head1 COPYRIGHT

Copyright (c) Albatros Technology S.A.

=head1 AUTHOR

Carlos Ramos Gómez <cramos at albatros-tech dot net>

=cut
