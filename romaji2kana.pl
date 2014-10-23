##
## Jeffrey Friedl (jfriedl@omron.co.jp)
## Copyri.... ah hell, just take it.
## Omron Corporation,  9/92
##
package romaji2kana;
$version = "960420.07";
##
## "960420.07"
##   Hadn't properly dealt with 1- and 2-letter upper-case romaji. Big "oops!".
## 
## "941028.05";
##   Slight mods to quiet perl5 warnings.
##
## "941006.04";

##
## BLURB:
## &romaji2kana'convert -- convert romaji to EUC kana.
##
##>
## ($kana, $error) = &romaji2kana'convert($romaji);
##
## Input: one string of romaji text.
## Returns: ($text, $error)
##
## $text is $romaji with romaji replaced by EUC kana:
##   * lower-case romaji converted to hiragana
##
##   * upper-case romaji converted to katakana
##
##   * non-ASCII are left as-is.
##
##   * ASCII characters listed in $romaji2kana'pass are left as-is
##     (default setting is "\t ")
##
##   * ASCII characters listed in $romaji2kana'omit are quietly omitted.
##     (default setting is "'"). The ' can be used to differentiate
##	"kenichi" (KE NI CHI) from "ken'ichi" (KE N I CHI).
##
##   * ASCII characters listed in $romaji2kana'longvowel are used to
##     creat a long vowel, such as in 'bi-ru' or 'o^saka'.
##     (default setting is "-^");
##
##   * All other characters are left as-is, but also put to $error.
##     Therefore, if $error is undefined, all characters in $romaji were
##     properly accounted for.
##<
##


$pass = "\t ";		## ASCII which should be passed to the kana
$omit = "'";		## ASCII which should be ignored
$longvowel = "-^";	## long-vowel indicator

######

$dash = "\241\274";  	  # ��
$small_TU = "\245\303";   # ��
$small_tu = "\244\303";   # ��


