##
## Jeffrey Friedl (jfriedl@omron.co.jp)
## Copyri.... ah hell, just take it.
##
## April 1993
## Prettied up July 1994
##

package Time;
$version = "940804.3";

## BLURB:
##   Routine to return the difference between two times as a string
##   along the lines of "4 years, 9 months, 1 minute, 23 seconds".
##   It can flexibly handle a number of different types of rounding
##   requests.
##
##>
##
## span(TIME1, TIME2, PLACES, ROUND)
##                   \__optional__/
##
##
## Given two times (as returned by 'time', $^T, etc.), normally returns a
## string along the lines of "4 years, 9 months, 1 minute, 23 seconds"
## indicating the difference between the two times.
##
## Units that might appear: years, months, days, hours, minutes, seconds.
##
## In general, units whose value are zero are skipped (such as the day and
## hour components of the example above). However, a final "0 whatever" is
## kept in certain cases discussed below.
##
## If PLACES is undefined, the full detail of the difference down to the
## second is returned, as shown above (but again, units for which the value
## is zero are not shown, so a trailing "0 seconds" would not appear at
## an even minute difference).
##
## If PLACES is defined and positive, only the first PLACES units starting
## with the first that prints are considered. For example, using PLACES = 2
## would get, depending upon the actual difference:
##
##       years and months
##       months and days
##       days and hours
##       hours and minutes
##    or minutes and seconds
##
## which seems pretty reasonable... if something was "1 year 3 months" ago,
## the info about the exact difference in seconds and minutes is probably
## more clutter than interesting.  In this case, the final unit to be
## printed is printed even if the result is zero. This is so that something
## like "4 years 0 months" doesn't come out as "4 years" only... we want to
## be sure to show the "significant digits", so to speak.
##
## If PLACES is defined and negative, only info *up* *to* unit -PLACES is
## returned (-1 == year, -2 == month, -3 == day, etc.). For example, with
## PLACES of 3 the above would come out as "4 years, 9 months".
## 
## If ROUND is defined and true, the result is round to the final unit
## printed. The round always results in a longer span. Using the above
## example, PLACES=1, ROUND=1 would result in "5 years".
##
####
##
## If PLACE is defined and zero, the 6-element array
##      ($year, $month, $day, $hour, $minute, $second)
## is returned. The values are deltas indicating the time difference.  This
## might be useful for creating a span description in a different language.
##
####
##
## Some example usages:
##
##   print "Jeffrey's been alive ", &Time'span(time, -117495540), ".\n";
##
##   print "About ",   &Time'span(time, 946684800, 3, 1)," until 2000.\n";
##
##   print "Exactly ", &Time'span(time, 946684800),   " until 2000.\n";
##
##   print "I've been running ", &Time'span(time, $), ".\n";
##
##   print "It'll be ", &Time'span(0, rand 10000),
##         " 'till I understand this damn thing!\n";
###
##
## A comment about that last example. I've seen routines that preport to
## tell you the difference between two times, where what they do is just
## pass the difference of two time values to gmtime and use what's returned
## as the difference in hours, minutes, seconds, etc. That's wrong.
##
## For hours, minutes and seconds, it's OK, but when you start getting into
## months and years, it breaks. For example the difference between
## now and one month from now could be less than 28 days or more than 31
## days, yet "1 month" will always be exactly 31 days as far as the
## aforementioned wrong method, since January 1970 had 31 days.
##
## BTW, I said "less than 28" and "more than 31" since there could be
## leap seconds added or subtracted!
##<
sub span
{
    local($t, $T, $places, $round) = @_;
   
    $places = 10 if !defined $places; ## default is a "big" value

    ## if times are the same, deal with it right away
    if ($t == $T) {
	return (0) x 6 if $places == 0;
	return "no time at all";
    }

    ## make sure they're in order; nab each's date and time
    ($t, $T) = ($T, $t) if $T > $t;
    local($SECOND, $MINUTE, $HOUR, $DAY, $MONTH, $YEAR) = (localtime $T);
    local($second, $minute, $hour, $day, $month, $year) = (localtime $t);

    ## change to individual deltas
    $year   -= $YEAR;
    $month  -= $MONTH;
    $day    -= $DAY;
    $hour   -= $HOUR;
    $minute -= $MINUTE;
    $second -= $SECOND;

    ## change the individual deltas into an overall delta
    while ($second < 0) { $minute--;	$second += 60;    		  }
    while ($minute < 0) { $hour--;	$minute += 60;    		  }
    while ($hour   < 0) { $day--;	$hour   += 24;    		  }
    while ($day    < 0) { $month--;	$day    += &dim(++$MONTH, $YEAR);
		          if ($MONTH == 12) { $MONTH = 0; $YEAR++ }       }
    while ($month  < 0) { $year--;	$month  += 12; 			  }

    ## if this is all they want, return it.
    return ($year, $month, $day, $hour, $minute, $second) if $places == 0;

    local($stop) = $places < 0 ? -$places : 10;
    local(%round, @out, $value);
    local($toprint) = 0;

    ##
    ## If we might be rounding, prepare info about how much longer to make
    ## the span WRT each unit at which we might round (only one will be
    ## used, if any). We only need enough seconds to get us into the next
    ## unit... i.e. if we need to round up to the next minute, so long as
    ## we add at least 30 seconds and no more than 60, we know we'll be safe.
    ## Actually, due to leap seconds, probably best to use a value right
    ## in the middle...
    ##
    if ($round) {
	$round{'minute'} = 60 -15          if $second >= 30;
	$round{'hour'}   = 60*60 -15       if $minute >= 30;
	$round{'day'}    = 60*60*24 -15    if $hour   >= 12;
	$round{'month'}  = 60*60*24*25     if $day    >= 15; ## sloffing a bit
	$round{'year'}   = 60*60*24*365    if $month  >=  6; ## sloffing a bit
    }

    ##
    ## while running below,
    ##    TOPRINT -- If positive, the number of units left to consider.
    ##               If one, we're on the last unit to print (and therefore
    ##               are subject to rounding if so requested, and must
    ##               print even if the unit's value is zero).
    ##
    ##    STOP --    Number of units after which to stop printing. Same
    ##		     stuff when it reaches one as with TOPRINT.
    ##
    foreach $UNIT ('year', 'month', 'day', 'hour', 'minute', 'second')
    {
	if (eval("\$value = \$$UNIT") || $toprint == 1 || $stop == 1) {
	    if (($toprint == 1 || $stop == 1) && defined $round{$UNIT}) {
		return &span($T, $t + $round{$UNIT}, $places);
	    }
	    push(@out, $value eq '1' ? "1 $UNIT" : "$value ${UNIT}s");
	    $toprint = $places if $places > 0 && @out == 1;
	}
	last if $toprint-- == 1 || (@out && (--$stop == 0));
    }
    join(', ', @out);
}


##
## NUM dim(MONTH, YEAR)
##
## Days In Month -- returns the number of days
## Returns the number of days in the given MONTH of the given YEAR.
## 
## YEAR is an absolute year (i.e. "1992", not "92")
## MONTH in range 1..12
##
sub dim
{
    local($month, $year) = @_;
    return (0, 31, 0, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31)[$month]
	if $month != 2;
    return (($year % 4 == 0) && ($year % 200 != 0)) ? 29 : 28;
}

1;

__END__
