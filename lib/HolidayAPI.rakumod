unit module HolidayAPI:ver<0.0.1>:auth<cpan:TBROWDER>;

# https://holidayapi.com
constant $HOLAPI-KEY is export = %*ENV<HOLIDAYAPI_KEY>;

use HTTP::UserAgent;
use JSON::Fast;
use Data::Dump;

# local
use Constants;

# special indexing for Naval Observatory data months
our %mnum = (
    jan => 1,
    feb => 2,
    mar => 3,
    apr => 4,
    may => 5,
    jun => 6,
    jul => 7,
    aug => 8,
    sep => 9,
    oct => 10,
    nov => 11,
    dec => 12,
);

# invert the hash so key is number
our %num2mon = %mnum.invert;

sub show-resources is export {
    my @lines = %?RESOURCES<default-holidays.toml>.lines;
    for @lines {
        say $_
    }
}

sub get-holidayapi-data($year,
                        :@jfils!,
                        :$new-files! is rw,
                        :$force,
                        :$format = 'json',
                        :$quiet,
                        :$debug,
                       ) is export {
    # skip if file exists and not forcing a redo
    my $of = "data/holidayapi-data-{$year}.{$format}.orig";
    if !$force && $of.IO.r {
        say "NOTE: file '$of' exists. Use --force to overwrite.\n  Ignoring." if !$quiet;
	@jfils.push: $of if $of.IO.f;
	return;
    }

    my $ua = HTTP::UserAgent.new;
    $ua.timeout = 10;

    my $api-uri  = "https://holidayapi.com/v1/holidays?key={$HOLAPI-KEY}&country=US&pretty&year={$year}&format={$format}";
    my $response = $ua.get($api-uri);
    if $response.is-success {
	say "Working year '$year'...";
        spurt $of, $response.content;
	@jfils.push: $of if $of.IO.f;
        ++$new-files;
    }
    else {
	die $response.status-line;
    }
} # get-holidayapi-data

sub write-header($fh, $m, :$perl5) is export {

    if $perl5 {
        $fh.say: "package $m;"
    }
    else {
        $fh.say: "unit module $m;"
    }

} # write-header

sub write-ender($fh, $m, :$perl5) is export {
    $fh.say: "# end of module $m";
    return if !$perl5;

    $fh.say: "# return mandatory true value for a Perl 5 module";
    $fh.say: "1;";
} # write-ender

