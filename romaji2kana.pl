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

$dash = "\241\274";  	  # ー
$small_TU = "\245\303";   # ッ
$small_tu = "\244\303";   # っ


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
    'a',  	"\xa4\xa2",		## あ
    'e',  	"\xa4\xa8",		## え
    'h',  	"\xa4\xa6",		## う
    'i',  	"\xa4\xa4",		## い
    'm',  	"\xa4\xf3",		## ん
    'n',  	"\xa4\xf3",		## ん
    'o',  	"\xa4\xaa",		## お
    'u',  	"\xa4\xa6",		## う
);

%two = (
    'ba',  	"\xa4\xd0",		## ば
    'be',  	"\xa4\xd9",		## べ
    'bi',  	"\xa4\xd3",		## び
    'bo',  	"\xa4\xdc",		## ぼ
    'bu',  	"\xa4\xd6",		## ぶ
    'ca',  	"\xa4\xab",		## か
    'co',  	"\xa4\xb3",		## こ
    'cu',  	"\xa4\xaf",		## く
    'da',  	"\xa4\xc0",		## だ
    'de',  	"\xa4\xc7",		## で
    'di',  	"\xa4\xc2",		## ぢ
    'do',  	"\xa4\xc9",		## ど
    'du',  	"\xa4\xc5",		## づ
    'fa',  	"\xa4\xd5\xa4\xa1",	## ふぁ
    'fe',  	"\xa4\xd5\xa4\xa7",	## ふぇ
    'fi',  	"\xa4\xd5\xa4\xa3",	## ふぃ
    'fo',  	"\xa4\xd5\xa4\xa9",	## ふぉ
    'fu',  	"\xa4\xd5",		## ふ
    'ga',  	"\xa4\xac",		## が
    'ge',  	"\xa4\xb2",		## げ
    'gi',  	"\xa4\xae",		## ぎ
    'go',  	"\xa4\xb4",		## ご
    'gu',  	"\xa4\xb0",		## ぐ
    'ha',  	"\xa4\xcf",		## は
    'he',  	"\xa4\xd8",		## へ
    'hi',  	"\xa4\xd2",		## ひ
    'ho',  	"\xa4\xdb",		## ほ
    'hu',  	"\xa4\xd5",		## ふ
    'ja',  	"\xa4\xb8\xa4\xe3",	## じゃ
    'je',  	"\xa4\xb8\xa4\xa7",	## じぇ
    'ji',  	"\xa4\xb8",		## じ
    'jo',  	"\xa4\xb8\xa4\xe7",	## じょ
    'ju',  	"\xa4\xb8\xa4\xe5",	## じゅ
    'ka',  	"\xa4\xab",		## か
    'ke',  	"\xa4\xb1",		## け
    'ki',  	"\xa4\xad",		## き
    'ko',  	"\xa4\xb3",		## こ
    'ku',  	"\xa4\xaf",		## く
    'la',  	"\xa4\xe9",		## ら
    'le',  	"\xa4\xec",		## れ
    'li',  	"\xa4\xea",		## り
    'lo',  	"\xa4\xed",		## ろ
    'lu',  	"\xa4\xeb",		## る
    'ma',  	"\xa4\xde",		## ま
    'me',  	"\xa4\xe1",		## め
    'mi',  	"\xa4\xdf",		## み
    'mo',  	"\xa4\xe2",		## も
    'mu',  	"\xa4\xe0",		## む
    'na',  	"\xa4\xca",		## な
    'ne',  	"\xa4\xcd",		## ね
    'ni',  	"\xa4\xcb",		## に
    'no',  	"\xa4\xce",		## の
    'nu',  	"\xa4\xcc",		## ぬ
    'pa',  	"\xa4\xd1",		## ぱ
    'pe',  	"\xa4\xda",		## ぺ
    'pi',  	"\xa4\xd4",		## ぴ
    'po',  	"\xa4\xdd",		## ぽ
    'pu',  	"\xa4\xd7",		## ぷ
    'ra',  	"\xa4\xe9",		## ら
    're',  	"\xa4\xec",		## れ
    'ri',  	"\xa4\xea",		## り
    'ro',  	"\xa4\xed",		## ろ
    'ru',  	"\xa4\xeb",		## る
    'sa',  	"\xa4\xb5",		## さ
    'se',  	"\xa4\xbb",		## せ
    'si',  	"\xa4\xb7",		## し
    'so',  	"\xa4\xbd",		## そ
    'su',  	"\xa4\xb9",		## す
    'ta',  	"\xa4\xbf",		## た
    'te',  	"\xa4\xc6",		## て
    'ti',  	"\xa4\xc1",		## ち
    'to',  	"\xa4\xc8",		## と
    'tu',  	"\xa4\xc4",		## つ
    'va',  	"\xa5\xf4\xa4\xa1",	## ヴぁ
    've',  	"\xa5\xf4\xa4\xa7",	## ヴぇ
    'vi',  	"\xa5\xf4\xa4\xa3",	## ヴぃ
    'vo',  	"\xa5\xf4\xa4\xa9",	## ヴぉ
    'vu',  	"\xa5\xf4",		## ヴ
    'wa',  	"\xa4\xef",		## わ
    'we',  	"\xa4\xf1",		## ゑ
    'wi',  	"\xa4\xf0",		## ゐ
    'wo',  	"\xa4\xf2",		## を
    'xa',  	"\xa4\xa1",		## ぁ
    'xe',  	"\xa4\xa7",		## ぇ
    'xi',  	"\xa4\xa3",		## ぃ
    'xo',  	"\xa4\xa9",		## ぉ
    'xu',  	"\xa4\xa5",		## ぅ
    'ya',  	"\xa4\xe4",		## や
    'yo',  	"\xa4\xe8",		## よ
    'yu',  	"\xa4\xe6",		## ゆ
    'za',  	"\xa4\xb6",		## ざ
    'ze',  	"\xa4\xbc",		## ぜ
    'zi',  	"\xa4\xb8",		## じ
    'zo',  	"\xa4\xbe",		## ぞ
    'zu',  	"\xa4\xba",		## ず
);

