package Log::ger::Output::File;

# DATE
# VERSION

use strict;
use warnings;

use Log::ger::Util;

sub import {
    my ($package, %import_args) = @_;

    my $fh;
    if (defined(my $path = $import_args{path})) {
        open $fh, ">>", $path or die "Can't open log file '$path': $!";
    } elsif ($fh = $import_args{handle}) {
    } else {
        die "Please specify 'path' or 'handle'";
    }

    my $plugin = sub {
        my %args = @_;

        my $code = sub {
            print $fh $_[1];
            print $fh "\n" unless $_[1] =~ /\R\z/;
            $fh->flush;
        };
        [$code];
    };

    Log::ger::Util::add_plugin(
        'create_log_routine', [50, $plugin, __PACKAGE__], 'replace');
}

1;
# ABSTRACT: Send logs to file

=for Pod::Coverage ^(.+)$

=head1 SYNOPSIS

 use Log::ger::Output 'File' => (
     path => '/path/to/file.log', # or handle => $fh
 );
 use Log::ger;

 log_warn "blah ...";


=head1 DESCRIPTION

This is a simple output to file. File will be opened with append more. No
locking, rotation, or other fancy features (yet). Filehandle will be flushed
after each log.


=head1 CONFIGURATION

=head2 path => filename

Specify filename to open. File will be opened in append mode.

=head2 handle => glob|obj

Alternatively, you can provide an already opened filehandle.


=head1 SEE ALSO

L<Log::ger>
