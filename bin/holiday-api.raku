#!/usr/bin/env raku

use Config::TOML;

use lib <./lib ../lib>;

use HolidayAPI;
# %hnames
# %afdays
# %fed-holidays

my $fold = 0;

if !@*ARGS.elems {
    say qq:to/HERE/;
    Usage: {$*PROGRAM.IO.basename} <mode> [options]

    Modes:
      get           - get the api data sets
      create        - produce the Holidays.rakumod.YYYY modules
      test          - get the free data sets from last year
      show-holidays - dumps the default holidays to STDOUT as a TOML file

    Options:
      yyyy       - get or produce modules for year 2yyy [default:  previous year]
      dir=X      - output data to directory X           [default: './data']
      holidays=Y - define a TOML file ('Y') with the user's desired holiday list
      force      - overwrite an existing file
      quiet      - no informative messages
      debug      - for developer use
    HERE

    exit;
}

# modes
my $get    = 0;
my $create = 0;
my $test   = 0;
my $show   = 0;
sub z{$get=$create=$test=$show=0}

# options
my $outdir = './data';
my $debug  = 0;
my $force  = 0;
my $quiet  = 0;
my $perl5  = 0;
my $year-input;

# default year (next year, unless in 'test' mode)
my $d    = Date.new(now);
my $year = $d.year + 1;
# last year for free testing
my $ly   = $d.year - 1;
my %user-hnames;
for @*ARGS {
    # modes
    when /^c/ { z; $create = 1 }
    when /^g/ { z; $get    = 1 }
    when /^t/ { z; $test   = 1 }
    when /^s/ { z; $show   = 1 }

    # options
    when /^'dir=' (\S+) / {
        my $dir = ~$0;
        if $dir.IO.d {
            $outdir = $dir;
        }
        elsif $force {
            mkdir $outdir;
        }
        else {
            die "FATAL: Directory '$dir' doesn't exist. Use the 'force' option to proceed.";
        }
    }
    when /^'holidays=' (\S+) / {
        my $tf = ~$0;
        if not $tf.IO.f {
            die "FATAL: TOML holidays file '$tf' doesn't exist.";
        }
        %user-hnames  = from-toml :file($tf);
        %user-hnames .= antipairs;
    }
    when /^d/ { $debug = 1 }
    when /^f/ { $force = 1 }
    when /^q/ { $quiet = 1 }
    when /^p/ { $perl5 = 1 }
    when /^ 2\d**3 $/ { $year-input = $_ }
}

die "FATAL: No known mode entered." if not ($get or $create or $test or $show);

if $show {
    # dump to STDOUT and exit
    show-resources;
    exit;
}

if not $outdir.IO.d {
    if $force {
        mkdir $outdir;
    }
    else {
        die "FATAL: Dir '$outdir' doesn't exist. Use the 'force' option to proceed.";
    }
}

if $test {
    if $year-input.defined and $year-input < $ly {
        $year = $year-input;
    }
    else {
        $year = $ly;
    }
}
elsif $year-input {
    $year = $year-input
}

my @jfils     = [];
my $new-files = 0; # increment for each file written anew
if $get {
    get-holidayapi-data $year, :@jfils, :$new-files, :$force, :$quiet, :$debug;
    my $n = +@jfils;
    my $s = $n > 1 ?? 's' !! '';
    if $n {
        say "Normal end for 'get'. See JSON data file$s:";
        say "  $_" for @jfils;
    }
}
elsif $create {
    if $year-input {
        $year = $year-input;
        say "Input year is '$year'";
    }
    else {
        say "Year used is '$year'";
    }

    my %holidays;
    read-holidayapi-json($year, %holidays, :$debug);

    # in lib/CalFuncs.rakumod:
    update-holidays-module(:$year, :%holidays, :$force, :$quiet, :$debug,
                           :$perl5);


}
elsif $test {
    my $year = $ly;
    for <json csv tsv yaml> -> $format {
        get-holidayapi-data $year, :$force, :$format, :$quiet, :$debug;
    }
    my $n = +@jfils;
    my $s = $n > 1 ?? 's' !! '';
    if $n {
        say "Normal end for 'test'. See JSON data file$s:";
        say "  $_" for @jfils;
    }
}
