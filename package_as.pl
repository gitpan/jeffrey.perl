## 
## Jeffrey Friedl (jfriedl@omron.co.jp)
## Copyrighted 19...oh hell, just take it.
##
package package_as;
$version = "960330.3";
## Latest changes:
## "960330.3";
##   Made $&-clean
##
## "940627.1";
##   Made to work with perl5

##
## BLURB:
## Routine to, given the name of a package, return a single string representing
## all variables currently in the package. Eval'ing the string will recreate
## the variables. Useful when one wants to save a bunch of status to a file
## between runs of a program.
##
##>
##
## &package_as'text
##
## Used as
##   $text = &package_as'text("name");
##   $text = &package_as'text("name", "falsename");
##
## All variables in the given package will be represented in $text such that
## they will be recreated when $text is eval'ed (perhaps after having been
## saved to a file and loaded by a subsequent program).
##
## If "falsename" is given, the recreated variables will be in that package
## rather than the "name" package.
##
## If one wishes to clear out any variables that might be in the package
## before eval'ing the $text, you might consider something like
##
##       grep(push(@x, "\$$_", "\@$_", "%$_"), keys(%main'_PACKAGE));
##       $x = join(';undef ', '', @x);
##       { package PACKAGE; eval($main'x); }
##
## (where PACKAGE is the name of the package in question)
##
##<

sub text
{
    local($package, $name) = @_; 
    local(*P);
    if ($] < 5) {
        $cmd = "*P = *main'_${package};";
    } else {
	$cmd = "*P = *${package}::";
    }
    eval $cmd;

    $name = $package if !defined $name || $name eq '';
    local($key);
    local(@out) = ("# this file is machine generated... hands off.\n",
		   "{ package $name;\n");

    sub scalar_value
    {
	if (!defined($_[0])) {
	    "undef";
	} else {
	   local($temp) = $_[0];
	   $temp =~ s/([\'\\])/\\$1/g;
	   qq/'$temp'/;
	}
    }


    foreach $key (sort keys %P)
    {
        local(*entry) = $P{$key};

	if (defined $entry) {
	    push(@out, "\$$key = ", &scalar_value($entry), ";\n");
	}
	if (defined @entry) {
	    push(@out, "\@$key = (\n");
	    foreach (@entry) {
	        push(@out, "\t", &scalar_value($_), ",\n");
	    }
	    push(@out, ");\n");
	}
	if (defined %entry) {
	    push(@out, "\%$key = (\n");
	    foreach $key (sort keys(%entry)) {
	        push(@out, "\t", &scalar_value($key),
		      ",\t", &scalar_value($entry{$key}), ",\n");
	    }
	    push(@out, ");\n");
	}
    }
    push(@out, "} 1;\n");
    return join('', @out);
}

1;
__END__