sub update-holidays-module(:%holidays,
                           :$year,
                           :$force,
                           :$quiet,
                           :$debug,
                           :$perl5) is export {
    my $m = 'Holidays';
    my $f = $perl5 ?? "{$m}.pm.{$year}" !! "{$m}.rakumod.{$year}";

    if !$force && $f.IO.f {
        say "NOTE: file '$f' exists. Use the 'force' option to overwrite it.";
        return '';
    }
    say "Creating file '$f'...";
    # create the Perl 5 or 6 module
    my $fh = open $f, :w;
    write-header($fh, $m, :$perl5);

    $fh.say: qq:to/HERE/;

    # source data now:
    #   http://holidayapi.com
    #
    # use an API to get the data auto-magically in a JSON file:

    sub get-year \{
	# the calendar year for the data below
	return '$year';
    }

    our %holidays
        = (
    HERE

    # fill with data
    for %holidays{$year}.keys -> $name {
        # get the desired values
        my $date     = %holidays{$year}{$name}<date>;
        my $observed = %holidays{$year}{$name}<observed>;
        my $p        = %holidays{$year}{$name}<public>;
        my $federal  = %holidays{$year}{$name}<is-federal>;

        # get the date parts
        # date format: yyyy-mm-dd
        $date ~~ /^ (\d**4) '-' (\d**2) '-' (\d**2) $/;
        my ($yd, $md, $dd) = (~$0, ~$1, ~$2);
        $observed ~~ /^ (\d**4) '-' (\d**2) '-' (\d**2) $/;
        my ($yo, $mo, $do) = (~$0, ~$1, ~$2);

        # convert mon numbers to jan-dec
        $md = +$md;
        $md = %num2mon{$md};
        $mo = +$mo;
        $mo = %num2mon{$mo};

        # strip leading zeroes from days
        $dd = +$dd;
        $do = +$do;

        my $no-diff = $observed eq $date ?? 1 !! 0;
        =begin comment
        # a single holiday entry formatted for the Perl 5 module:
        my-hol-name = {
            # the defined day [holidayapi: "date"]
            day   => '16',  # $dd
            month => 'jan', # $md
            # the federal day off [holidayapi: "observed" if different from "date"]
            # note each is treated indepently!!
            fedday   => '', # $do
            fedmonth => '', # $mo
            # [holidayapi: "public";
            public => 1, # or 0,
        }
        =end comment

        if $no-diff {
            $do = '';
            $mo = '';
            $yo = '';
        }
        else {
            $do = $do ne $dd ?? $do !! '';
            $mo = $mo ne $md ?? $mo !! '';
            $yo = $yo ne $yd ?? $yo !! '';
        }

        $fh.say: qq:to/HERE/;
            '$name' => \{
                # the official day
		day   => '$dd',
		month => '$md',
                year  => '$yd',
                # public same as Federal? NO
                public => $p,
		# the federal day off (if different, by parts)
		fedday   => '$do',   # empty if no change
		fedmonth => '$mo',   # empty if no change
		fedyear  => '$yo',   # empty if no change
                federal  => $federal,
            },
        HERE
    }

    # close the hash
    $fh.say: ");\n";

    write-ender($fh, $m, :$perl5);

    return $f;

} # update-holidays

sub read-holidayapi-json($year, %holidays, :$quiet, :$debug) is export {
    # Note this is the new format as of 2020.

    # skip if file exists and not forcing a redo
    my $jfil;
    if $debug > 1 {
        $jfil = "data/holidayapi-data-2019.json.debug";
    }
    else {
        $jfil = "data/holidayapi-data-{$year}.json.orig";
    }

    if !$jfil.IO.r {
        say "NOTE: input file '$jfil' not found." if !$quiet;
	return;
    }

    say "NOTE: using holiday input file '$jfil'." if !$quiet;

    say "DEBUG: working file '$jfil'" if $debug;
    my $jstr = slurp $jfil;

    my %j = from-json $jstr;
    if $debug {
        say Dump(%j, :color(False), :indent(4));
        say "DEBUG: holidays:";
        say "Debug early exit.";
        # %j<holidays> is an array of anonymous hashes
        for @(%j<holidays>) -> $h {
            my %h = %($h);
            say "  holiday: '{%h<name>}'";
        }
        exit;
    }

    # Extract data into the incoming %holidays hash.  Be sure to add
    # the US Armed Forces Day holiday if not found.
    my $afday-found = 0;
    for %j<holidays>.keys.sort -> $k {
        say "  k: $k" if $debug;
        my @val = %j<holidays>{$k};
        say "  type of \@val: {@val.^name}" if $debug;
        for @val -> @v {
            say "    type of \@v: {@v.^name}" if $debug;
            for @v -> $v {
                # this is the object of interest
                say "      type of \$v: {$v.^name}" if $debug;

                my $n = $v<name>;
                # skip if not in our interest list
                unless %hnames{$n} {
                    say "NOTE: skipping unwanted holiday '$n'..." if !$quiet;
                    next;
                }

                ++$afday-found if $n eq $afday;

                # is it a Federal holiday?
                # using the holidayapi name:
                my $is-federal = %fed-holidays{$n} ?? 1 !! 0;

                # NOW TRANSLATE NAME TO OUR VERSION
                say "DEBUG: holidayapi name:  '$n'" if $debug;
                $n = %hnames{$n};
                say "DEBUG: our holiday name: '$n'" if $debug;

                my $d = $v<date>;
                my $o = $v<observed>;
                my $p = $v<public>;
                if $p ~~ /:i true/ {
                    $p = 1;
                }
                elsif $p ~~ /:i false/ {
                    $p = 0;
                }
                else {
                    die "FATAL: Unrecognized 'public' value '$p'";
                }

                # check for dups
                if %holidays{$year}{$n} {
                    die "FATAL: Dup holiday ($year) name '$n'";
                }

                %holidays{$year}{$n}<date>       = $d;
                %holidays{$year}{$n}<observed>   = $o;
                %holidays{$year}{$n}<public>     = $p;
                %holidays{$year}{$n}<is-federal> = $is-federal;

            }
            #say $v.^name;
        }
        #say "";
        #say "  v: $v";
    }

    # now add the US Armed Forces Day holiday if not found
    if !$afday-found {
        my $n = $afday;
        if %holidays{$year}{$n}:exists {
            die "FATAL: Dup holiday ($year) name '$n'";
        }
        my $day   = %afdays{$year}; # two digits as a string
        my $month = '05'; # always May
        my $date  = "{$year}-05-{$day}";
        %holidays{$year}{$n}<date>       = $date;
        %holidays{$year}{$n}<observed>   = $date;
        %holidays{$year}{$n}<public>     = 1;
        %holidays{$year}{$n}<is-federal> = 0;
    }
} # read-holidayapi-json

sub read-holidayapi-json-old-format($year, %holidays, :$quiet, :$debug) is export {
    # skip if file exists and not forcing a redo
    my $jfil;
    if !$debug {
        $jfil = "data/holidayapi-data-{$year}.json.orig";
    }
    else {
        $jfil = "data/holidayapi-data-2019.json.debug";
    }

    if !$jfil.IO.r {
        say "NOTE: input file '$jfil' not found." if !$quiet;
	return;
    }

    say "NOTE: using holiday input file '$jfil'." if !$quiet;

    say "DEBUG: working file '$jfil'" if $debug;
    my $jstr = slurp $jfil;

    my %j = from-json $jstr;
    say Dump(%j, :color(False), :indent(4)) if (0 && $debug);

    say "DEBUG: keys:" if $debug;

    # Extract data into the incoming %holidays hash.  Be sure to add
    # the US Armed Forces Day holiday if not found.
    my $afday-found = 0;
    for %j<holidays>.keys.sort -> $k {
        say "  k: $k" if $debug;
        my @val = %j<holidays>{$k};
        say "  type of \@val: {@val.^name}" if $debug;
        for @val -> @v {
            say "    type of \@v: {@v.^name}" if $debug;
            for @v -> $v {
                # this is the object of interest
                say "      type of \$v: {$v.^name}" if $debug;

                my $n = $v<name>;
                # skip if not in our interest list
                unless %hnames{$n} {
                    say "NOTE: skipping unwanted holiday '$n'..." if !$quiet;
                    next;
                }

                ++$afday-found if $n eq $afday;

                # is it a Federal holiday?
                # using the holidayapi name:
                my $is-federal = %fed-holidays{$n} ?? 1 !! 0;

                # NOW TRANSLATE NAME TO OUR VERSION
                say "DEBUG: holidayapi name:  '$n'" if $debug;
                $n = %hnames{$n};
                say "DEBUG: our holiday name: '$n'" if $debug;

                my $d = $v<date>;
                my $o = $v<observed>;
                my $p = $v<public>;
                if $p ~~ /:i true/ {
                    $p = 1;
                }
                elsif $p ~~ /:i false/ {
                    $p = 0;
                }
                else {
                    die "FATAL: Unrecognized 'public' value '$p'";
                }

                # check for dups
                if %holidays{$year}{$n} {
                    die "FATAL: Dup holiday ($year) name '$n'";
                }

                %holidays{$year}{$n}<date>       = $d;
                %holidays{$year}{$n}<observed>   = $o;
                %holidays{$year}{$n}<public>     = $p;
                %holidays{$year}{$n}<is-federal> = $is-federal;

            }
            #say $v.^name;
        }
        #say "";
        #say "  v: $v";
    }

    # now add the US Armed Forces Day holiday if not found
    if !$afday-found {
        my $n = $afday;
        if %holidays{$year}{$n}:exists {
            die "FATAL: Dup holiday ($year) name '$n'";
        }
        my $day   = %afdays{$year}; # two digits as a string
        my $month = '05'; # always May
        my $date  = "{$year}-05-{$day}";
        %holidays{$year}{$n}<date>       = $date;
        %holidays{$year}{$n}<observed>   = $date;
        %holidays{$year}{$n}<public>     = 1;
        %holidays{$year}{$n}<is-federal> = 0;
    }
} # read-holidayapi-json-old-format
