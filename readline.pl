##
## Perl Readline -- The Quick Help
## (see the manual for complete info)
##
## Once this package is included (require'd), you can then call
##	$text = &readline'readline($input);
## to get lines of input from the user.
##
## Normally, it reads ~/.inputrc when loaded... to suppress this, set
## 	$readline'rl_NoInitFromFile = 1;
## before requiring the package.
##
## Call rl_bind to add your own key bindings, as in
##	&readline'rl_bind('C-L', 'possible-completions');
##
## Call rl_set to set mode variables yourself, as in
##	&readline'rl_set('TcshCompleteMode', 'On');
##
## Call rl_basic_commands to set your own command completion, as in
##      &readline'rl_basic_commands('print', 'list', 'quit', 'run', 'status');
##
##

package readline;
##
## BLURB:
## A pretty full-function package similar to GNU's readline.
## Includes support for EUC-encoded Japanese text.
##
## Written by Jeffrey Friedl, Omron Corporation (jfriedl@omron.co.jp)
##
## Comments, corrections welcome.
##
## Thanks to the people at FSF for readline (and the code I referenced
## while writing this), and for Roland Schemers whose line_edit.pl I used
## as an early basis for this.
##
$version = "940817.008";

## 940817.008 - Added $var_CompleteAddsuffix.
##		Now recognizes window-change signals (at least on BSD).
##              Various typos and bug fixes.
##	Changes from Chris Arthur (csa@halcyon.com):
##		Added a few new keybindings.
##              Various typos and bug fixes.
##		Support for use from a dumb terminal.
##		Pretty-printing of filename-completion matches.
##		
## 930306.007 - Added rl_start_default_at_beginning.
##		Added optional message arg to &redisplay.
##		Added explicit numeric argument var to functions that use it.
##		Redid many commands to simplify.
##		Added TransposeChars, UpcaseWord, CapitalizeWord, DownCaseWord.
##		Redid key binding specs to better match GNU.. added
##		  undocumented "new-style" bindings.... can now bind
##		  arrow keys and other arbitrairly long key sequences.
##		Added if/else/then to .inputrc.
##		
## 930305.006 - optional "default" added (from mmuegel@cssmp.corp.mot.com).
##
## 930211.005 - fixed strange problem with eval while keybinding
##


