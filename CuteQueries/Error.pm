package XML::Twigx::CuteQueries::Error;

use strict;
use warnings;
use Carp;
use Config;
use overload '""' => "stringify", fallback=>1;
use base 'Class::Accessor'; __PACKAGE__->mk_accessors(qw(type text));

use constant SUCCESS     => 1;
use constant QUERY_ERROR => 2;
use constant DATA_ERROR  => 3;
use constant UNKNOWN     => 9_000;

my $USEDBY = "???";
sub import { $USEDBY = caller; return }

# new {{{
sub new {
    my $class = shift;
    my $this = bless {type=>UNKNOWN, text=>"unknown", @_, map {$_=>"unknown"} qw(ub_file ub_line file line package caller)}, $class;

    # This is ripped off from IPC::System::Simple::Exception, it's pretty hot

    my ($package, $file, $line, $sub);

    my $depth = 0;
    while (1) {
        $depth++;
        ($package, $file, $line, $sub) = CORE::caller($depth);

        # Skip up the call stack until we find something outside
        # of the caller, $class or eval space

        if( $package->isa($USEDBY) ) {
            $this->{ub_file} = $file;
            $this->{ub_line} = $line;
            next;
        }

        next if $package->isa($USEDBY);
        next if $package->isa($class);
        next if $package->isa(__PACKAGE__);
        next if $file =~ /^\(eval\s\d+\)$/;

        last;
    }

    # We now have everything correct, *except* for our subroutine
    # name.  If it's __ANON__ or (eval), then we need to keep on
    # digging deeper into our stack to find the real name.  However we
    # don't update our other information, since that will be correct
    # for our current exception.

    my $first_guess_subroutine = $sub;
    while (defined $sub and $sub =~ /^\(eval\)$|::__ANON__$/) {
        $depth++;
        $sub = (CORE::caller($depth))[3];
    }

    # If we end up falling out the bottom of our stack, then our
    # __ANON__ guess is the best we can get.  This includes situations
    # where we were called from the top level of a program.

    if (not defined $sub) {
        $sub = $first_guess_subroutine;
    }

    $this->{package}  = $package;
    $this->{file}     = $file;
    $this->{line}     = $line;
    $this->{caller}   = $sub;

    return $this;
}
# }}}

sub query_error {
    my $this = shift;

    return if $this->{type} == QUERY_ERROR;
    return;
}

sub data_error {
    my $this = shift;

    return if $this->{type} == DATA_ERROR;
    return;
}

sub throw {
    my $this = shift;

    croak $this;
}

sub stringify {
    my $this = shift;
    my $type = $this->{type};

    return  "DATA ERROR: $this->{text} at $this->{file} line $this->{line}" if $type == DATA_ERROR;
    return "QUERY ERROR: $this->{text} at $this->{file} line $this->{line}" if $type == QUERY_ERROR;

    return "UNKNOWN ERROR TYPE at $this->{ub_file} line $this->{ub_line}: $this->{text} or something at $this->{file} line $this->{line}";
}

sub is_success {
    my $this = shift;

    return 1 if $this->{type} == SUCCESS;
    return;
}

1;