%three = (
    'bya',  	"\xa4\xd3\xa4\xe3",	## びゃ
    'byo',  	"\xa4\xd3\xa4\xe7",	## びょ
    'byu',  	"\xa4\xd3\xa4\xe5",	## びゅ
    'cha',  	"\xa4\xc1\xa4\xe3",	## ちゃ
    'che',  	"\xa4\xc1\xa4\xa7",	## ちぇ
    'chi',  	"\xa4\xc1",		## ち
    'cho',  	"\xa4\xc1\xa4\xe7",	## ちょ
    'chu',  	"\xa4\xc1\xa4\xe5",	## ちゅ
    'dya',  	"\xa4\xc2\xa4\xe3",	## ぢゃ
    'dye',  	"\xa4\xc2\xa4\xa7",	## ぢぇ
    'dyi',  	"\xa4\xc7\xa4\xa3",	## でぃ
    'dyo',  	"\xa4\xc2\xa4\xe7",	## ぢょ
    'dyu',  	"\xa4\xc2\xa4\xe5",	## ぢゅ
    'dzi',  	"\xa4\xc2",		## ぢ
    'dzu',  	"\xa4\xc5",		## づ
    'gya',  	"\xa4\xae\xa4\xe3",	## ぎゃ
    'gyo',  	"\xa4\xae\xa4\xe7",	## ぎょ
    'gyu',  	"\xa4\xae\xa4\xe5",	## ぎゅ
    'hya',  	"\xa4\xd2\xa4\xe3",	## ひゃ
    'hyo',  	"\xa4\xd2\xa4\xe7",	## ひょ
    'hyu',  	"\xa4\xd2\xa4\xe5",	## ひゅ
    'jya',  	"\xa4\xb8\xa4\xe3",	## じゃ
    'jyo',  	"\xa4\xb8\xa4\xe7",	## じょ
    'jyu',  	"\xa4\xb8\xa4\xe5",	## じゅ
    'kya',  	"\xa4\xad\xa4\xe3",	## きゃ
    'kyo',  	"\xa4\xad\xa4\xe7",	## きょ
    'kyu',  	"\xa4\xad\xa4\xe5",	## きゅ
    'mya',  	"\xa4\xdf\xa4\xe3",	## みゃ
    'myo',  	"\xa4\xdf\xa4\xe7",	## みょ
    'myu',  	"\xa4\xdf\xa4\xe5",	## みゅ
    'nya',  	"\xa4\xcb\xa4\xe3",	## にゃ
    'nyo',  	"\xa4\xcb\xa4\xe7",	## にょ
    'nyu',  	"\xa4\xcb\xa4\xe5",	## にゅ
    'pya',  	"\xa4\xd4\xa4\xe3",	## ぴゃ
    'pyo',  	"\xa4\xd4\xa4\xe7",	## ぴょ
    'pyu',  	"\xa4\xd4\xa4\xe5",	## ぴゅ
    'rya',  	"\xa4\xea\xa4\xe3",	## りゃ
    'ryo',  	"\xa4\xea\xa4\xe7",	## りょ
    'ryu',  	"\xa4\xea\xa4\xe5",	## りゅ
    'sha',  	"\xa4\xb7\xa4\xe3",	## しゃ
    'shi',  	"\xa4\xb7",		## し
    'sho',  	"\xa4\xb7\xa4\xe7",	## しょ
    'shu',  	"\xa4\xb7\xa4\xe5",	## しゅ
    'sya',  	"\xa4\xb7\xa4\xe3",	## しゃ
    'syi',  	"\xa4\xb7",		## し
    'syo',  	"\xa4\xb7\xa4\xe7",	## しょ
    'syu',  	"\xa4\xb7\xa4\xe5",	## しゅ
    'tsu',  	"\xa4\xc4",		## つ
    'tya',  	"\xa4\xc1\xa4\xe3",	## ちゃ
    'tye',  	"\xa4\xc1\xa4\xa7",	## ちぇ
    'tyi',  	"\xa4\xc6\xa4\xa3",	## てぃ
    'tyo',  	"\xa4\xc1\xa4\xe7",	## ちょ
    'tyu',  	"\xa4\xc1\xa4\xe5",	## ちゅ
    'tzu',  	"\xa4\xc5",		## づ
    'xka',  	"\xa5\xf5",		## ヵ
    'xke',  	"\xa5\xf6",		## ヶ
    'xtu',  	"\xa4\xc3",		## っ
    'xwa',  	"\xa4\xee",		## ゎ
    'xya',  	"\xa4\xe3",		## ゃ
    'xyo',  	"\xa4\xe7",		## ょ
    'xyu',  	"\xa4\xe5",		## ゅ
    'zya',  	"\xa4\xb8\xa4\xe3",	## じゃ
    'zye',  	"\xa4\xb8\xa4\xa7",	## じぇ
    'zyo',  	"\xa4\xb8\xa4\xe7",	## じょ
    'zyu',  	"\xa4\xb8\xa4\xe5",	## じゅ
);

__END__
