package Time::Stats;

=head1 NAME

Time::Stats - Easy timing info

=head1 SYNOPSIS

use Time::Stats qw(mark clear stats);

use Time::Stats ':all';

clear();

mark();

stats();

=head1 DESCRIPTION

This module is designed to make it very easy to get timing info for your code, ala Time::HiRes, without needing to remember tv_interval and [gettimeofday], or writing your own methods for processing data.  This is mainly useful if DProf doesn't give you useful info on what's slowing you down, and you need to inspect larger sections of code.

It's pretty smart about loops and being used in persistent environments such as mod_perl.

=cut

use strict;
use warnings;

use Time::HiRes qw(tv_interval gettimeofday);

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(mark clear stats);
our %EXPORT_TAGS = (all => [qw(mark clear stats)]);

our $VERSION = '0.3';

our %last_caller_data;
our %time_data;

=over 4

=item mark

Flags a point in the code to pay attention to.  Times will be reported for the code in between two calls to mark within the same file.  If the calls to mark are inside of a loop, the times between two calls to mark will be summed.

=cut

sub mark {
    my @caller = caller;

    my $file = $caller[1];
    my $line = $caller[2];

    my $current_time = [gettimeofday];
        # if you're using mod_perl, or what not, you don't want line 99 to 40 taking up 40 seconds and messing up your numbers!
    if ($last_caller_data{$file} && ($last_caller_data{$file}->{'line'} < $line)) {
        my $start_line = $last_caller_data{$file}->{'line'};
        my $last_time = $last_caller_data{$file}->{'time'};
        $time_data{$file}->{$start_line.'-'.$line} += tv_interval($last_time, $current_time);
    }
    $last_caller_data{$file}->{'line'} = $line;
    $last_caller_data{$file}->{'time'} = $current_time;

    return;
}

=item clear

Removes all data currently tracked, in all files.

=cut

sub clear {
    %last_caller_data = ();
    %time_data = ();
}

=item stats

Prints a synopsis to STDERR.  This displays time per file, with the slowest intervals sorted to the top of each file.

=cut

sub stats {
    foreach my $file (keys %time_data) {
        print STDERR "File: $file\n";
        foreach my $lines (sort { $time_data{$file}->{$b} <=> $time_data{$file}->{$a} } keys %{$time_data{$file}}) {
            my $duration = $time_data{$file}->{$lines};
            my ($start, $end) = split(/-/, $lines);
            print STDERR "Lines $start to $end: $duration\n";
        }
    }
}

=back

=cut

1;

__END__

=head1 AUTHOR

Patrick A. Michaud, E<lt>vegitron@gmail.comE<gt>

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

