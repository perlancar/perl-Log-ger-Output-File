package Log::ger::Output::File;

# DATE
# VERSION

## no critic (InputOutput::RequireBriefOpen)

use strict;
use warnings;

our %lock_handles;

sub get_hooks {
    my %conf = @_;

    my $lazy      = $conf{lazy};
    my $autoflush = $conf{autoflush}; $autoflush = 1 unless defined $autoflush;
    my $lock_mode = $conf{lock_mode} || 'none';

    (defined($conf{path}) || $conf{handle}) or
        die "Please specify 'path' or 'handle'";
    $lock_mode =~ /\A(none|write|exclusive)\z/ or
        die "Invalid lock_mode, please choose none|write|exclusive";
    $lock_mode ne 'none' && $conf{handle} and
        die "Locking using handle not supported for now";

    my $code_lock = sub {
        require File::Flock::Retry;
        my $key = defined($conf{path}) ? ":$conf{path}" : $conf{handle};
        if ($lock_handles{$key}) {
            return $lock_handles{$key};
        }
        $lock_handles{$key} = File::Flock::Retry->lock("$conf{path}.lck");
        #Scalar::Util::weaken($lock_handles{$key});
        # XXX how do we purge old %lock_handles keys?
        return $lock_handles{$key};
    };

    my $fh;
    my $code_open = sub {
        return if $fh;
        if (defined(my $path = $conf{path})) {
            open $fh, ">>", $path or die "Can't open log file '$path': $!";
        } else {
            $fh = $conf{handle};
        }
        $fh;
    };

    if ($lock_mode eq 'exclusive') {
        print "D:locking\n";
        $code_lock->();
    }

    $code_open->() unless $lazy;

    return {
        create_log_routine => [
            __PACKAGE__, 50,
            sub {
                my %args = @_;

                my $logger = sub {
                    my $lock_handle;
                    $code_open->() if $lazy && !$fh;
                    $lock_handle = $code_lock->() if $lock_mode eq 'write';
                    print $fh $_[1];
                    print $fh "\n" unless $_[1] =~ /\R\z/;
                    $fh->flush if $autoflush || $lock_handle;
                    undef $lock_handle;
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

This is an output module to file, with some options. File will be opened with
append mode. Filehandle will be flushed after each log.


=head1 CONFIGURATION

=head2 path => filename

Specify filename to open. File will be opened in append mode.

=head2 handle => glob|obj

Alternatively, you can provide an already opened filehandle.

=head2 autoflush => bool (default: 1)

Can be turned off if you need more speed, but note that under the absence of
autoflush, partial log messages might be written.

=head2 lazy => bool (default: 0)

If set to true, will only open the file right before we need to log the message
(instead of during output initialization). If you have lots of applications that
use file logging, this can avoid the proliferation of zero-sized log files. On
the other hand, the application bears an additional risk of failing to open a
log file in the middle of the run.

=head2 lock_mode => str (none|write|exclusive, default: none)

If you set this to C<none> (the default), no locking is done. When there are
several applications/processes that output log to the same file, messages from
applications might get jumbled, e.g. partial message from application 1 is
followed by message from application 2 and 3, then continued by the rest of
message from application 1, and so on.

If you set this to C<write>, an attempt to acquire an exclusive lock to C<<
<PATH>.lck >> will be made. If all logger processes use locking, this makes it
safe to log to the same file. However, this increases the overhead of writing
the log which will become non-negligible once you log to files at the rate of
thousands per second. Also, when a locking attempt fails after 60 seconds, this
module will die. C<autoflush> is automatically turned on under this locking
mode.

If you set this to C<exclusive>, locking will be attempted only once during the
output initialization.


=head1 TODO

When C<lock_mode> is set to C<exclusive>, and user switches output, we have not
released the lock.


=head1 SEE ALSO

L<Log::ger>

L<Log::ger::Output::SimpleFile>

L<Log::ger::Output::FileWriteRotate>
