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

$katakana_dash = "\241\274";          ## '��'
$small_tsu = '[\244\245]\303';        ## regex to match '��' or '��'
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
	 "\xa4\xa2", 'a',                                    # ��
	 "\xa4\xa4", 'i',                                    # ��
	 "\xa4\xa6", 'u',                                    # ��
	 "\xa4\xa8", 'e',                                    # ��
	 "\xa4\xaa", 'o',                                    # ��

	 "\xa4\xab", 'ka',             "\xa4\xac", 'ga',     # ��, ��
	 "\xa4\xad", 'ki',             "\xa4\xae", 'gi',     # ��, ��
	 "\xa4\xaf", 'ku',             "\xa4\xb0", 'gu',     # ��, ��
	 "\xa4\xb1", 'ke',             "\xa4\xb2", 'ge',     # ��, ��
	 "\xa4\xb3", 'ko',             "\xa4\xb4", 'go',     # ��, ��


 "\xa4\xad\xa4\xe3", 'kya',    "\xa4\xae\xa4\xe3", 'gya',    # ����, ����
 "\xa4\xad\xa4\xe5", 'kyu',    "\xa4\xae\xa4\xe5", 'gyu',    # ����, ����
 "\xa4\xad\xa4\xe7", 'kyo',    "\xa4\xae\xa4\xe7", 'gyo',    # ����, ����


 "\xa4\xaf\xa4\xa1", 'kwa',                                  # ����
 "\xa4\xaf\xa4\xa9", 'kwo',                                  # ����

	 "\xa4\xb5", 'sa',             "\xa4\xb6", 'za',     # ��, ��
	 "\xa4\xb7", 'shi',            "\xa4\xb8", 'ji',     # ��, ��
	 "\xa4\xb9", 'su',             "\xa4\xba", 'zu',     # ��, ��
	 "\xa4\xbb", 'se',             "\xa4\xbc", 'ze',     # ��, ��
	 "\xa4\xbd", 'so',             "\xa4\xbe", 'zo',     # ��, ��


 "\xa4\xb7\xa4\xe3", 'sha',    "\xa4\xb8\xa4\xe3", 'ja',     # ����, ����
 "\xa4\xb7\xa4\xe5", 'shu',    "\xa4\xb8\xa4\xe5", 'ju',     # ����, ����
 "\xa4\xb7\xa4\xa7", 'she',    "\xa4\xb8\xa4\xa7", 'je',     # ����, ����
 "\xa4\xb7\xa4\xe7", 'sho',    "\xa4\xb8\xa4\xe7", 'jo',     # ����, ����

 "\xa4\xb9\xa4\xa7", 'suwe',                                 # ����

	 "\xa4\xbf", 'ta',             "\xa4\xc0", 'da',     # ��, ��
	 "\xa4\xc1", 'chi',            "\xa4\xc2", 'ji',     # ��, ��
	 "\xa4\xc4", 'tsu',            "\xa4\xc5", 'dzu',    # ��, ��
	 "\xa4\xc6", 'te',             "\xa4\xc7", 'de',     # ��, ��
	 "\xa4\xc8", 'to',             "\xa4\xc9", 'do',     # ��, ��

 "\xa4\xc1\xa4\xe3", 'cha',                                  # ����
 "\xa4\xc1\xa4\xe5", 'chu',                                  # ����
 "\xa4\xc1\xa4\xa7", 'che',                                  # ����
 "\xa4\xc1\xa4\xe7", 'cho',    "\xa4\xc2\xa4\xe7", 'jyo',    # ����, �¤�

 "\xa4\xc4\xa4\xa1", 'tsa',                                  # �Ĥ�
 "\xa4\xc6\xa4\xa3", 'ti',     "\xa4\xc7\xa4\xa3", 'di',     # �Ƥ�, �Ǥ�

	 "\xa4\xca", 'na',                                   # ��
	 "\xa4\xcb", 'ni',                                   # ��
	 "\xa4\xcc", 'nu',                                   # ��
	 "\xa4\xcd", 'ne',                                   # ��
	 "\xa4\xce", 'no',                                   # ��
 "\xa4\xcb\xa4\xe3", 'nya',                                  # �ˤ�
 "\xa4\xcb\xa4\xe5", 'nyu',                                  # �ˤ�
 "\xa4\xcb\xa4\xe7", 'nyo',                                  # �ˤ�

     "\xa4\xcf", 'ha',     "\xa4\xd0", 'ba',   "\xa4\xd1",'pa', # ��, ��, ��
     "\xa4\xd2", 'hi',     "\xa4\xd3", 'bi',   "\xa4\xd4",'pi', # ��, ��, ��
     "\xa4\xd5", 'fu',     "\xa4\xd6", 'bu',   "\xa4\xd7",'pu', # ��, ��, ��
     "\xa4\xd8", 'he',     "\xa4\xd9", 'be',   "\xa4\xda",'pe', # ��, ��, ��
     "\xa4\xdb", 'ho',     "\xa4\xdc", 'bo',   "\xa4\xdd",'po', # ��, ��, ��

  #�Ҥ�,�Ӥ�,�Ԥ�
  "\xa4\xd2\xa4\xe3",'hya',"\xa4\xd3\xa4\xe3",'bya',"\xa4\xd4\xa4\xe3",'pya',

  #�Ҥ�,�Ӥ�,�Ԥ�
  "\xa4\xd2\xa4\xe5",'hyu',"\xa4\xd3\xa4\xe5",'byu',"\xa4\xd4\xa4\xe5",'pyu',

  #�Ҥ�,�Ӥ�,�Ԥ�
  "\xa4\xd2\xa4\xe7",'hyo',"\xa4\xd3\xa4\xe7",'byo',"\xa4\xd4\xa4\xe7",'pyo',

 "\xa4\xd5\xa4\xa1", 'fa',                                   # �դ�
 "\xa4\xd5\xa4\xa3", 'fi',                                   # �դ�
 "\xa4\xd5\xa4\xa7", 'fe',                                   # �դ�
 "\xa4\xd5\xa4\xa9", 'fo',                                   # �դ�

	 "\xa4\xde", 'ma',                                   # ��
	 "\xa4\xdf", 'mi',                                   # ��
	 "\xa4\xe0", 'mu',                                   # ��
	 "\xa4\xe1", 'me',                                   # ��
	 "\xa4\xe2", 'mo',                                   # ��

 "\xa4\xdf\xa4\xe3", 'mya',                                  # �ߤ�
 "\xa4\xdf\xa4\xe5", 'myu',                                  # �ߤ�
 "\xa4\xdf\xa4\xe7", 'myo',                                  # �ߤ�

	 "\xa4\xe4", 'ya',                                   # ��
	 "\xa4\xe6", 'yu',                                   # ��
	 "\xa4\xe8", 'yo',                                   # ��

	 "\xa4\xe9", 'ra',                                   # ��
	 "\xa4\xea", 'ri',                                   # ��
	 "\xa4\xeb", 'ru',                                   # ��
	 "\xa4\xec", 're',                                   # ��
	 "\xa4\xed", 'ro',                                   # ��

 "\xa4\xea\xa4\xa7", 'rye',                                  # �ꤧ
 "\xa4\xea\xa4\xe3", 'rya',                                  # ���
 "\xa4\xea\xa4\xe5", 'ryu',                                  # ���
 "\xa4\xea\xa4\xe7", 'ryo',                                  # ���

	 "\xa4\xef", 'wa',                                   # ��
	 "\xa4\xf2", 'wo',                                   # ��
	 "\xa4\xf3", 'n',                                    # ��

	 "\xa4\xf0", 'wi',                                   # ��
	 "\xa4\xf1", 'we',                                   # ��
	 "\xa5\xf1", 'e',                                    # ��

 "\xa4\xa4\xa4\xa7", 'ixe',                                  # ����
 "\xa4\xa6\xa4\xa3", 'wi',                                   # ����
 "\xa4\xa6\xa4\xa7", 'we',                                   # ����
 "\xa5\xa6\xa5\xa9", 'wo',                                   # ����
	 "\xa5\xf4", 'vu',                                   # ��

							     # ����
 "\xa5\xf4\xa5\xa3", 'vi',                                   # ����
 "\xa5\xf4\xa5\xa7", 've',                                   # ����
 "\xa5\xf4\xa5\xa9", 'vo',                                   # ����
 "\xa5\xf4\xa5\xe5", 'vyu',                                  # ����

	 "\xa4\xa1", 'xa',                                   # ��
	 "\xa4\xa3", 'xi',                                   # ��
	 "\xa4\xa5", 'xu',                                   # ��
	 "\xa4\xa7", 'xe',                                   # ��
	 "\xa4\xa9", 'xo',                                   # ��
	 "\xa4\xe3", 'xya',                                  # ��
	 "\xa4\xe5", 'xyu',                                  # ��
	 "\xa4\xe7", 'xyo',                                  # ��
	 "\xa4\xee", 'xwa',                                  # ��
	 "\xa5\xf6", 'xke',                                  # ��
	 "\xa5\xf5", 'xka',                                  # ��


	 "\xa1\xb9", ' kanjinoodoriji ',                     # ��
	 "\xa1\xf5", ' anddo ',                              # ��
	 "\xa6\xc2", ' beta ',                               # ��

	 "\xa3\xb0", ' zero ',                               # ��
	 "\xa3\xb1", ' uan ',                                # ��
	 "\xa3\xb2", ' tuu ',                                # ��
	 "\xa3\xb3", ' turii ',                              # ��
	 "\xa3\xb4", ' foaa ',                               # ��
	 "\xa3\xb5", ' faibu ',                              # ��
	 "\xa3\xb6", ' shikusu ',                            # ��
	 "\xa3\xb7", ' sebin ',                              # ��
	 "\xa3\xb8", ' eito ',                               # ��
	 "\xa3\xb9", ' nainu ',                              # ��

	 "\xa3\xc1", ' ee ',                                 # ��
	 "\xa3\xe1", ' ee ',                                 # ��
	 "\xa3\xc2", ' bii ',                                # ��
	 "\xa3\xe2", ' bii ',                                # ��
	 "\xa3\xc3", ' shii ',                               # ��
	 "\xa3\xe3", ' shii ',                               # ��
	 "\xa3\xc4", ' di  ',                                # ��
	 "\xa3\xe4", ' di  ',                                # ��
	 "\xa3\xc5", ' ii ',                                 # ��
	 "\xa3\xe5", ' ii ',                                 # ��
	 "\xa3\xc6", ' efu ',                                # ��
	 "\xa3\xe6", ' efu ',                                # ��
	 "\xa3\xc7", ' ji ',                                 # ��
	 "\xa3\xe7", ' ji ',                                 # ��
	 "\xa3\xc8", ' echi ',                               # ��
	 "\xa3\xe8", ' echi ',                               # ��
	 "\xa3\xc9", ' ai ',                                 # ��
	 "\xa3\xe9", ' ai ',                                 # ��
	 "\xa3\xca", ' jei ',                                # ��
	 "\xa3\xea", ' jei ',                                # ��
	 "\xa3\xcb", ' kei ',                                # ��
	 "\xa3\xeb", ' kei ',                                # ��
	 "\xa3\xcc", ' eru ',                                # ��
	 "\xa3\xec", ' eru ',                                # ��
	 "\xa3\xcd", ' emu ',                                # ��
	 "\xa3\xed", ' emu ',                                # ��
	 "\xa3\xce", ' en ',                                 # ��
	 "\xa3\xee", ' en ',                                 # ��
	 "\xa3\xcf", ' oo ',                                 # ��
	 "\xa3\xef", ' oo ',                                 # ��
	 "\xa3\xd0", ' pii ',                                # ��
	 "\xa3\xf0", ' pii ',                                # ��
	 "\xa3\xd1", ' kyuu ',                               # ��
	 "\xa3\xf1", ' kyuu ',                               # ��
	 "\xa3\xd2", ' aru ',                                # ��
	 "\xa3\xf2", ' aru ',                                # ��
	 "\xa3\xd3", ' esu ',                                # ��
	 "\xa3\xf3", ' esu ',                                # ��
	 "\xa3\xd4", ' tii ',                                # ��
	 "\xa3\xf4", ' tii ',                                # ��
	 "\xa3\xd5", ' iuu ',                                # ��
	 "\xa3\xf5", ' iuu ',                                # ��
	 "\xa3\xd6", ' vi ',                                 # ��
	 "\xa3\xf6", ' vi ',                                 # ��
	 "\xa3\xd7", ' daburu ',                             # ��
	 "\xa3\xf7", ' daburu ',                             # ��
	 "\xa3\xd8", ' ekusu ',                              # ��
	 "\xa3\xf8", ' ekusu ',                              # ��
	 "\xa3\xd9", ' uai ',                                # ��
	 "\xa3\xf9", ' uai ',                                # ��
	 "\xa3\xda", ' zedo ',                               # ��
	 "\xa3\xfa", ' zedo ',                               # ��
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
