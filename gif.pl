package gif;
## Routines to write a two-color GIF.
## Jeffrey Friedl (jfriedl@omron.co.jp)
## Copyrighted 19...oh hell, just take it.
##
$version = "940706.01";

## BLURB:
## Routines to create monochrome (and possibly transparent) gifs.
## Very simpleton. Maybe check out
##         http://www.ast.cam.ac.uk/cgi-bin/pgperl_formdemo.pg
## for more routines.
##
##>
##
## Three public routines:
##
##   gif'start(FH, w, h, R,G,B, r,g,b, transparent)
##
##      Prepare to write a stream of bits to the named file handle (as a
##      string). The w and h are the width and height of the image.
##      The first R G B are for the foreground, the 2nd for the background.
##      If $transparent is given and is true, the GIF89a "transparent color"
##      will be used for the background (otherwise it's a GIF87a).
##
##  gif'bits(text...)
##      Text should be a string (or strings) of 0s and/or 1s which are
##      taken as background and/or foreground bits of the image. The stream
##      should be sent row by row, starting with the top row, left to right.
##	Any number of bits may be sent with any one call to &gif'bits... it
##	makes no difference.
##
##	For example, to create a rediculously small (3x2) "picture" that
##	looks like  +------+
##                  |[][]  |
##                  |    []|
##                  +------+
##	The calls could look like:
##	   &gif'start("STDOUT", 3, 2, 255,255,255, 0,0,0);
##         &gif'bits("110"); ## the top row
##         &gif'bits("001"); ## the bottom row
##	   &gif'end;
##	or
##	   &gif'start("STDOUT", 3, 2, 255,255,255, 0,0,0);
##         &gif'bits("110001"); ## the bits for both rows
##	   &gif'end;
##	or
##	   &gif'start("STDOUT", 3, 2, 255,255,255, 0,0,0);
##         &gif'bits("1");   ## the first bit
##         &gif'bits("1");   ## the 2nd bit
##         &gif'bits("000"); ## 3rd,4th,and 5th bits
##         &gif'bits("11");  ## last two bits
##	   &gif'end;
##      Etc.
##
##  gif'end()
##      Finalizes things (you still need to close the file, though).
##
##<
###########################################################################

## a bit of initialization
$MAX = 1 << 12; ## maximum GIF compression value

sub start
{
    local($trans);
    ($FH, $w, $h, $fg_r, $fg_g, $fg_b, $bg_r, $bg_g, $bg_b, $trans) = @_;

    ## force unqualified filehandles into callers' package
    ## (this line stolen from E. Spafford)
    $FH = (caller)[$[] . "'$FH" if $FH !~ m/'/;

    $w    =   0 if !defined $w;
    $h    =   0 if !defined $h;
    $fg_r = 255 if !defined $fg_r;
    $fg_g = 255 if !defined $fg_g;
    $fg_b = 255 if !defined $fg_b;
    $bg_r =   0 if !defined $bg_r;
    $bg_g =   0 if !defined $bg_g;
    $bg_b =   0 if !defined $bg_b;
    $trans =  0 if !defined($trans);

    print $FH ($trans ? "GIF89a" : "GIF87a"),
	pack('CC CC C C C  CCC CCC',
	  $w & 0xff, ($w >> 8),
	  $h & 0xff, ($h >> 8),
	  0x80,                  # global color map. no color. 1 bit/pixel
	  0,                     # background is color 0
	  0,                     # pad
          $fg_r, $fg_g, $fg_b, $bg_r, $bg_g, $bg_b,
	  0);

    if ($trans)
    {
	print $FH pack('CCC CCCC C',
	    0x21,  ## magic: "Extension Introducer"
	    0xf9,  ## magic: "Graphic Control Label"
	       4,  ## bytes in block (between here and terminator)
	    0x01,  ## indicates that 'transparet index' is given
	    0, 0,  ## delay time.
	       0,  ## index of "transparent" color.
	    0x00); ## terminator.
    }

    print $FH ',', pack('CC CC CC CC CC',
	0,0,0,0,
	$w & 0xff, $w >> 8,
	$h & 0xff, $h >> 8,
	0, 2);

    &lzw_clear_dic();
}


sub end
{
    &lzw_out();
    &lzw_raw_out($EOF);
    &lzw_flush_raw();
    print $FH pack("C", 0);
    undef $FH;
}

sub bits
{
    return 0 if !defined $FH;
    local($cleartext) = join('',@_);
    local($index) = 0;
    local($len) = length $cleartext;
    $working = substr($cleartext, $index++, 1) if !defined $working;

    while ($index < $len)
    {
	$K = substr($cleartext, $index++, 1);
	if (defined $dic{$working.$K}) {
	    $working .= $K;
	} else {
	    &lzw_out();
	    $dic{$working.$K} = $code++;
	    $working = $K;
	}
    }
    1;
}

###########################################################################
###########################################################################

sub lzw_clear_dic
{
    undef %dic;
    $bits  = 2;
    $Clear = 1 << $bits;
    $EOF   = $Clear + 1;
    $code  = $Clear + 2;
    $nextbump = 1 << ++$bits;
    $WaitingBits = ''; ## init stuff.
    &lzw_raw_out($Clear);
    undef $working;
}

##
## Inherits: $bits, $working %dic
## Output the appropriate code for $working.
##
sub lzw_out
{
   &lzw_raw_out(($working eq '0' || $working eq '1')?$working:$dic{$working});
   if ($code >= $nextbump) {
       &lzw_clear_dic() if ($nextbump = 1 << ++$bits) > $MAX;
   }
}

##
## Given a raw value, write it out as a $bit-wide value.
##
## Inherits: $WaitingBits, $bits
##
sub lzw_raw_out
{
    local($raw) = @_;
    for ($b = 1; $b < $nextbump; $b <<= 1) {
	$WaitingBits .= ($raw & $b) ? '1' : '0';
    }
    while (length $WaitingBits >= 8) {
	&send_data_byte(unpack("C", pack("b8", $WaitingBits)));
	substr($WaitingBits, 0, 8) = '';
    }
}

##
## Flush out a byte to represent the remaining bits in $WaitingBits,
## if there are any.
## Inherits: $WaitingBits
##
sub lzw_flush_raw
{
    if (length $WaitingBits) {
	$WaitingBits .= "00000000"; ## enough padded 0's to make a byte
	&send_data_byte(unpack("C", pack("b8", $WaitingBits)));
	$WaitingBits = '';
    }
    &flush_data();
}

sub send_data_byte
{
    push(@out, @_);
    if (@out == 255) {
	print $FH pack("C256", 255, @out);
	@out = ();
    }
}

sub flush_data
{
    local($count) = scalar(@out);
    if ($count) {
	local($c2) = $count + 1;
	print $FH pack("C$c2", $count, @out);
	undef @out;
    }
}

1; ## required for a required package
__END__