sub convert
{
    local($romaji) = @_;
    local($kana, $bite, $lastromaji, $newkana, $error) = ('','','','', '');

    while (length $romaji)
    {
	## Pass through any EUC or $pass characters.
	$kana .= $1 if $romaji =~ s/^([\x80-\xff]+|[$pass])//;

	## If told to omit such-and-such, to do.
	$romaji =~ s/^[$omit]+// if length $omit;

	##
	## If we have a longvowel marker, add either a dash or the appropriate
	## vowel sound. The latter is accomplished by repeating the end of the
	## last romaji.
	##
	if ($romaji =~ s/^[$longvowel]+//) {
	    if ($katakana) {
		$kana .= $dash;
	    } else {
		$romaji = chop($lastromaji) . $romaji;
	    }
	}

	##
	## If the next non-vowel is repeated, take off all but the last
	## one and add an appropriate small TSU.
	##
	if ($romaji =~ s/^([^aiueo])\1/$1/i) {
	    $kana .= $katakana ? $small_TU : $small_tu;
	    next;
	}

	##
	## Grab a bite of up to three same-case letters.
	##
	if ($romaji =~ s/^([a-z]{1,3})|([A-Z]{1,3})//)
	{
	    if ($2) {
		$origbite = $2;
		$bite = "\L$2"; ## put to lower case
		$katakana = 1;
	    } else {
		$origbite = $1;
	        $bite = $1;
		$katakana = 0;
	    }

	    $newkana = undef;
	    if (length($bite) == 3) {
		if (defined $three{$bite}) {
		    $newkana = $three{$lastromaji = $bite};
		} else {
		    $romaji = chop($origbite) . $romaji;
		    chop($bite);
		}
	    }

	    if (!defined($newkana) && length($bite) == 2) {
		if (defined $two{$bite}) {
		    $newkana = $two{$lastromaji = $bite};
		} else {
		    $romaji = chop($origbite) . $romaji;
		    chop($bite);
		}
	    }

	    if (!defined($newkana) && defined $one{$bite}) {
		$newkana = $one{$lastromaji = $bite};
	    }

	    if (defined $newkana)
	    {
		if ($katakana) {
		    ## switch to katakana
		    @chars = $newkana =~ m/(..)/g;
		    grep(s/^\xa4/\xa5/, @chars);
		    $newkana = join('', @chars);
		}
		$kana .= $newkana;
		next;
	    } else {
		## wasn't able to convert.... throw the $bite to both the
		## $kana and $error strings.
	        $kana .= $origbite;
		$error .= $origbite;
		next;
	    }
	}
	$kana .= $1 if $romaji =~ s/^([^a-z]+)//i;
    }
    $error = undef if $error eq '';
    ($kana, $error);
}

%one = (
    'a',  	"\xa4\xa2",		## ��
    'e',  	"\xa4\xa8",		## ��
    'h',  	"\xa4\xa6",		## ��
    'i',  	"\xa4\xa4",		## ��
    'm',  	"\xa4\xf3",		## ��
    'n',  	"\xa4\xf3",		## ��
    'o',  	"\xa4\xaa",		## ��
    'u',  	"\xa4\xa6",		## ��
);

%two = (
    'ba',  	"\xa4\xd0",		## ��
    'be',  	"\xa4\xd9",		## ��
    'bi',  	"\xa4\xd3",		## ��
    'bo',  	"\xa4\xdc",		## ��
    'bu',  	"\xa4\xd6",		## ��
    'ca',  	"\xa4\xab",		## ��
    'co',  	"\xa4\xb3",		## ��
    'cu',  	"\xa4\xaf",		## ��
    'da',  	"\xa4\xc0",		## ��
    'de',  	"\xa4\xc7",		## ��
    'di',  	"\xa4\xc2",		## ��
    'do',  	"\xa4\xc9",		## ��
    'du',  	"\xa4\xc5",		## ��
    'fa',  	"\xa4\xd5\xa4\xa1",	## �դ�
    'fe',  	"\xa4\xd5\xa4\xa7",	## �դ�
    'fi',  	"\xa4\xd5\xa4\xa3",	## �դ�
    'fo',  	"\xa4\xd5\xa4\xa9",	## �դ�
    'fu',  	"\xa4\xd5",		## ��
    'ga',  	"\xa4\xac",		## ��
    'ge',  	"\xa4\xb2",		## ��
    'gi',  	"\xa4\xae",		## ��
    'go',  	"\xa4\xb4",		## ��
    'gu',  	"\xa4\xb0",		## ��
    'ha',  	"\xa4\xcf",		## ��
    'he',  	"\xa4\xd8",		## ��
    'hi',  	"\xa4\xd2",		## ��
    'ho',  	"\xa4\xdb",		## ��
    'hu',  	"\xa4\xd5",		## ��
    'ja',  	"\xa4\xb8\xa4\xe3",	## ����
    'je',  	"\xa4\xb8\xa4\xa7",	## ����
    'ji',  	"\xa4\xb8",		## ��
    'jo',  	"\xa4\xb8\xa4\xe7",	## ����
    'ju',  	"\xa4\xb8\xa4\xe5",	## ����
    'ka',  	"\xa4\xab",		## ��
    'ke',  	"\xa4\xb1",		## ��
    'ki',  	"\xa4\xad",		## ��
    'ko',  	"\xa4\xb3",		## ��
    'ku',  	"\xa4\xaf",		## ��
    'la',  	"\xa4\xe9",		## ��
    'le',  	"\xa4\xec",		## ��
    'li',  	"\xa4\xea",		## ��
    'lo',  	"\xa4\xed",		## ��
    'lu',  	"\xa4\xeb",		## ��
    'ma',  	"\xa4\xde",		## ��
    'me',  	"\xa4\xe1",		## ��
    'mi',  	"\xa4\xdf",		## ��
    'mo',  	"\xa4\xe2",		## ��
    'mu',  	"\xa4\xe0",		## ��
    'na',  	"\xa4\xca",		## ��
    'ne',  	"\xa4\xcd",		## ��
    'ni',  	"\xa4\xcb",		## ��
    'no',  	"\xa4\xce",		## ��
    'nu',  	"\xa4\xcc",		## ��
    'pa',  	"\xa4\xd1",		## ��
    'pe',  	"\xa4\xda",		## ��
    'pi',  	"\xa4\xd4",		## ��
    'po',  	"\xa4\xdd",		## ��
    'pu',  	"\xa4\xd7",		## ��
    'ra',  	"\xa4\xe9",		## ��
    're',  	"\xa4\xec",		## ��
    'ri',  	"\xa4\xea",		## ��
    'ro',  	"\xa4\xed",		## ��
    'ru',  	"\xa4\xeb",		## ��
    'sa',  	"\xa4\xb5",		## ��
    'se',  	"\xa4\xbb",		## ��
    'si',  	"\xa4\xb7",		## ��
    'so',  	"\xa4\xbd",		## ��
    'su',  	"\xa4\xb9",		## ��
    'ta',  	"\xa4\xbf",		## ��
    'te',  	"\xa4\xc6",		## ��
    'ti',  	"\xa4\xc1",		## ��
    'to',  	"\xa4\xc8",		## ��
    'tu',  	"\xa4\xc4",		## ��
    'va',  	"\xa5\xf4\xa4\xa1",	## ����
    've',  	"\xa5\xf4\xa4\xa7",	## ����
    'vi',  	"\xa5\xf4\xa4\xa3",	## ����
    'vo',  	"\xa5\xf4\xa4\xa9",	## ����
    'vu',  	"\xa5\xf4",		## ��
    'wa',  	"\xa4\xef",		## ��
    'we',  	"\xa4\xf1",		## ��
    'wi',  	"\xa4\xf0",		## ��
    'wo',  	"\xa4\xf2",		## ��
    'xa',  	"\xa4\xa1",		## ��
    'xe',  	"\xa4\xa7",		## ��
    'xi',  	"\xa4\xa3",		## ��
    'xo',  	"\xa4\xa9",		## ��
    'xu',  	"\xa4\xa5",		## ��
    'ya',  	"\xa4\xe4",		## ��
    'yo',  	"\xa4\xe8",		## ��
    'yu',  	"\xa4\xe6",		## ��
    'za',  	"\xa4\xb6",		## ��
    'ze',  	"\xa4\xbc",		## ��
    'zi',  	"\xa4\xb8",		## ��
    'zo',  	"\xa4\xbe",		## ��
    'zu',  	"\xa4\xba",		## ��
);

%three = (
    'bya',  	"\xa4\xd3\xa4\xe3",	## �Ӥ�
    'byo',  	"\xa4\xd3\xa4\xe7",	## �Ӥ�
    'byu',  	"\xa4\xd3\xa4\xe5",	## �Ӥ�
    'cha',  	"\xa4\xc1\xa4\xe3",	## ����
    'che',  	"\xa4\xc1\xa4\xa7",	## ����
    'chi',  	"\xa4\xc1",		## ��
    'cho',  	"\xa4\xc1\xa4\xe7",	## ����
    'chu',  	"\xa4\xc1\xa4\xe5",	## ����
    'dya',  	"\xa4\xc2\xa4\xe3",	## �¤�
    'dye',  	"\xa4\xc2\xa4\xa7",	## �¤�
    'dyi',  	"\xa4\xc7\xa4\xa3",	## �Ǥ�
    'dyo',  	"\xa4\xc2\xa4\xe7",	## �¤�
    'dyu',  	"\xa4\xc2\xa4\xe5",	## �¤�
    'dzi',  	"\xa4\xc2",		## ��
    'dzu',  	"\xa4\xc5",		## ��
    'gya',  	"\xa4\xae\xa4\xe3",	## ����
    'gyo',  	"\xa4\xae\xa4\xe7",	## ����
    'gyu',  	"\xa4\xae\xa4\xe5",	## ����
    'hya',  	"\xa4\xd2\xa4\xe3",	## �Ҥ�
    'hyo',  	"\xa4\xd2\xa4\xe7",	## �Ҥ�
    'hyu',  	"\xa4\xd2\xa4\xe5",	## �Ҥ�
    'jya',  	"\xa4\xb8\xa4\xe3",	## ����
    'jyo',  	"\xa4\xb8\xa4\xe7",	## ����
    'jyu',  	"\xa4\xb8\xa4\xe5",	## ����
    'kya',  	"\xa4\xad\xa4\xe3",	## ����
    'kyo',  	"\xa4\xad\xa4\xe7",	## ����
    'kyu',  	"\xa4\xad\xa4\xe5",	## ����
    'mya',  	"\xa4\xdf\xa4\xe3",	## �ߤ�
    'myo',  	"\xa4\xdf\xa4\xe7",	## �ߤ�
    'myu',  	"\xa4\xdf\xa4\xe5",	## �ߤ�
    'nya',  	"\xa4\xcb\xa4\xe3",	## �ˤ�
    'nyo',  	"\xa4\xcb\xa4\xe7",	## �ˤ�
    'nyu',  	"\xa4\xcb\xa4\xe5",	## �ˤ�
    'pya',  	"\xa4\xd4\xa4\xe3",	## �Ԥ�
    'pyo',  	"\xa4\xd4\xa4\xe7",	## �Ԥ�
    'pyu',  	"\xa4\xd4\xa4\xe5",	## �Ԥ�
    'rya',  	"\xa4\xea\xa4\xe3",	## ���
    'ryo',  	"\xa4\xea\xa4\xe7",	## ���
    'ryu',  	"\xa4\xea\xa4\xe5",	## ���
    'sha',  	"\xa4\xb7\xa4\xe3",	## ����
    'shi',  	"\xa4\xb7",		## ��
    'sho',  	"\xa4\xb7\xa4\xe7",	## ����
    'shu',  	"\xa4\xb7\xa4\xe5",	## ����
    'sya',  	"\xa4\xb7\xa4\xe3",	## ����
    'syi',  	"\xa4\xb7",		## ��
    'syo',  	"\xa4\xb7\xa4\xe7",	## ����
    'syu',  	"\xa4\xb7\xa4\xe5",	## ����
    'tsu',  	"\xa4\xc4",		## ��
    'tya',  	"\xa4\xc1\xa4\xe3",	## ����
    'tye',  	"\xa4\xc1\xa4\xa7",	## ����
    'tyi',  	"\xa4\xc6\xa4\xa3",	## �Ƥ�
    'tyo',  	"\xa4\xc1\xa4\xe7",	## ����
    'tyu',  	"\xa4\xc1\xa4\xe5",	## ����
    'tzu',  	"\xa4\xc5",		## ��
    'xka',  	"\xa5\xf5",		## ��
    'xke',  	"\xa5\xf6",		## ��
    'xtu',  	"\xa4\xc3",		## ��
    'xwa',  	"\xa4\xee",		## ��
    'xya',  	"\xa4\xe3",		## ��
    'xyo',  	"\xa4\xe7",		## ��
    'xyu',  	"\xa4\xe5",		## ��
    'zya',  	"\xa4\xb8\xa4\xe3",	## ����
    'zye',  	"\xa4\xb8\xa4\xa7",	## ����
    'zyo',  	"\xa4\xb8\xa4\xe7",	## ����
    'zyu',  	"\xa4\xb8\xa4\xe5",	## ����
);

__END__
