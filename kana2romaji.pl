##
## Jeffrey Friedl (jfriedl@omron.co.jp)
## Copyri.... ah hell, just take it.
##
## Prettied up October 94.
##
package kana2romaji;
$version = "941005.02";

##
## BLURB:
##   &kana2romaji'convert -- convert EUC kana to romaji
##
##>
##
##  $romaji = &kana2romaji'convert($kana);
##
##  Converts the given kana (encoded in EUC) to romaji.
##  Return undef if there is an error.
##
##<
##

$katakana_dash = "\241\274";          ## '¡¼'
$small_tsu = '[\244\245]\303';        ## regex to match '¥Ã' or '¤Ã'
#$kana_char = '[\244\245][\x81-\xf6]'; ## regex to match a kana character.
$euc_char = '[\x80-\xff][\x80-\xff]'; ## regex to match an EUC character

sub kana2romaji
{
    &convert;
}

sub convert
{
    local($kana) = @_;
    local($romaji) = '';
    local($try, $new);

    MAINLOOP: while (length $kana)
    {
	##
	## If there is some prepended ASCII, just pass to the romaji.
	##
	if ($kana =~ s/^([\x00-\x7f]+)//) {
	    $romaji .= $1;
	    last unless length $kana; ## quick abort if we're done.
	}

	##
	## If the kana begins with a dash, just replicate the
	## final character of the romaji.
	##
	if (length($romaji) && $kana =~ s/^($katakana_dash)+//o) {
	    $romaji =~ s/(.)$/$1$1/;
	    next;
	}

	##
	## If the next character is a small TSU, note that the character
	## following it will have to have its romaji preceeded by a voiced
	## stop (replicating the first character of the romaji).
	##
	$voiced_stop = ($kana =~ s/^($small_tsu)+//o);

	##
	## The longest bit of kana we'll ever check against the transliteration
	## tables would be three characters, so grab at most three for
	## checking:
	##
        unless ($kana =~ s/^(($euc_char){1,3})//o) {
	    ##
	    ## At this point, we couldn't translate the first character....
	    ## Just pass it through to $romaji.
	    ##
	    $kana =~ s/([\x00-\x7f]|[\x80-\xff].)//;
	    $romaji .= $1;
	} else {
	    ($try) = $1;

	    while (length $try)
	    {
		if (defined($new = $tr{$try})) {
		    ## found the transliteration
		    $romaji .= substr($new, 0, 1) if $voiced_stop;
		    $romaji .="'" if $romaji =~ m/n$/ && $new =~ m/^[aiueoy]/;
		    $romaji .= $new;
		    next MAINLOOP;
		}

	        last if length($try) <= 2;
		$try =~ s/(..)$//;  ## nab last char of $try....
		$kana= "$1$kana";   ## ... and prepend back to $kana
	    }

	    ##
	    ## At this point, we couldn't translate $try.
	    ## Just pass it through to $romaji.
	    ##
	    $romaji .= $try;
	}
    }
    $romaji =~ s/^\s+//;  ## make sure no leading or
    $romaji =~ s/\s+$//;  ##   trailing spaces.
    return $romaji;
}


##
## Transliteration table.
## $tr{$kana} = $romaji;
##
%tr = (
	 "\xa4\xa2", 'a',                                    # ¤¢
	 "\xa4\xa4", 'i',                                    # ¤¤
	 "\xa4\xa6", 'u',                                    # ¤¦
	 "\xa4\xa8", 'e',                                    # ¤¨
	 "\xa4\xaa", 'o',                                    # ¤ª

	 "\xa4\xab", 'ka',             "\xa4\xac", 'ga',     # ¤«, ¤¬
	 "\xa4\xad", 'ki',             "\xa4\xae", 'gi',     # ¤­, ¤®
	 "\xa4\xaf", 'ku',             "\xa4\xb0", 'gu',     # ¤¯, ¤°
	 "\xa4\xb1", 'ke',             "\xa4\xb2", 'ge',     # ¤±, ¤²
	 "\xa4\xb3", 'ko',             "\xa4\xb4", 'go',     # ¤³, ¤´


 "\xa4\xad\xa4\xe3", 'kya',    "\xa4\xae\xa4\xe3", 'gya',    # ¤­¤ã, ¤®¤ã
 "\xa4\xad\xa4\xe5", 'kyu',    "\xa4\xae\xa4\xe5", 'gyu',    # ¤­¤å, ¤®¤å
 "\xa4\xad\xa4\xe7", 'kyo',    "\xa4\xae\xa4\xe7", 'gyo',    # ¤­¤ç, ¤®¤ç


 "\xa4\xaf\xa4\xa1", 'kwa',                                  # ¤¯¤¡
 "\xa4\xaf\xa4\xa9", 'kwo',                                  # ¤¯¤©

	 "\xa4\xb5", 'sa',             "\xa4\xb6", 'za',     # ¤µ, ¤¶
	 "\xa4\xb7", 'shi',            "\xa4\xb8", 'ji',     # ¤·, ¤¸
	 "\xa4\xb9", 'su',             "\xa4\xba", 'zu',     # ¤¹, ¤º
	 "\xa4\xbb", 'se',             "\xa4\xbc", 'ze',     # ¤», ¤¼
	 "\xa4\xbd", 'so',             "\xa4\xbe", 'zo',     # ¤½, ¤¾


 "\xa4\xb7\xa4\xe3", 'sha',    "\xa4\xb8\xa4\xe3", 'ja',     # ¤·¤ã, ¤¸¤ã
 "\xa4\xb7\xa4\xe5", 'shu',    "\xa4\xb8\xa4\xe5", 'ju',     # ¤·¤å, ¤¸¤å
 "\xa4\xb7\xa4\xa7", 'she',    "\xa4\xb8\xa4\xa7", 'je',     # ¤·¤§, ¤¸¤§
 "\xa4\xb7\xa4\xe7", 'sho',    "\xa4\xb8\xa4\xe7", 'jo',     # ¤·¤ç, ¤¸¤ç

 "\xa4\xb9\xa4\xa7", 'suwe',                                 # ¤¹¤§

	 "\xa4\xbf", 'ta',             "\xa4\xc0", 'da',     # ¤¿, ¤À
	 "\xa4\xc1", 'chi',            "\xa4\xc2", 'ji',     # ¤Á, ¤Â
	 "\xa4\xc4", 'tsu',            "\xa4\xc5", 'dzu',    # ¤Ä, ¤Å
	 "\xa4\xc6", 'te',             "\xa4\xc7", 'de',     # ¤Æ, ¤Ç
	 "\xa4\xc8", 'to',             "\xa4\xc9", 'do',     # ¤È, ¤É

 "\xa4\xc1\xa4\xe3", 'cha',                                  # ¤Á¤ã
 "\xa4\xc1\xa4\xe5", 'chu',                                  # ¤Á¤å
 "\xa4\xc1\xa4\xa7", 'che',                                  # ¤Á¤§
 "\xa4\xc1\xa4\xe7", 'cho',    "\xa4\xc2\xa4\xe7", 'jyo',    # ¤Á¤ç, ¤Â¤ç

 "\xa4\xc4\xa4\xa1", 'tsa',                                  # ¤Ä¤¡
 "\xa4\xc6\xa4\xa3", 'ti',     "\xa4\xc7\xa4\xa3", 'di',     # ¤Æ¤£, ¤Ç¤£

	 "\xa4\xca", 'na',                                   # ¤Ê
	 "\xa4\xcb", 'ni',                                   # ¤Ë
	 "\xa4\xcc", 'nu',                                   # ¤Ì
	 "\xa4\xcd", 'ne',                                   # ¤Í
	 "\xa4\xce", 'no',                                   # ¤Î
 "\xa4\xcb\xa4\xe3", 'nya',                                  # ¤Ë¤ã
 "\xa4\xcb\xa4\xe5", 'nyu',                                  # ¤Ë¤å
 "\xa4\xcb\xa4\xe7", 'nyo',                                  # ¤Ë¤ç

     "\xa4\xcf", 'ha',     "\xa4\xd0", 'ba',   "\xa4\xd1",'pa', # ¤Ï, ¤Ð, ¤Ñ
     "\xa4\xd2", 'hi',     "\xa4\xd3", 'bi',   "\xa4\xd4",'pi', # ¤Ò, ¤Ó, ¤Ô
     "\xa4\xd5", 'fu',     "\xa4\xd6", 'bu',   "\xa4\xd7",'pu', # ¤Õ, ¤Ö, ¤×
     "\xa4\xd8", 'he',     "\xa4\xd9", 'be',   "\xa4\xda",'pe', # ¤Ø, ¤Ù, ¤Ú
     "\xa4\xdb", 'ho',     "\xa4\xdc", 'bo',   "\xa4\xdd",'po', # ¤Û, ¤Ü, ¤Ý

  #¤Ò¤ã,¤Ó¤ã,¤Ô¤ã
  "\xa4\xd2\xa4\xe3",'hya',"\xa4\xd3\xa4\xe3",'bya',"\xa4\xd4\xa4\xe3",'pya',

  #¤Ò¤å,¤Ó¤å,¤Ô¤å
  "\xa4\xd2\xa4\xe5",'hyu',"\xa4\xd3\xa4\xe5",'byu',"\xa4\xd4\xa4\xe5",'pyu',

  #¤Ò¤ç,¤Ó¤ç,¤Ô¤ç
  "\xa4\xd2\xa4\xe7",'hyo',"\xa4\xd3\xa4\xe7",'byo',"\xa4\xd4\xa4\xe7",'pyo',

 "\xa4\xd5\xa4\xa1", 'fa',                                   # ¤Õ¤¡
 "\xa4\xd5\xa4\xa3", 'fi',                                   # ¤Õ¤£
 "\xa4\xd5\xa4\xa7", 'fe',                                   # ¤Õ¤§
 "\xa4\xd5\xa4\xa9", 'fo',                                   # ¤Õ¤©

	 "\xa4\xde", 'ma',                                   # ¤Þ
	 "\xa4\xdf", 'mi',                                   # ¤ß
	 "\xa4\xe0", 'mu',                                   # ¤à
	 "\xa4\xe1", 'me',                                   # ¤á
	 "\xa4\xe2", 'mo',                                   # ¤â

 "\xa4\xdf\xa4\xe3", 'mya',                                  # ¤ß¤ã
 "\xa4\xdf\xa4\xe5", 'myu',                                  # ¤ß¤å
 "\xa4\xdf\xa4\xe7", 'myo',                                  # ¤ß¤ç

	 "\xa4\xe4", 'ya',                                   # ¤ä
	 "\xa4\xe6", 'yu',                                   # ¤æ
	 "\xa4\xe8", 'yo',                                   # ¤è

	 "\xa4\xe9", 'ra',                                   # ¤é
	 "\xa4\xea", 'ri',                                   # ¤ê
	 "\xa4\xeb", 'ru',                                   # ¤ë
	 "\xa4\xec", 're',                                   # ¤ì
	 "\xa4\xed", 'ro',                                   # ¤í

 "\xa4\xea\xa4\xa7", 'rye',                                  # ¤ê¤§
 "\xa4\xea\xa4\xe3", 'rya',                                  # ¤ê¤ã
 "\xa4\xea\xa4\xe5", 'ryu',                                  # ¤ê¤å
 "\xa4\xea\xa4\xe7", 'ryo',                                  # ¤ê¤ç

	 "\xa4\xef", 'wa',                                   # ¤ï
	 "\xa4\xf2", 'wo',                                   # ¤ò
	 "\xa4\xf3", 'n',                                    # ¤ó

	 "\xa4\xf0", 'wi',                                   # ¤ð
	 "\xa4\xf1", 'we',                                   # ¤ñ
	 "\xa5\xf1", 'e',                                    # ¥ñ

 "\xa4\xa4\xa4\xa7", 'ixe',                                  # ¤¤¤§
 "\xa4\xa6\xa4\xa3", 'wi',                                   # ¤¦¤£
 "\xa4\xa6\xa4\xa7", 'we',                                   # ¤¦¤§
 "\xa5\xa6\xa5\xa9", 'wo',                                   # ¥¦¥©
	 "\xa5\xf4", 'vu',                                   # ¥ô

							     # ¥ô¥¡
 "\xa5\xf4\xa5\xa3", 'vi',                                   # ¥ô¥£
 "\xa5\xf4\xa5\xa7", 've',                                   # ¥ô¥§
 "\xa5\xf4\xa5\xa9", 'vo',                                   # ¥ô¥©
 "\xa5\xf4\xa5\xe5", 'vyu',                                  # ¥ô¥å

	 "\xa4\xa1", 'xa',                                   # ¤¡
	 "\xa4\xa3", 'xi',                                   # ¤£
	 "\xa4\xa5", 'xu',                                   # ¤¥
	 "\xa4\xa7", 'xe',                                   # ¤§
	 "\xa4\xa9", 'xo',                                   # ¤©
	 "\xa4\xe3", 'xya',                                  # ¤ã
	 "\xa4\xe5", 'xyu',                                  # ¤å
	 "\xa4\xe7", 'xyo',                                  # ¤ç
	 "\xa4\xee", 'xwa',                                  # ¤î
	 "\xa5\xf6", 'xke',                                  # ¥ö
	 "\xa5\xf5", 'xka',                                  # ¥õ


	 "\xa1\xb9", ' kanjinoodoriji ',                     # ¡¹
	 "\xa1\xf5", ' anddo ',                              # ¡õ
	 "\xa6\xc2", ' beta ',                               # ¦Â

	 "\xa3\xb0", ' zero ',                               # £°
	 "\xa3\xb1", ' uan ',                                # £±
	 "\xa3\xb2", ' tuu ',                                # £²
	 "\xa3\xb3", ' turii ',                              # £³
	 "\xa3\xb4", ' foaa ',                               # £´
	 "\xa3\xb5", ' faibu ',                              # £µ
	 "\xa3\xb6", ' shikusu ',                            # £¶
	 "\xa3\xb7", ' sebin ',                              # £·
	 "\xa3\xb8", ' eito ',                               # £¸
	 "\xa3\xb9", ' nainu ',                              # £¹

	 "\xa3\xc1", ' ee ',                                 # £Á
	 "\xa3\xe1", ' ee ',                                 # £á
	 "\xa3\xc2", ' bii ',                                # £Â
	 "\xa3\xe2", ' bii ',                                # £â
	 "\xa3\xc3", ' shii ',                               # £Ã
	 "\xa3\xe3", ' shii ',                               # £ã
	 "\xa3\xc4", ' di  ',                                # £Ä
	 "\xa3\xe4", ' di  ',                                # £ä
	 "\xa3\xc5", ' ii ',                                 # £Å
	 "\xa3\xe5", ' ii ',                                 # £å
	 "\xa3\xc6", ' efu ',                                # £Æ
	 "\xa3\xe6", ' efu ',                                # £æ
	 "\xa3\xc7", ' ji ',                                 # £Ç
	 "\xa3\xe7", ' ji ',                                 # £ç
	 "\xa3\xc8", ' echi ',                               # £È
	 "\xa3\xe8", ' echi ',                               # £è
	 "\xa3\xc9", ' ai ',                                 # £É
	 "\xa3\xe9", ' ai ',                                 # £é
	 "\xa3\xca", ' jei ',                                # £Ê
	 "\xa3\xea", ' jei ',                                # £ê
	 "\xa3\xcb", ' kei ',                                # £Ë
	 "\xa3\xeb", ' kei ',                                # £ë
	 "\xa3\xcc", ' eru ',                                # £Ì
	 "\xa3\xec", ' eru ',                                # £ì
	 "\xa3\xcd", ' emu ',                                # £Í
	 "\xa3\xed", ' emu ',                                # £í
	 "\xa3\xce", ' en ',                                 # £Î
	 "\xa3\xee", ' en ',                                 # £î
	 "\xa3\xcf", ' oo ',                                 # £Ï
	 "\xa3\xef", ' oo ',                                 # £ï
	 "\xa3\xd0", ' pii ',                                # £Ð
	 "\xa3\xf0", ' pii ',                                # £ð
	 "\xa3\xd1", ' kyuu ',                               # £Ñ
	 "\xa3\xf1", ' kyuu ',                               # £ñ
	 "\xa3\xd2", ' aru ',                                # £Ò
	 "\xa3\xf2", ' aru ',                                # £ò
	 "\xa3\xd3", ' esu ',                                # £Ó
	 "\xa3\xf3", ' esu ',                                # £ó
	 "\xa3\xd4", ' tii ',                                # £Ô
	 "\xa3\xf4", ' tii ',                                # £ô
	 "\xa3\xd5", ' iuu ',                                # £Õ
	 "\xa3\xf5", ' iuu ',                                # £õ
	 "\xa3\xd6", ' vi ',                                 # £Ö
	 "\xa3\xf6", ' vi ',                                 # £ö
	 "\xa3\xd7", ' daburu ',                             # £×
	 "\xa3\xf7", ' daburu ',                             # £÷
	 "\xa3\xd8", ' ekusu ',                              # £Ø
	 "\xa3\xf8", ' ekusu ',                              # £ø
	 "\xa3\xd9", ' uai ',                                # £Ù
	 "\xa3\xf9", ' uai ',                                # £ù
	 "\xa3\xda", ' zedo ',                               # £Ú
	 "\xa3\xfa", ' zedo ',                               # £ú
);

##init
{
    local ($key, @chars, $kata);

    ## replicate to a katakana version
    foreach $key (keys(%tr)) {
	@chars = $key =~ m/(..)/g;       ## Break out indiviual characters.
	grep(s/^\xa4/\xa5/,  @chars);    ## Change any hiragana to katakana.
	$kata = join('', @chars);                ## put back together.
	$tr{$kata} = $tr{$key} if $kata ne $key; ## set katakana->romaji reln
    }
}

1;


__END__