$[ = 0;
&preinit;
&init;

##
## What's Cool
## ----------------------------------------------------------------------
## * hey, it's in perl.
## * Pretty full GNU readline like library...
## *	support for ~/.inputrc
## *    horizontal scrolling
## *	command/file completion
## *	rebinding
## *	history (with search)
## *	undo
## *	numeric prefixes
## * supports multi-byte characters (at least for the Japanese I use).
## * Has a tcsh-like completion-function mode.
##     call &readline'rl_set('tcsh-complete-mode', 'On') to turn on.
##

##
## What's not Cool
## ----------------------------------------------------------------------
## Can you say HUGE?
## I can't spell, so comments riddled with misspellings.
## Written by someone that has never really used readline.
## History mechanism is slightly different than GNU... may get fixed
##     someday, but I like it as it is now...
## Killbuffer not a ring.. just one level.
## Obviously not well tested yet.
## Written by someone that doesn't have a bell on his terminal, so
##     proper readline use of the bell may not be here.
##


##
## Functions beginning with F_ are functions that are mapped to keys.
## Variables and functions beginning rl_ may be accessed/set/called/read
## from outside the package.  Other things are internal.
##
## Some notable internal-only variables of global proportions:
##   $prompt -- line prompt (passed from user)
##   $line  -- the line being input
##   $D     -- ``Dot'' -- index into $line of the cursor's location.
##   $InsertMode -- usually true. False means overwrite mode.
##   $InputLocMsg -- string for error messages, such as "[~/.inputrc line 2]"
##   *emacs_keymap -- keymap for emacs-mode bindings:
##	@emacs_keymap - bindings indexed by ASCII ordinal
##      $emacs_keymap{'name'} = "emacs_keymap"
##      $emacs_keymap{'default'} = "SelfInsert"  (default binding)
##   *vi_keymap -- keymap for vi-mode bindings
##   *KeyMap -- current keymap in effect.
##   $LastCommandKilledText -- needed so that subsequent kills accumulate
##   $lastcommand -- name of command previously run
##   $lastredisplay -- text placed upon screen during previous &redisplay
##   $si -- ``screen index''; index into $line of leftmost char &redisplay'ed
##   $force_redraw -- if set to true, causes &redisplay to be verbose.
##   $AcceptLine -- when set, its value is returned from &readline.
##   $ReturnEOF -- unless this also set, in which case undef is returned.
##   $pending -- if set, value is to be used as input.
##   @undo -- array holding all states of current line, for undoing.
##   $KillBuffer -- top of kill ring (well, don't have a kill ring yet)
##   @tcsh_complete_selections -- for tcsh mode, possible selections
##
## Some internal variables modified by &rl_set (see comment at &rl_set for
## info about how these set'able variables work)
##   $var_EditingMode -- either *emacs_map or *vi_map
##   $var_TcshCompleteMode -- if true, the completion function works like
##      in tcsh.  That is, the first time you try to complete something,
##	the common prefix is completed for you. Subsequent completion tries
##	(without other commands in between) cycles the command line through
##	the various possibilities.  If/when you get the one you want, just
##	continue typing.
## Other $var_ things not supported yet.
##
## Some variables used internally, but may be accessed from outside...
##   $version -- just for good looks.
##   $rl_readline_name = name of program -- for .initrc if/endif stuff.
##   $rl_NoInitFromFile -- if defined when package is require'd, ~/.inputrc
##  	will not be read.
##   @rl_History -- array of previous lines input
##   $rl_HistoryIndex -- history pointer (for moving about history array)
##   $rl_completion_function -- see "How Command Completion Works" (way) below.
##   $rl_basic_word_break_characters -- string of characters that can cause
##	a word break for forward-word, etc.
##   $rl_start_default_at_beginning --
##	Normally, the user's cursor starts at the end of any default text
##	passed to readline.  If this variable is true, it starts at the
##	beginning.
##   $rl_completer_word_break_characters --
##	like $rl_basic_word_break_characters (and in fact defaults to it),
##	but for the completion function.
##   $rl_special_prefixes -- characters that are part of this string as well
##      as of $rl_completer_word_break_characters cause a word break for the
##	completer function, but remain part of the word.  An example: consider
##      when the input might be perl code, and one wants to be able to
##      complete on variable and function names, yet still have the '$',
##	'&', '@',etc. part of the $text to be completed. Then set this var
## 	to '&@$%' and make sure each of these characters is in
## 	$rl_completer_word_break_characters as well....
##   $rl_MaxHistorySize -- maximum size that the history array may grow.
##   $rl_screen_width -- width readline thinks it can use on the screen.
##   $rl_margin -- when moving to within this far from a margin, scrolls.
##   $rl_CLEAR -- what to output to clear the screen.
##   $rl_max_numeric_arg -- maximum numeric arg allowed.
##

sub preinit
{
    ## not yet supported... always on.
    $var_HorizontalScrollMode = 1;
    $var_HorizontalScrollMode{'On'} = 1;
    $var_HorizontalScrollMode{'Off'} = 0;

    $var_EditingMode{'emacs'} = *emacs_keymap;
    $var_EditingMode{'vi'} = *vi_keymap;
    $var_EditingMode = $var_EditingMode{'emacs'};

    ## not yet supported... always off
    $var_MarkModifiedLines = 0;
    $var_MarkModifiedLines{'Off'} = 0;
    $var_MarkModifiedLines{'On'} = 1;

    ## not yet supported... always off
    $var_PreferVisibleBell = 0;
    $var_PreferVisibleBell{'On'} = 1;
    $var_PreferVisibleBell{'Off'} = 0;

    ## this is an addition. Very nice.
    $var_TcshCompleteMode = 0;
    $var_TcshCompleteMode{'On'} = 1;
    $var_TcshCompleteMode{'Off'} = 0;

    $var_CompleteAddsuffix = 1;
    $var_CompleteAddsuffix{'On'} = 1;
    $var_CompleteAddsuffix{'Off'} = 0;

    eval 'require "ioctl.pl"'; ## try to get, don't die if not found.
    eval 'require "sys/ioctl.ph"'; ## try to get, don't die if not found.
    $TIOCGETP   = 0x40067408 if !defined($TIOCGETP);
    $TIOCSETP   = 0x80067409 if !defined($TIOCSETP);
    $TIOCGWINSZ = 0x40087468 if !defined($TIOCGWINSZ);
    $FIONREAD   = 0x4004667f if !defined($FIONREAD);
    $TCGETS     = 0x40245408 if !defined($TCGETS);
    $TCSETS     = 0x80245409 if !defined($TCSETS);
    $TCXONC     = 0x20005406 if !defined($TCXONC);

    ## TTY modes
    $RAW	= 040 if !defined($RAW);
    $ECHO	= 010 if !defined($ECHO);
    #$CBREAK    = 002 if !defined($CBREAK);
    $mode = $RAW; ## could choose CBREAK for testing....

    $IGNBRK     = 1 if !defined($IGNBRK);
    $BRKINT     = 2 if !defined($BRKINT);
    $ISTRIP     = 040 if !defined($ISTRIP);
    $INLCR      = 0100 if !defined($INLCR);
    $IGNCR      = 0200 if !defined($IGNCR);
    $ICRNL      = 0400 if !defined($ICRNL);
    $OPOST      = 1 if !defined($OPOST);
    $ISIG       = 1 if !defined($ISIG);
    $ICANON     = 2 if !defined($ICANON);
    $TCOON      = 1 if !defined($TCOON);

    $TERMIOS_READLINE_ION = $BRKINT;
    $TERMIOS_READLINE_IOFF = $IGNBRK | $ISTRIP | $INLCR | $IGNCR | $ICRNL;
    $TERMIOS_READLINE_OON = 0;
    $TERMIOS_READLINE_OOFF = $OPOST;
    $TERMIOS_READLINE_LON = 0;
    $TERMIOS_READLINE_LOFF = $ISIG | $ICANON | $ECHO;
    $TERMIOS_NORMAL_ION = $BRKINT;
    $TERMIOS_NORMAL_IOFF = $IGNBRK;
    $TERMIOS_NORMAL_OON = $OPOST;
    $TERMIOS_NORMAL_OOFF = 0;
    $TERMIOS_NORMAL_LON = $ISIG | $ICANON | $ECHO;
    $TERMIOS_NORMAL_LOFF = 0;

    $sgttyb_t   = 'C4 S';
    $winsz_t = "S S S S";  # rows,cols, xpixel, ypixel
    $winsz = pack($winsz_t,0,0,0,0);
    $fionread_t = "L";
    $fion = pack($fionread_t, 0);
    $NCCS = 17;
    $termios_t = "LLLLc" . ("c" x $NCCS);  # true for SunOS 4.1.3, at least...
    $termios = ''; ## just to shut up "perl -w".
    $termios = pack($termios, 0);  # who cares, just make it long enough
    $TERMIOS_IFLAG = 0;
    $TERMIOS_OFLAG = 1;
    $TERMIOS_CFLAG = 2;
    $TERMIOS_LFLAG = 3;
    $TERMIOS_VMIN = 5 + 4;
    $TERMIOS_VTIME = 5 + 5;

    $rl_start_default_at_beginning = 0;
    $rl_screen_width = 79; ## default

    $rl_completion_function = "rl_filename_list"
	unless defined($rl_completion_function);
    $rl_basic_word_break_characters = "\\\t\n' \"`\@\$><=;|&{(";
    $rl_completer_word_break_characters = $rl_basic_word_break_characters;
    $rl_special_prefixes = '';
    ($rl_readline_name = $0) =~ s#.*[/\\]## if !defined($rl_readline_name);

    @rl_History=() if !defined(@rl_History);
    $rl_MaxHistorySize = 100 if !defined($rl_MaxHistorySize);
    $rl_max_numeric_arg = 200 if !defined($rl_max_numeric_arg);

    $InsertMode=1;
    $KillBuffer='';
    $line='';
    $InputLocMsg = ' [initialization]';

    &InitKeymap(*emacs_keymap, 'SelfInsert', 'emacs_keymap',
		'C-@',	'Ding',
		'C-a',	'BeginningOfLine',
		'C-b',	'BackwardChar',
		'C-c',	'Interrupt',
		'C-d',	'DeleteChar',
		'C-e',	'EndOfLine',
		'C-f',	'ForwardChar',
		'C-g',	'Abort',
		'M-C-g',	'Abort',
		'C-h',	'BackwardDeleteChar',
		"TAB" ,	'Complete',
		"C-j" ,	'AcceptLine',
		'C-k',	'KillLine',
		'C-l',	'ClearScreen',
		"C-m" ,	'AcceptLine',
		'C-n',	'NextHistory',
		'C-o',	'Ding',
		'C-p',	'PreviousHistory',
		'C-q',	'QuotedInsert',
		'C-r',	'ReverseSearchHistory',
		'C-s',	'ForwardSearchHistory',
		'C-t',	'TransposeChars',
		'C-u',	'UnixLineDiscard',
		'C-v',	'QuotedInsert',
		'C-w',	'UnixWordRubout',
		'C-x',	'ReReadInitFile',
		'C-y',	'Yank',
		'C-z',	'Suspend',
		'C-\\',	'Ding',
		'C-^',	'Ding',
		'C-_',	'Undo',
		'DEL',	'BackwardDeleteChar',
		'M-<',	'BeginningOfHistory',
		'M->',	'EndOfHistory',
		'M-DEL',	'BackwardKillWord',
		'M-C-h',	'BackwardKillWord',
		'M-C-j',	'ToggleEditingMode',
		'M-b',	'BackwardWord',
		'M-c',	'CapitalizeWord',
		'M-d',	'KillWord',
		'M-f',	'ForwardWord',
		'M-l',	'DownCaseWord',
		'M-r',	'RevertLine',
		'M-t',	'TransposeWords',
		'M-u',	'UpcaseWord',
		'M-y',	'YankPop',
		"M-?",	'PossibleCompletions',
		"M-TAB",	'TabInsert',
		qq/"\e[A"/,  'previous-history',
		qq/"\e[B"/,  'next-history',
		qq/"\e[C"/,  'forward-char',
		qq/"\e[D"/,  'backward-char',
		qq/"\e[[A"/,  'previous-history',
		qq/"\e[[B"/,  'next-history',
		qq/"\e[[C"/,  'forward-char',
		qq/"\e[[D"/,  'backward-char',
		);

    *KeyMap = *emacs_keymap;
    foreach ('-', '0' .. '9') { &rl_bind("M-$_", 'DigitArgument'); }
    foreach ('A' .. 'Z')      { &rl_bind("M-$_", 'DoLowercaseVersion'); }

    ## Vi keymap not yet supported...
    &InitKeymap(*vi_keymap, 'Ding', 'vi_keymap',
		' ',	'EmacsEditingMode',
		"\n",	'EmacsEditingMode',
		"\r",	'EmacsEditingMode',
		);

    *KeyMap = $var_EditingMode;
}

sub get_window_size
{
    local($sig) = @_;
    if (ioctl(STDIN,$TIOCGWINSZ,$winsz)) {
	 local($num_rows,$num_cols) = unpack($winsz_t,$winsz);
	 $rl_screen_width = $num_cols if defined($num_cols) && $num_cols;
    }
    $rl_margin = int($rl_screen_width/3);
    if (defined $sig) {
	$force_redraw = 1;
	&redisplay();
    }

    $SIG{'WINCH'} = "readline'get_window_size";
}

sub init
{
    if ($ENV{'TERM'} eq 'emacs' || $ENV{'TERM'} eq 'dumb') {
	$dumb_term = 1;
    } elsif (! -t STDIN) {
    	$stdin_not_tty = 1;
    } else {
	&get_window_size;
	&F_ReReadInitFile if !defined($rl_NoInitFromFile);
	$InputLocMsg = '';
    }
    $initialized = 1;
}


##
## This is it. Called as &readline'readline($prompt, $default),
## (DEFAULT can be omitted) the next input line is returned (undef on EOF).
##
sub readline
{
    if ($stdin_not_tty) {
	return undef if !defined($line = <STDIN>);
	chop($line);
	return $line;
    }

    local($|) = 1;
    local($input);

    ## prompt should be given to us....
    $prompt = defined($_[0]) ? $_[0] : 'INPUT> ';

    if ($dumb_term) {
	print STDOUT $prompt;
	return undef if !defined($line = <STDIN>);
	chop($line);
	return $line;
    }

    $rl_HistoryIndex = @rl_History; ## Start at the end of the history.
    $line = defined($_[1]) ? $_[1] : '';
    $line_for_revert = $line;

# I don't think we need to do this, actually...
#    while (ioctl(STDIN,$FIONREAD,$fion))
#    {
#	local($n_chars_available) = unpack ($fionread_t, $fion);
#	## print "n_chars = $n_chars_available\n";
#	last if $n_chars_available == 0;
#	$line .= getc;  # should we prepend if $rl_start_default_at_beginning?
#    }

    $D = $rl_start_default_at_beginning ? 0 : length($line); ## set dot.
    $LastCommandKilledText = 0;     ## heck, was no last command.
    $lastcommand = '';		    ## Well, there you go.

    ##
    ## some stuff for &redisplay.
    ##
    $lastredisplay = '';	## Was no last redisplay for this time.
    $lastlen = length($lastredisplay);
    $lastdelta = 0;		## Cursor was nowhere
    $si = 0;			## Want line to start left-justified
    $force_redraw = 1;		## Want to display with brute force.
    &SetTTY;			## Put into raw mode.
    &redisplay(); 		## Show the line (just prompt at this point).

    *KeyMap = $var_EditingMode;
    undef($AcceptLine);		## When set, will return its value.
    undef($ReturnEOF);		## ...unless this on, then return undef.
    undef($pending);		## If set, contains text to use as input.
    @undo = ();			## Undo history starts empty for each line.

    while (!defined($AcceptLine)) {
	## get a character of input
	if (!defined($pending)) {
	    $input = getc;
	} else {
	    $input = substr($pending, 0, 1);
	    substr($pending, 0, 1) = '';
	    undef($pending) if length($pending) == 0;
	}

	push(@undo, &savestate); ## save state so we can undo.

	$ThisCommandKilledText = 0;
	##print "\n\rline is @$D:[$line]\n\r"; ##DEBUG
	&do_command(*KeyMap, 1, ord($input)); ## actually execute input
	&redisplay();
	$LastCommandKilledText = $ThisCommandKilledText;
    }

    undef @undo; ## Release the memory.
    &ResetTTY;   ## Restore the tty state.
    return undef if defined($ReturnEOF);
    $AcceptLine; ## return the line accepted.
}



##
## InitKeymap(*keymap, 'default', 'name', bindings.....)
##
sub InitKeymap
{
    local(*KeyMap) = shift(@_);
    local($func) = $KeyMap{'default'} = 'F_'.shift(@_);
    $KeyMap{'name'} = shift(@_);
    die qq/Bad default function [$func] for keymap "$KeyMap{'name'}"/
	if !defined(&$func);
    &rl_bind if @_ > 0;	## The rest of @_ gets passed silently.
}

sub max     { $_[0] > $_[1] ? $_[0] : $_[1]; }
sub min     { $_[0] < $_[1] ? $_[0] : $_[1]; }
sub isupper { ord($_[0]) >= ord('A') && ord($_[0]) <= ord('Z'); }
sub islower { ord($_[0]) >= ord('a') && ord($_[0]) <= ord('z'); }
sub toupper { &islower ? pack('c', ord($_[0])-ord('a')+ord('A')) : $_[0];}
sub tolower { &isupper ? pack('c', ord($_[0])-ord('A')+ord('a')) : $_[0];}


##
## Accepts an array as pairs ($keyspec, $function, [$keyspec, $function]...).
## and maps the associated bindings to the current KeyMap.
##
## keyspec should be the name of key sequence in one of two forms:
##
## Old (GNU readline documented) form:
##	     M-x	to indicate Meta-x
##	     C-x	to indicate Ctrl-x
##	     M-C-x	to indicate Meta-Ctrl-x
##	     x		simple char x
##      where 'x' above can be a single character, or the special:
##          special  	means
##         --------  	-----
##	     space	space   ( )
##	     spc	space   ( )
##	     tab	tab     (\t)
##	     del	delete  (0x7f)
##	     rubout	delete  (0x7f)
##	     newline 	newline (\n)
##	     lfd     	newline (\n)
##	     ret     	return  (\r)
##	     return  	return  (\r)
##	     escape  	escape  (\e)
##	     esc     	escape  (\e)
##
## New form:
##	  "chars"   (note the required double-quotes)
##   where each char in the list represents a character in the sequence, except
##   for the special sequences:
##	  \\C-x		Ctrl-x
##	  \\M-x		Meta-x
##	  \\M-C-x	Meta-Ctrl-x
##	  \\e		escape.
##	  \\x		x (if not one of the above)
##
##
## FUNCTION should be in the form 'BeginningOfLine' or 'beginning-of-line'.
## It is an error for the function to not be known....
##
## As an example, the following lines in .inputrc will bind one's xterm
## arrow keys:
##     "\e[[A": previous-history
##     "\e[[B": next-history
##     "\e[[C": forward-char
##     "\e[[D": backward-char
##

sub rl_bind
{
    ## ctrl(ord('a')) will return the ordinal for Ctrl-A.
    sub ctrl { $_[0] & ~($_[0]>=ord('a') && $_[0]<=ord('z') ? 0x60 : 0x40); }

    sub actually_do_binding
    {
	##
	## actually_do_binding($function, @sequence)
	##
	## Actually inserts the binding for @sequence to $function into the
	## current map.  @sequence is an array of character ordinals.
	##
	## If @sequence is more than one element long, all but the last will
	## cause meta maps to be created.
	##
	## $Function will have an implicit "F_" prepended to it.
	##
	local($func, $key, @keys) = @_;
	$key += 0;
	if (@keys == 0) {
	    if (defined($KeyMap[$key]) && $KeyMap[$key] eq 'F_PrefixMeta'
		&& $func ne 'PrefixMeta')
	    {
		warn "Warning$InputLocMsg: ".
		     " Re-binding char #$key to non-meta ($func)\n";
	    }
	    $KeyMap[$key] = "F_$func";
	} else {
	    if (defined($KeyMap[$key]) && ($KeyMap[$key] ne 'F_PrefixMeta')) {
		warn "Warning$InputLocMsg: ".
		     "Re-binding char #$key from [$KeyMap[$key]] to meta.\n";
	    }
	    $KeyMap[$key] = 'F_PrefixMeta';
	    local($map) = "$KeyMap{'name'}_$key";
	    eval("&InitKeymap(*$map, 'Ding', '$map') if !defined(%$map);1")
		    || die "$@";
	    eval "{local(*KeyMap)=*$map; &actually_do_binding($func,\@keys);}";
	}
    }

    local(@keys, $key, $func, $ord);

    while (defined($key = shift(@_)) && defined($func = shift(@_)))
    {
	##
	## Change the function name from something like
	##	backward-kill-line
	## to
	##	BackwardKillLine
	## if not already there.
	##
	$func = "\u$func";
	$func =~ s/-(.)/\u$1/g;

	if (!defined($_readline{"F_$func"})) {
	    warn "Warning$InputLocMsg: bad bind function [$func]\n";
	    next;
	}

	## print "sequence [$key] func [$func]\n"; ##DEBUG

	@keys = ();
 	## See if it's a new-style binding.
	if ($key =~ m/"(.*[^\\])"/) {
	    $key = $1;
	    ## New-style bindings are enclosed in double-quotes.
	    ## Characters are taken verbatim except the special cases:
	    ##    \C-x    Control x (for any x)
	    ##    \M-x    Meta x (for any x)
	    ##    \e	  Escape
	    ##    \x      x  (unless it fits the above pattern)
	    ## Look for special case of "\C-\M-x", which should be treated
	    ## like "\M-\C-x".
	    while (length($key) > 0) {
		if ($key =~ s#\\C-\\M-(.)##) {
		   push(@keys, ord("\e"), &ctrl(ord($1)));
		} elsif ($key =~ s#\\C-(.)##) {
		   push(@keys, ord($1)&~40);
		} elsif ($key =~ s#\\(M-|e)##) {
		   push(@keys, ord("\e"));
		} elsif ($key =~ s#\\(.)##) {
		   push(@keys, ord($1));
		} else {
		   push(@keys, ord($key));
		   substr($key,0,1) = '';
		}
	    }
	} else {
	    ## ol-dstyle binding... only one key (or Meta+key)
	    local($isctrl, $orig) = (0, $key);
	    $isctrl = $key =~ s/(C|Control|CTRL)-//i;
	    push(@keys, ord("\e")) if $key =~ s/(M|Meta)-//i; ## is meta?
	    ## Isolate key part. This matches GNU's implementation.
	    ## If the key is '-', be careful not to delete it!
	    $key =~ s/.*-(.)/$1/;
	    if    ($key =~ /^(space|spc)$/i)   { $key = ' ';    }
	    elsif ($key =~ /^(rubout|del)$/i)  { $key = "\x7f"; }
	    elsif ($key =~ /^tab$/i)           { $key = "\t";   }
	    elsif ($key =~ /^(return|ret)$/i)  { $key = "\r";   }
	    elsif ($key =~ /^(newline|lfd)$/i) { $key = "\n";   }
	    elsif ($key =~ /^(escape|esc)$/i)  { $key = "\e";   }
	    elsif (length($key) > 1) {
	        warn "Warning$InputLocMsg: strange binding [$orig]\n";
	    }
	    $key = ord($key);
	    $key = &ctrl($key) if $isctrl;
	    push(@keys, $key);
	}

	# 
	## Now do the mapping of the sequence represented in @keys
	 #
	# print "&actually_do_binding($func, @keys)\n"; ##DEBUG
	&actually_do_binding($func, @keys);
    }
}

##
## rl_set(var_name, value_string)
##
## Sets the named variable as per the given value, if both are appropriate.
## Allows the user of the package to set such things as HorizontalScrollMode
## and EditingMode.  Value_string may be of the form
##	HorizontalScrollMode
##      horizontal-scroll-mode
##
## Also called during the parsing of ~/.inputrc for "set var value" lines.
##
## The previous value is returned, or undef on error.
###########################################################################
## Consider the following example for how to add additional variables
## accessible via rl_set (and hence via ~/.inputrc).
##
## Want:
## We want an external variable called "FooTime" (or "foo-time").
## It may have values "January", "Monday", or "Noon".
## Internally, we'll want those values to translate to 1, 2, and 12.
##
## How:
## Have an internal variable $var_FooTime that will represent the current
## internal value, and initialize it to the default value.
## Make an array %var_FooTime whose keys and values are are the external
## (January, Monday, Noon) and internal (1, 2, 12) values:
##
##	    $var_FooTime = $var_FooTime{'January'} =  1; #default
##	                   $var_FooTime{'Monday'}  =  2;
##	                   $var_FooTime{'Noon'}    = 12;
##
sub rl_set
{
    local($var, $val) = @_;

    ## if the variable is in the form "some-name", change to "SomeName"
    local($_) = "\u$var";
    local($return) = undef;
    s/-(.)/\u$1/g;

    local(*V) = $_readline{"var_$_"};
    if (!defined($V)) {
	warn("Warning$InputLocMsg:\n".
	     "  Invalid variable `$var'\n");
    } elsif (!defined($V{$val})) {
	local(@selections) = keys(%V);
	warn("Warning$InputLocMsg:\n".
	     "  Invalid value `$val' for variable `$var'.\n".
	     "  Choose from [@selections].\n");
    } else {
	$return = $V;
        $V = $V{$val}; ## make the setting
    }
    $return;
}

##
## OnSecondByte($index)
##
## Returns true if the byte at $index into $line is the second byte
## of a two-byte character.
##
sub OnSecondByte
{
    return 0 if $_[0] == 0 || $_[0] == length($line);

    die 'internal error' if $_[0] > length($line);

    ##
    ## must start looking from the beginning of the line .... can
    ## have one- and two-byte characters interspersed, so can't tell
    ## without starting from some know location.....
    ##
    local($i);
    for ($i = 0; $i < $_[0]; $i++) {
	next if ord(substr($line, $i, 1)) < 0x80;
	## We have the first byte... must bump up $i to skip past the 2nd.
	## If that one we're skipping past is the index, it should be changed
	## to point to the first byte of the pair (therefore, decremented).
        return 1 if ++$i == $_[0];
    }
    0; ## seemed to be OK.
}

##
## CharSize(index)
##
## Returns the size of the character at the given INDEX in the
## current line.  Most characters are just one byte in length,
## but if the byte at the index and the one after has the high
## bit set those two bytes are one character of size=2.
##
## Assumes that index points to the first of a 2-byte char if not
## pointing to a 2-byte char.
##
sub CharSize
{
    return 2 if ord(substr($line, $_[0],   1)) >= 0x80 &&
                ord(substr($line, $_[0]+1, 1)) >= 0x80;
    1;
}

sub GetTTY
{
    $base_termios = $termios;  # make it long enough
    ioctl(STDIN,$TCGETS,$base_termios) || die "Can't ioctl TCGETS: $!";
}

sub XonTTY
{
    # I don't know which of these I actually need to do this to, so we'll
    # just cover all bases.

    ioctl(STDIN,$TCXONC,$TCOON);    # || die "Can't ioctl TCXONC STDIN: $!";
    ioctl(STDOUT,$TCXONC,$TCOON);   # || die "Can't ioctl TCXONC STDOUT: $!";
}

sub ___SetTTY
{
# print "before SetTTY\n\r";
# system 'stty -a';

    &XonTTY;

    &GetTTY
	if !defined($base_termios);

    @termios = unpack($termios_t,$base_termios);
    $termios[$TERMIOS_IFLAG] |= $TERMIOS_READLINE_ION;
    $termios[$TERMIOS_IFLAG] &= ~$TERMIOS_READLINE_IOFF;
    $termios[$TERMIOS_OFLAG] |= $TERMIOS_READLINE_OON;
    $termios[$TERMIOS_OFLAG] &= ~$TERMIOS_READLINE_OOFF;
    $termios[$TERMIOS_LFLAG] |= $TERMIOS_READLINE_LON;
    $termios[$TERMIOS_LFLAG] &= ~$TERMIOS_READLINE_LOFF;
    $termios[$TERMIOS_VMIN] = 1;
    $termios[$TERMIOS_VTIME] = 0;
    $termios = pack($termios_t,@termios);
    ioctl(STDIN,$TCSETS,$termios) || die "Can't ioctl TCSETS: $!";

# print "after SetTTY\n\r";
# system 'stty -a';
}

sub normal_tty_mode
{
    return if $stdin_not_tty || $dumb_term || !$initialized;
    &XonTTY;
    &GetTTY if !defined($base_termios);
    &ResetTTY;
}

sub ___ResetTTY
{
# print "before ResetTTY\n\r";
# system 'stty -a';

    @termios = unpack($termios_t,$base_termios);
    $termios[$TERMIOS_IFLAG] |= $TERMIOS_NORMAL_ION;
    $termios[$TERMIOS_IFLAG] &= ~$TERMIOS_NORMAL_IOFF;
    $termios[$TERMIOS_OFLAG] |= $TERMIOS_NORMAL_OON;
    $termios[$TERMIOS_OFLAG] &= ~$TERMIOS_NORMAL_OOFF;
    $termios[$TERMIOS_LFLAG] |= $TERMIOS_NORMAL_LON;
    $termios[$TERMIOS_LFLAG] &= ~$TERMIOS_NORMAL_LOFF;
    $termios = pack($termios_t,@termios);
    ioctl(STDIN,$TCSETS,$termios) || die "Can't ioctl TCSETS: $!";

# print "after ResetTTY\n\r";
# system 'stty -a';
}

sub SetTTY {
    return if $dumb_term || $stdin_not_tty;

#   system 'stty raw -echo';

    $sgttyb = ''; ## just to quiet "perl -w";
    ioctl(STDIN,$TIOCGETP,$sgttyb) || die "Can't ioctl TIOCGETP: $!";
    @tty_buf = unpack($sgttyb_t,$sgttyb);
    $tty_buf[4] |= $mode;
    $tty_buf[4] &= ~$ECHO;
    $sgttyb = pack($sgttyb_t,@tty_buf);
    ioctl(STDIN,$TIOCSETP,$sgttyb) || die "Can't ioctl TIOCSETP: $!";
}

sub ResetTTY {
    return if $dumb_term || $stdin_not_tty;

#   system 'stty -raw echo';

    ioctl(STDIN,$TIOCGETP,$sgttyb) || die "Can't ioctl TIOCGETP: $!";
    @tty_buf = unpack($sgttyb_t,$sgttyb);
    $tty_buf[4] &= ~$mode;
    $tty_buf[4] |= $ECHO;
    $sgttyb = pack($sgttyb_t,@tty_buf);
    ioctl(STDIN,$TIOCSETP,$sgttyb) || die "Can't ioctl TIOCSETP: $!";
}

##
## WordBreak(index)
##
## Returns true if the character at INDEX into $line is a basic word break
## character, false otherwise.
##
sub WordBreak
{
    index($rl_basic_word_break_characters, substr($line,$_[0],1)) != -1;
}

##
## do_command(keymap, numericarg, command)
##
## If the KEYMAP has an entry for COMMAND, it is executed.
## Otherwise, the default command for the keymap is executed.
##
sub do_command
{
    local(*KeyMap, $count, $key) = @_;
    local($cmd) = defined($KeyMap[$key]) ? $KeyMap[$key] : $KeyMap{'default'};
    if (!defined($cmd) || $cmd eq ''){
	warn "internal error (key=$key)";
    } else {
	## print "COMMAND [$cmd($count, $key)]\r\n"; ##DEBUG
	&$cmd($count, $key);
    }
    $lastcommand = $cmd;
}

##
## Save whatever state we wish to save as a string.
## Only other function that needs to know about it's encoded is getstate.
##
sub savestate
{
    join("\0", $D, $si, $LastCommandKilledText, $KillBuffer, $line);
}
sub getstate
{
    ($D, $si, $LastCommandKilledText, $KillBuffer, $line) = split(/\0/, $_[0]);
    $ThisCommandKilledText = $LastCommandKilledText;
}

##
## kills from D=$_[0] to $_[1] (to the killbuffer if $_[2] is true)
##
sub kill_text
{
    local($from, $to, $save) = (&min($_[0], $_[1]), &max($_[0], $_[1]), $_[2]);
    local($len) = $to - $from;
    if ($save) {
	$ThisCommandKilledText = 1;
	$KillBuffer = '' if !$LastCommandKilledText;
	$KillBuffer .= substr($line, $from, $len);
    }
    substr($line, $from, $len) = '';

    ## adjust $D
    if ($D > $from) {
	$D -= $len;
	$D = $from if $D < $from;
    }
}


##
## redisplay()
##
## Updates the screen to reflect the current $line.
##
## For the purposes of this routine, we prepend the prompt to a local copy of
## $line so that we display the prompt as well.  We then modify it to reflect
## that some characters have different sizes (i.e. control-C is represented
## as ^C, tabs are expanded, etc.)
##
## This routine is somewhat complicated by two-byte characters.... must
## make sure never to try do display just half of one.
##
## NOTE: If an argument is given, it is used instead of the prompt.
##
## This is some nasty code.
##
sub redisplay
{
    ## local $line has prompt also; take that into account with $D.
    local($prompt) = defined($_[0]) ? $_[0] : $prompt;
    local($line) = $prompt . $line;
    local($D) = $D + length($prompt);

    ##
    ## If the line contains anything that might require special processing
    ## for displaying (such as tabs, control characters, etc.), we will
    ## take care of that now....
    ##
    if ($line =~ m/[^\x20-\x7e]/)
    {
	local($new, $Dinc, $c) = ('', 0);

	## Look at each character of $line in turn.....
        for ($i = 0; $i < length($line); $i++) {
	    $c = substr($line, $i, 1);

	    ## A tab to expand...
	    if ($c eq "\t") {
		$c = ' ' x  (8 - (($i-length($prompt)) % 8));

	    ## A control character....
	    } elsif ($c =~ tr/\000-\037//) {
		$c = sprintf("^%c", ord($c)+ord('@'));

	    ## the delete character....
	    } elsif (ord($c) == 127) {
		$c = '^?';
	    }
	    $new .= $c;

	    ## Bump over $D if this char is expanded and left of $D.
	    $Dinc += length($c) - 1 if (length($c) > 1 && $i < $D);
	}
	$line = $new;
	$D += $Dinc;
    }

    ##
    ## Now $line is what we'd like to display.
    ##
    ## If it's too long to fit on the line, we must decide what we can fit.
    ##
    ## If we end up moving the screen index ($si) [index of the leftmost
    ## character on the screen], to some place other than the front of the
    ## the line, we'll have to make sure that it's not on the first byte of
    ## a 2-byte character, 'cause we'll be placing a '<' marker there, and
    ## that would screw up the 2-byte character.
    ##
    ## Similarly, if the line needs chopped off, we make sure that the
    ## placement of the tailing '>' won't screw up any 2-byte character in
    ## the vicinity.
    ##
    if ($D == length($prompt)) {
	$si = 0;   ## display from the beginning....
    } elsif ($si >= $D) {
	$si = &max(0, $D - $rl_margin);
	$si-- if $si != length($prompt) && !&OnSecondByte($si);
    } elsif ($si + $rl_screen_width <= $D) {
	$si = &min(length($line), ($D - $rl_screen_width) + $rl_margin);
	$si-- if $si != length($prompt) && !&OnSecondByte($si);
    } else {
	## Fine as-is.... don't need to change $si.
    }
    substr($line, $si, 1) = '<' if $si != 0; ## put the "chopped-off" marker

    $thislen = &min(length($line) - $si, $rl_screen_width);
    if ($si + $thislen < length($line)) {
	## need to place a '>'... make sure to place on first byte.
	$thislen-- if &OnSecondByte($si+$thislen-1);
	substr($line, $si+$thislen-1,1) = '>';
    }

    ##
    ## Now know what to display.
    ## Must get substr($line, $si, $thislen) on the screen,
    ## with the cursor at $D-$si characters from the left edge.
    ##
    $line = substr($line, $si, $thislen);
    $delta = $D - $si;	## delta is cursor distance from left margin.

    ##
    ## Now must output $line, with cursor $delta spaces from left margin.
    ##

    ##
    ## If $force_redraw is not set, we can attempt to optimize the redisplay
    ## However, if we don't happen to find an easy way to optimize, we just
    ## fall through to the brute-force method of re-drawing the whole line.
    ##
    if (!$force_redraw)
    {
	## can try to optimize here a bit.

	## For when we only need to move the cursor
	if ($lastredisplay eq $line) {
	    ## If we need to move forward, just overwrite as far as we need.
	    if ($lastdelta < $delta) {
		print substr($line, $lastdelta, $delta-$lastdelta);

	    ## Need to move back.
	    } elsif($lastdelta > $delta) {
		## Two ways to move back... use the fastest. One is to just
		## backspace the proper amount. The other is to jump to the
		## the beginning of the line and overwrite from there....
		if ($lastdelta - $delta < $delta) {
		    print "\b" x ($lastdelta - $delta);
		} else {
		    print "\r", substr($line, 0, $delta);
		}
	    }
	    ($lastlen, $lastredisplay, $lastdelta) = ($thislen, $line, $delta);
	    return;
	}

	## for when we've just added stuff to the end
	if ($thislen > $lastlen &&
	    $lastdelta == $lastlen &&
	    $delta == $thislen &&
	    substr($line, 0, $lastlen) eq $lastredisplay)
	{
	    print substr($line, $lastdelta);
	    ($lastlen, $lastredisplay, $lastdelta) = ($thislen, $line, $delta);
	    return;
	}

	## There is much more opportunity for optimizing.....
	## something to work on later.....
    }

    ##
    ## Brute force method of redisplaying... redraw the whole thing.
    ##

    print "\r",$line;
    print ' ' x ($lastlen - $thislen) if $lastlen > $thislen;

    print "\r",substr($line, 0, $delta)
	if $delta != length ($line) || $lastlen > $thislen;

    ($lastlen, $lastredisplay, $lastdelta) = ($thislen, $line, $delta);

    $force_redraw = 0;
}

###########################################################################
## Bindable functions... pretty much in the same order as in readline.c ###
###########################################################################

##
## Returns true if $D at the end of the line.
##
sub at_end_of_line
{
    ($D + &CharSize($D)) == (length($line) + 1);
}


##
## Move forward (right) $count characters.
##
sub F_ForwardChar
{
    local($count) = @_;
    return &F_BackwardChar(-$count) if $count < 0;

    while (!&at_end_of_line && $count-- > 0) {
	$D += &CharSize($D);
    }
}

##
## Move backward (left) $count characters.
##
sub F_BackwardChar
{
    local($count) = @_;
    return &F_ForwardChar(-$count) if $count < 0;

    while (($D > 0) && ($count-- > 0)) {
	$D--;  		           ## Move back one regardless,
	$D-- if &OnSecondByte($D); ## another if over a big char.
    }
}

##
## Go to beginning of line.
##
sub F_BeginningOfLine
{
    $D = 0;
}

##
## Move to the end of the line.
##
sub F_EndOfLine
{
    &F_ForwardChar(100) while !&at_end_of_line;
}

##
## Move to the end of this/next word.
## Done as many times as $count says.
##
sub F_ForwardWord
{
    local($count) = @_;
    return &F_BackwardWord(-$count) if $count < 0;

    while (!&at_end_of_line && $count-- > 0)
    {
	## skip forward to the next word (if not already on one)
	&F_ForwardChar(1) while !&at_end_of_line && &WordBreak($D);
	## skip forward to end of word
	&F_ForwardChar(1) while !&at_end_of_line && !&WordBreak($D);
    }
}

##
## 
## Move to the beginning of this/next word.
## Done as many times as $count says.
##
sub F_BackwardWord
{
    local($count) = @_;
    return &F_ForwardWord(-$count) if $count < 0;

    while ($D > 0 && $count-- > 0) {
	## skip backward to the next word (if not already on one)
	&F_BackwardChar(1) while (($D > 0) && &WordBreak($D-1));
	## skip backward to start of word
	&F_BackwardChar(1) while (($D > 0) && !&WordBreak($D-1));
    }
}

##
## Refresh the input line.
##
sub F_RedrawCurrentLine
{
    $force_redraw = 1;
}

##
## Clear the screen and refresh the line.
## If given a numeric arg other than 1, simply refreshes the line.
##
sub F_ClearScreen
{
    local($count) = @_;
    return &F_RedrawCurrentLine if $count != 1;

    $rl_CLEAR = `clear` if !defined($rl_CLEAR);
    print $rl_CLEAR;
    $force_redraw = 1;
}

##
## $_[1] is an ASCII ordinal; inserts as per $count.
##
sub F_SelfInsert
{
    local($count, $ord) = @_;
    local($text2add) = pack('c', $ord) x $count;
    if ($InsertMode) {
	substr($line,$D,0) .= $text2add;
    } else {
	## note: this can screw up with 2-byte characters.
	substr($line,$D,length($text2add)) = $text2add;
    }
    $D += length($text2add);
}

##
## Insert the next character read verbatim.
##
sub F_QuotedInsert
{
    local($count) = @_;
    &F_SelfInsert($count, ord(getc));
}

##
## Insert a tab.
##
sub F_TabInsert
{
    local($count) = @_;
    &F_SelfInsert($count, ord("\t"));
}

##
## Return the line as-is to the user.
##
sub F_AcceptLine
{
    ##
    ## Insert into history list if:
    ##	 * not blank
    ##   * not same as last entry
    ##
    if ($line ne '' && (!@rl_History || $rl_History[$#rl_History] ne $line)) {
	## if the history list is full, shift out an old one first....
	shift(@rl_History) while @rl_History >= $rl_MaxHistorySize;
        push(@rl_History, $line); ## tack new one on the end
    }
    $AcceptLine = $line;
    print "\r\n";
}


##
## Removes $count chars to left of cursor (if not at beginning of line).
## If $count > 1, deleted chars saved to kill buffer.
##
sub F_BackwardDeleteChar
{
    local($count) = @_;
    return F_DeleteChar(-$count) if $count < 0;
    local($oldD) = $D;
    &F_BackwardChar($count);
    return if $D == $oldD;
    &kill_text($oldD, $D, $count > 1);
}

##
## Removes the $count chars from under the cursor.
## If there is no line and the last command was different, tells
## readline to return EOF.
## If there is a line, and the cursor is at the end of it, and we're in
## tcsh completion mode, then list possible completions.
## If $count > 1, deleted chars saved to kill buffer.
##
sub F_DeleteChar
{
    local($count) = @_;
    return F_DeleteBackwardChar(-$count) if $count < 0;
    if (length($line) == 0) {
	$AcceptLine = $ReturnEOF = 1 if $lastcommand ne 'F_DeleteChar';
	return;
    }
    if ($D == length ($line))
    {
	&complete_internal('?') if $var_TcshCompleteMode;
	return;
    }
    local($oldD) = $D;
    &F_ForwardChar($count);
    return if $D == $oldD;
    &kill_text($oldD, $D, $count > 1);
}

##
## Kill to previous whitespace.
##
sub F_UnixWordRubout
{
    return &F_Ding if $D == 0;
    local($oldD, $rl_basic_word_break_characters) = ($D, "\t ");
    &F_BackwardWord(1);
    &kill_text($D, $oldD, 1);
}

##
## Kill line from cursor to beginning of line.
##
sub F_UnixLineDiscard
{
    return &F_Ding if $D == 0;
    &kill_text(0, $D, 1);
}

sub F_UpcaseWord     { &changecase($_[0], 'up');   }
sub F_DownCaseWord   { &changecase($_[0], 'down'); }
sub F_CapitalizeWord { &changecase($_[0], 'cap');  }

##
## Translated from GNUs readline.c
## One arg is 'up' to upcase $_[0] words,
##            'down' to downcase them,
##         or something else to capitolize them.
## If $_[0] is negative, the dot is not moved.
##
sub changecase
{
    local($op) = $_[1];

    local($start, $state, $c, $olddot) = ($D, 0);
    if ($_[0] < 0)
    {
	$olddot = $D;
	$_[0] = -$_[0];
    }

    &F_ForwardWord;  ## goes forward $_[0] words.

    while ($start < $D) {
	$c = substr($line, $start, 1);

	if ($op eq 'up') {
	    $c = &toupper($c);
	} elsif ($op eq 'down') {
	    $c = &tolower($c);
	} else { ## must be 'cap'
	    if ($state == 1) {
	        $c = &tolower($c);
	    } else {
	        $c = &toupper($c);
		$state = 1;
	    }
	    $state = 0 if $c !~ tr/a-zA-Z//;
	}

	substr($line, $start, 1) = $c;
	$start++;
    }
    $D = $olddot if defined($olddot);
}

sub F_TransposeWords { } ## not implemented yet

##
## Switch char at dot with char before it.
## If at the end of the line, switch the previous two...
## (NOTE: this could screw up multibyte characters.. should do correctly)
sub F_TransposeChars
{
    if ($D == length($line) && $D >= 2) {
        substr($line,$D-2,2) = substr($line,$D-1,1).substr($line,$D-2,1);
    } elsif ($D >= 1) {
	substr($line,$D-1,2) = substr($line,$D,1)  .substr($line,$D-1,1);
    } else {
	&F_Ding;
    }
}

##
## Use the previous entry in the history buffer (if there is one)
##
sub F_PreviousHistory
{
    return if $rl_HistoryIndex == 0;

    $rl_HistoryIndex--;
    ($D, $line) = (0, $rl_History[$rl_HistoryIndex]);
    &F_EndOfLine;
}

##
## Use the next entry in the history buffer (if there is one)
##
sub F_NextHistory
{
    return if $rl_HistoryIndex == @rl_History;

    $rl_HistoryIndex++;
    if ($rl_HistoryIndex == @rl_History) {
	$D = 0;
	$line = '';
    } else {
	($D, $line) = (0, $rl_History[$rl_HistoryIndex]);
	&F_EndOfLine;
    }
}

sub F_BeginningOfHistory
{
    if ($rl_HistoryIndex != 0) {
	($D, $line) = (0, $rl_History[$rl_HistoryIndex]);
	&F_EndOfLine;
    }
}

sub F_EndOfHistory
{
    if (@rl_History != 0 && $rl_HistoryIndex != $#rl_History) {
	($D, $line) = (0, $rl_History[$rl_HistoryIndex]);
	&F_EndOfLine;
    }
}

sub F_ReverseSearchHistory
{
    &DoSearch($_[0] >= 0 ? 1 : 0);
}

sub F_ForwardSearchHistory
{
    &DoSearch($_[0] >= 0 ? 0 : 1);
}

sub DoSearch
{
    local($reverse) = @_;
    local($oldline) = $line;
    local($oldD) = $D;

    local($searchstr) = '';  ## string we're searching for
    local($I) = -1;  	     ## which history line

    $si = 0;

    ## returns a new $i or -1 if not found.
    sub search { local($i, $str) = @_;
	return -1 if $i < 0 || $i > $#rl_History; ## for safety
	while (1) {
	    return $i if rindex($rl_History[$i], $str) >= 0;
	    if ($reverse) {
		return -1 if $i-- == 0;
	    } else {
		return -1 if $i++ == $#rl_History;
	    }
	}
    }

    while (1)
    {
	if ($I != -1) {
	    $line .= $rl_History[$I];
	    $D += index($rl_History[$I], $searchstr);
	}
	&redisplay( '('.($reverse?'reverse-':'') ."i-search) `$searchstr': ");

	$c = getc;
	if ($KeyMap[ord($c)] eq 'F_ReverseSearchHistory') {
	    if ($reverse && $I != -1) {
		if ($tmp = &search($I-1,$searchstr), $tmp >= 0) {
		    $I = $tmp;
		} else {
		    &F_Ding;
		}
	    }
	    $reverse = 1;
	} elsif ($KeyMap[ord($c)] eq 'F_ForwardSearchHistory') {
	    if (!$reverse && $I != -1) {
		if ($tmp = &search($I+1,$searchstr), $tmp >= 0) {
		    $I = $tmp;
		} else {
		    &F_Ding;
		}
	    }
	    $reverse = 0;
        } elsif ($c eq "\007") {  ## abort search... restore line and return
	    $line = $oldline;
	    $D = $oldD;
	    return;
        } elsif (ord($c) < 32 || ord($c) > 126) {
	    $pending = $c if $c ne "\e";
	    if ($I < 0) {
		## just restore
		$line = $oldline;
		$D = $oldD;
	    } else {
		#chose this line
		$line = $rl_History[$I];
		$D = index($rl_History[$I], $searchstr);
	    }
	    &redisplay();
	    last;
	} else {
	    ## Add this character to the end of the search string and
	    ## see if that'll match anything.
	    $tmp = &search($I < 0 ? $rl_HistoryIndex-$reverse: $I, $searchstr.$c);
	    if ($tmp == -1) {
		&F_Ding;
	    } else {
		$searchstr .= $c;
		$I = $tmp;
	    }
	}
    }
}

###########################################################################
###########################################################################

##
## Kill from cursor to end of line.
##
sub F_KillLine
{
    local($count) = @_;
    return &F_BackwardKillLine(-$count) if $count < 0;
    &kill_text($D, length($line), 1);
}

##
## Delete from cursor to beginning of line.
##
sub F_BackwardKillLine
{
    local($count) = @_;
    return &F_KillLine(-$count) if $count < 0;
    return &F_Ding if $D == 0;
    &kill_text(0, $D, 1);
}

sub F_Yank
{
    ##
    ## TextInsert(count, string)
    ##
    sub TextInsert
    {
        local($count) = @_;
	local($text2add) = $_[1] x $count;
	if ($InsertMode) {
	    substr($line,$D,0) .= $text2add;
	} else {
	    substr($line,$D,length($text2add)) = $text2add;
	}
	$D += length($text2add);
    }
    &TextInsert($_[0], $KillBuffer);
}

sub F_YankPop    { } ## not implemented yet
sub F_YankNthArg { } ## not implemented yet

##
## Kill to the end of the current word. If not on a word, kill to
## the end of the next word.
##
sub F_KillWord
{
    local($count) = @_;
    return &F_BackwardKillWord(-$count) if $count < 0;
    local($oldD) = $D;
    &F_ForwardWord;	## moves forward $count words.
    &kill_text($oldD, $D, 1);
}

##
## Kill backward to the start of the current word, or, if currently
## not on a word (or just at the start of a word), to the start of the
## previous word.
##
sub F_BackwardKillWord
{
    local($count) = @_;
    return &F_KillWord(-$count) if $count < 0;
    local($oldD) = $D;
    &F_BackwardWord;	## moves backward $count words.
    &kill_text($D, $oldD, 1);
}

sub F_ReReadInitFile
{
    local($file) = $ENV{'HOME'}."/.inputrc";
    return if !open(RC, $file);
    local(@action) = ('exec'); ## exec, skip, ignore (until appropriate endif)
    local(@level) = ();        ## if, else

    while (<RC>) {
	s/^\s*//;
	next if m/^#/;
	$InputLocMsg = " [$file line $.]";
	if (/^\$if\s+/) {
	    local($test) = $';
	    push(@level, 'if');
	    if ($action[$#action] ne 'exec') {
		## We're supposed to be skipping or ignoring this level,
		## so for subsequent levels we really ignore completely.
		push(@action, 'ignore');
	    } else {
		## We're executing this IF... do the test.
		## The test is either "term=xxxx", or just a string that
		## we compare to $rl_readline_name;
		if ($test =~ /term=([a-z0-9]+)/) {
		    $test = $1 eq $ENV{'TERM'};
		} else {
		    $test = $test =~ /^(perl|$rl_readline_name)\s*$/i;
		}
		push(@action, $test ? 'exec' : 'skip');
	    }
	    next;
	} elsif (/^\$endif\b/) {
	    die qq/\rWarning$InputLocMsg: unmatched endif\n/ if @level == 0;
	    pop(@level);
	    pop(@action);
	    next;
	} elsif (/^\$else\b/) {
	    die qq/\rWarning$InputLocMsg: unmatched else\n/ if
		@level == 0 || $level[$#level] ne 'if';
	    $level[$#level] = 'else'; ## an IF turns into an ELSE
	    if ($action[$#action] eq 'skip') {
		$action[$#action] = 'exec'; ## if were SKIPing, now EXEC
	    } else {
		$action[$#action] = 'ignore'; ## otherwise, just IGNORE.
	    }
	    next;
	} elsif ($action[$#action] ne 'exec') {
	    ## skipping this one....
	} elsif (m/\s*set\s+(\S+)\s+(\S*)\s*$/) {
	    &rl_set($1, $2, $file);
	} elsif (m/^\s*(\S+):\s+(\S+)\s*$/) {
	    &rl_bind($1, $2);
	} else {
	    chop;
	    warn "\rWarning$InputLocMsg: Bad line [$_]\n";
	}
    }
    close(RC);
    ##undef(&F_ReReadInitFile); ## you can do this if you're low on memory
}

###########################################################################
###########################################################################


##
## Abort the current input.
##
sub F_Abort
{
    &F_Ding;
}


##
## If the character that got us here is upper case,
## do the lower-case equiv...
##
sub F_DoLowercaseVersion
{
    if ($_[1] >= ord('A') && $_[1] <= ord('Z')) {
	&do_command(*KeyMap, $_[0], $_[1] - ord('A') + ord('a'));
    } else {
	&F_Ding;
    }
}

##
## Undo one level.
##
sub F_Undo
{
    pop(@undo); ## get rid of the state we just put on, so we can go back one.
    if (@undo) {
	&getstate(pop(@undo));
    } else {
	&F_Ding;
    }
}

##
## Replace the current line to some "before" state.
##
sub F_RevertLine
{
    if ($rl_HistoryIndex >= @rl_History) {
	$line = $line_for_revert;
    } else {
	$line = $rl_History[$rl_HistoryIndex];
    }
    $D = length($line);
}

sub F_EmacsEditingMode
{
    $var_EditingMode = $var_EditingMode{'emacs'};
}

sub F_ToggleEditingMode
{
    if ($var_EditingMode{$var_EditingMode} eq $var_EditingMode{'emacs'}) {
        $var_EditingMode = $var_EditingMode{'vi'};
    } else {
        $var_EditingMode = $var_EditingMode{'emacs'};
    }
}

###########################################################################
###########################################################################


##
## (Attempt to) interrupt the current program.
##
sub F_Interrupt
{
    print "\r\n";
    &ResetTTY;
    kill ("INT", 0);

    ## We're back.... must not have died.
    $force_redraw = 1;
}

##
## Execute the next character input as a command in a meta keymap.
##
sub F_PrefixMeta
{
    local($count, $keymap) = ($_[0], "$KeyMap{'name'}_$_[1]");
    ##print "F_PrefixMeta [$keymap]\n\r";
    die "<internal error, $_[1]>" if eval("!defined(%$keymap)");
    eval qq/ &do_command(*$keymap, $count, ord(getc)) /;
}

sub F_UniversalArgument
{
    &F_DigitArgument;
}

##
## For typing a numeric prefix to a command....
##
sub F_DigitArgument
{
    local($ord) = $_[1];
    local($NumericArg, $sign, $explicit) = (1, 1, 0);
    local($increment);

    do
    {
	if (defined($KeyMap[$ord]) && $KeyMap[$ord] eq 'F_UniversalArgument') {
	    $NumericArg *= 4;
	} elsif ($ord == ord('-') && !$explicit) {
	    $sign = -$sign;
	    $NumericArg = $sign;
	} elsif ($ord >= ord('0') && $ord <= ord('9')) {
	    $increment = ($ord - ord('0')) * $sign;
	    if ($explicit) {
		$NumericArg = $NumericArg * 10 + $increment;
	    } else {
		$NumericArg = $increment;
		$explicit = 1;
	    }
	} else {
	    local(*KeyMap) = $var_EditingMode;
	    &do_command(*KeyMap, $NumericArg, $ord);
	    return;
	}
	## make sure it's not toooo big.
	if ($NumericArg > $rl_max_numeric_arg) {
	    $NumericArg = $rl_max_numeric_arg;
	} elsif ($NumericArg < -$rl_max_numeric_arg) {
	    $NumericArg = -$rl_max_numeric_arg;
	}
	&redisplay(sprintf("(arg %d) ", $NumericArg));
    } while $ord = ord(getc);
}

sub F_OverwriteMode
{
    $InsertMode = 0;
}

sub F_InsertMode
{
    $InsertMode = 1;
}

##
## (Attempt to) suspend the program.
##
sub F_Suspend
{
    print "\r\n";
    &ResetTTY;
    eval qq{ kill ("TSTP", 0) };
    ## We're back....
    &SetTTY;
    $force_redraw = 1;
}

##
## Ring the bell.
## Should do something with $var_PreferVisibleBell here, but what?
##
sub F_Ding {
    print "\007";
}

##########################################################################
#### command/file completion  ############################################
##########################################################################

##
## How Command Completion Works
##
## When asked to do a completion operation, readline isolates the word
## to the immediate left of the cursor (i.e. what's just been typed).
## This information is then passed to some function (which may be supplied
## by the user of this package) which will return an array of possible
## completions.
##
## If there is just one, that one is used.  Otherwise, they are listed
## in some way (depends upon $var_TcshCompleteMode).
##
## The default is to do filename completion.  The function that performs
## this task is readline'rl_filename_list.
##
## A minimal-trouble way to have command-completion is to call
## readline'rl_basic_commands with an array of command names, such as
##    &readline'rl_basic_commands('quit', 'run', 'set', 'list')
## Those command names will then be used for completion if the word being
## completed begins the line. Otherwise, completion is disallowed.
##
## The way to have the most power is to provide a function to readline
## which will accept information about a partial word that needs completed,
## and will return the appropriate list of possibilities.
## This is done by setting $readline'rl_completion_function to the name of
## the function to run.
##
## That function will be called with three args ($text, $line, $start).
## TEXT is the partial word that should be completed.  LINE is the entire
## input line as it stands, and START is the index of the TEXT in LINE
## (i.e. zero if TEXT is at the beginning of LINE).
##
## A cool completion function will look at LINE and START and give context-
## sensitive completion lists. Consider something that will do completion
## for two commands
## 	cat FILENAME
##	finger USERNAME
##	status [this|that|other]
##
## It (untested) might look like:
##
##	$readline'rl_completion_function = "main'complete";
##	sub complete { local($text, $_, $start) = @_;
##	    ## return commands which may match if at the beginning....
##	    return grep(/^$text/, 'cat', 'finger') if $start == 0;
##	    return &rl_filename_list($text) if /^cat\b/;
##	    return &my_namelist($text) if /^finger\b/;
##	    return grep(/^text/, 'this', 'that','other') if /^status\b/;
##	    ();
##	}
## Of course, a real completion function would be more robust, but you
## get the idea (I hope).
##

##
## List possible completions
##
sub F_PossibleCompletions
{
    &complete_internal('?');
}

##
## Do a completion operation.
## If the last thing we did was a completion operation, we'll
## now list the options available (under normal emacs mode).
##
## Under TcshCompleteMode, each contiguous subsequent completion operation
## lists another of the possible options.
##
sub F_Complete
{
    if ($lastcommand eq 'F_Complete') {
	if ($var_TcshCompleteMode && @tcsh_complete_selections > 0) {
	    substr($line, $tcsh_complete_start, $tcsh_complete_len)
		= $tcsh_complete_selections[0];
	    $D -= $tcsh_complete_len;
	    $tcsh_complete_len = length($tcsh_complete_selections[0]);
	    $D += $tcsh_complete_len;
	    push(@tcsh_complete_selections, shift(@tcsh_complete_selections));
	} else {
	    &complete_internal('?');
	}
    } else {
	@tcsh_complete_selections = ();
	&complete_internal("\t");
    }
}

##
## The meat of command completion. Patterned closely after GNU's.
##
## The supposedly partial word at the cursor is "completed" as per the
## single argument:
##	"\t"	complete as much of the word as is unambiguous
##	"?"	list possibilities.
## 	"*"	replace word with all possibilities. (who would use this?)
##
## A few notable variables used:
##   $rl_completer_word_break_characters
##	-- characters in this string break a word.
##   $rl_special_prefixes
##	-- but if in this string as well, remain part of that word.
##
sub complete_internal
{
    local($what_to_do) = @_;
    local($point, $end) = ($D, $D);

    if ($point)
    {
        ## Not at the beginning of the line; Isolate the word to be completed.
	1 while (--$point && (-1 == index($rl_completer_word_break_characters,
		substr($line, $point, 1))));

	# Either at beginning of line or at a word break.
	# If at a word break (that we don't want to save), skip it.
	$point++ if (
    		(index($rl_completer_word_break_characters,
		       substr($line, $point, 1)) != -1) &&
    		(index($rl_special_prefixes, substr($line, $point, 1)) == -1)
	);
    }

    local($text) = substr($line, $point, $end - $point);
    @matches = &completion_matches($rl_completion_function,$text,$line,$point);

    if (@matches == 0) {
	&F_Ding;
    } elsif ($what_to_do eq "\t") {
	local($replacement) = shift(@matches);
	$replacement .= ' ' if @matches == 1;
	if (!$var_TcshCompleteMode) {
	    &F_Ding if @matches != 1;
	} else {
	    &F_Ding if @matches != 1;
	    @tcsh_complete_selections = (@matches, $text);
	    $tcsh_complete_start = $point;
	    $tcsh_complete_len = length($replacement);
	}
	if ($replacement ne '') {
	    substr($line, $point, $end-$point) = $replacement;
	    $D = $D - ($end - $point) + length($replacement);
	}
    } elsif ($what_to_do eq '?') {
	shift(@matches); ## remove prepended common prefix
	print "\n\r";
	# print "@matches\n\r";
	&pretty_print_list (@matches);
	$force_redraw = 1;
    } elsif ($what_to_do eq '*') {
	shift(@matches); ## remove common prefix.
	substr($line, $point, $end-$point) = "@matches"; ## insert all.
    } else {
	warn "\r\n[Internal error]";
    }
}

##
## completion_matches(func, text, line, start)
##
## FUNC is a function to call as FUNC(TEXT, LINE, START)
## 	where TEXT is the item to be completed
##	      LINE is the whole command line, and
##	      START is the starting index of TEXT in LINE.
## The FUNC should return a list of items that might match.
##
## completion_matches will return that list, with the longest common
## prefix prepended as the first item of the list.  Therefor, the list
## will either be of zero length (meaning no matches) or of 2 or more.....
##
sub completion_matches
{
    local($func, $text, $line, $start) = @_;

    ## Works with &rl_basic_commands. Return items from @rl_basic_commands
    ## that start with the pattern in $text.
    sub use_basic_commands
    {
	local($text, $line, $start) = @_;
	return () if $start != 0;
	grep(/^$text/, @rl_basic_commands);
    }

    ## get the raw list
    local(@matches);

    #print qq/\r\neval("\@matches = &$func(\$text, \$line, \$start)\n\r/;#DEBUG
    #eval("\@matches = &$func(\$text, \$line, \$start);1") || warn "$@ ";
    @matches = &$func($text, $line, $start);

    ## if anything returned , find the common prefix among them
    if (@matches) {
	local($prefix) = $matches[0];
	local($len) = length($prefix);
	for ($i = 1; $i < @matches; $i++) {
	    next if substr($matches[$i], 0, $len) eq $prefix;
	    $prefix = substr($prefix, 0, --$len);
	    last if $len == 0;
	    $i--; ## retry this one to see if the shorter one matches.
	}
	unshift(@matches, $prefix); ## make common prefix the first thing.
    }
    @matches;
}

##
## For use in passing to completion_matches(), returns a list of
## filenames that begin with the given pattern.  The user of this package
## can set $rl_completion_function to 'rl_filename_list' to restore the
## default of filename matching if they'd changed it earlier, either
## directly or via &rl_basic_commands.
##
sub rl_filename_list
{
    local($pattern) = $_[0];
    local(@files) = (<$pattern*>);
    if ($var_CompleteAddsuffix) {
	foreach (@files) {
	    if (-l $_) {
		$_ .= '@';
	    } elsif (-d _) {
		$_ .= '/';
	    } elsif (-x _) {
		$_ .= '*';
	    } elsif (-S _ || -p _) {
		$_ .= '=';
	    }
	}
    }
    return @files;
}

##
## For use by the user of the package. Called with a list of possible
## commands, will allow command completion on those commands, but only
## for the first word on a line.
## For example: &rl_basic_commands('set', 'quit', 'type', 'run');
##
## This is for people that want quick and simple command completion.
## A more thoughtful implementation would set $rl_completion_function
## to a routine that would look at the context of the word being completed
## and return the appropriate possibilities.
##
sub rl_basic_commands
{
     @rl_basic_commands = @_;
     $rl_completion_function = 'use_basic_commands';
}

##
## Print an array in columns like ls -C.  Originally based on stuff
## (lsC2.pl) by utashiro@sran230.sra.co.jp (Kazumasa Utashiro).
##
sub pretty_print_list
{
    local (@list) = @_;
    return unless @list;
    local ($lines, $columns, $mark, $index);

    ## find width of widest entry
    local($maxwidth) = 0;
    grep(length > $maxwidth && ($maxwidth = length), @list);
    $maxwidth++;

    $columns = $maxwidth >= $rl_screen_width
	       ? 1 : int($rl_screen_width / $maxwidth);

    ## if there's enough margin to interspurse among the columsn, do so.
    $maxwidth += int(($rl_screen_width % $maxwidth) / $columns);

    $lines = int((@list + $columns - 1) / $columns);
    $columns-- while ((($lines * $columns) - @list + 1) > $lines);

    $mark = $#list - $lines;
    for ($l = 0; $l < $lines; $l++) {
	for ($index = $l; $index <= $mark; $index += $lines) {
	    printf("%-${maxwidth}s", $list[$index]);
	}
   	print $list[$index] if $index <= $#list;
	print "\n\r";
    }
}

1;
__END__
