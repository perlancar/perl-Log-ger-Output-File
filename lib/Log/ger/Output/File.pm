package Log::ger::Output::File;

# DATE
# VERSION

## no critic (InputOutput::RequireBriefOpen)

use strict;
use warnings;

sub get_hooks {
    my %conf = @_;
    my $lazy = $conf{lazy};

    my $fh;
    my $code_open = sub {
        return if $fh;
        if (defined(my $path = $conf{path})) {
            open $fh, ">>", $path or die "Can't open log file '$path': $!";
        } elsif ($fh = $conf{handle}) {
        } else {
            die "Please specify 'path' or 'handle'";
        }
        $fh;
    };

    $code_open->() unless $lazy;

    return {
        create_log_routine => [
            __PACKAGE__, 50,
            sub {
                my %args = @_;

                my $logger = sub {
                    $code_open->() if $lazy && !$fh;
                    print $fh $_[1];
                    print $fh "\n" unless $_[1] =~ /\R\z/;
                    $fh->flush;
                };
                [$logger];
            }],
    };
}

1;
# ABSTRACT: Send logs to file

=for Pod::Coverage ^(.+)$

=head1 SYNOPSIS

 use Log::ger::Output 'File' => (
     path => '/path/to/file.log', # or handle => $fh
     lazy => 1,                   # optional, default 0
 );
 use Log::ger;

 log_warn "blah ...";


=head1 DESCRIPTION

This is a simple output to file. File will be opened with append mode. No
locking, rotation, or other fancy features (yet). Filehandle will be flushed
after each log.


=head1 CONFIGURATION

=head2 path => filename

Specify filename to open. File will be opened in append mode.

=head2 handle => glob|obj

Alternatively, you can provide an already opened filehandle.

=head2 lazy => bool (default: 0)

If set to true, will only open the file right before we need to log the message
(instead of during output initialization). If you have lots of applications that
use file logging, this can avoid the proliferation of zero-sized log files. On
the other hand, the application bears an additional risk of failing to open a
log file in the middle of the run.


=head1 SEE ALSO

L<Log::ger>

L<Log::ger::Output::SimpleFile>

L<Log::ger::Output::FileWriteRotate>
