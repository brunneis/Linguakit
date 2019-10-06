#!/usr/bin/env perl


#
# It takes a tagged text as input and uses a reference corpus (2 million tokens) as argument, to select keywords by computing chi-square measure. 
#
package Keywords;

#<ignore-block>
use strict; 
binmode STDIN, ':utf8';
binmode STDOUT, ':utf8';
use utf8;
#<ignore-block>


sub init {
	# Absolute path 
	use Cwd 'abs_path';#<ignore-line>
	use File::Basename;#<ignore-line>
	my $abs_path = ".";#<string>
	$abs_path = dirname(__FILE__);#<ignore-line>


	@Keywords::ref;#<array><string>
	@Keywords::stop;#<array><string>

	($Keywords::lang) = @_;

	##Language resources
	my ($REF, $STOP);#<file>
	open ($REF, $abs_path."/recursos/ref_$Keywords::lang") or die "O ficheiro ref_$Keywords::lang não pode ser aberto: $!\n";
	binmode $REF, ':utf8';#<ignore-line>

	open ($STOP, $abs_path."/recursos/stopwords_$Keywords::lang") or die "O ficheiro stopwords_$Keywords::lang não pode ser aberto: $!\n";
	binmode $STOP, ':utf8';#<ignore-line>

	@Keywords::ref = <$REF>;#<array><string>
	@Keywords::stop = <$STOP>;#<array><string>

	####Reading file with stopwords and NP errors

	chomp $Keywords::stop[0];
	(my $tmp, $Keywords::ErrosNP) = split ('\t', $Keywords::stop[0]);#<string>
	$Keywords::ErrosNP =~ s/ /\|/g;
	#print STDERR "#$Keywords::ErrosNP#\n";

	chomp $Keywords::stop[1];
	(my $tmp, $Keywords::Stopwords) = split ('\t', $Keywords::stop[1]);#<string>
	$Keywords::Stopwords =~ s/ /\|/g;
}

sub keywords {
	my $texto = $_ [0];#<ref><array><string>
	my $th = 30;#<integer>

	if (@_ > 2 && $_[2]){
		$th = $_[2];
	}

	my @saida=();#<list><string>
	my %POS=();#<hash><hash><integer>
	my %NEG=();#<hash><hash><integer>
	my %Keys=();#<hash><double>
	my $NEG=0;#<integer>
	my $POS=0;#<integer>
	my $N=0;#<integer>
	my %TOKEN;#<ignore-line>

	####Reading file with reference or language model

	foreach my $line (@Keywords::ref) {
		chomp $line;
		my ($lemma, $cat, $freq) = split(qr/ /, $line);#<string>
		$cat =~ s/^J$/A/;
		$NEG{$cat} = {} if (!defined($NEG{$cat}));
		$NEG{$cat}{$lemma} = $freq;
		$NEG += $freq;
	}

	######reading input file
	foreach my $line (@{$texto}) {
		chomp $line;
		#print STDERR "LINE:#$line#\n";
		my ($token, $lemma, $tag) = split(qr/ /, $line);#<string>
		$lemma = $token if ($tag =~ /^NP/ || $tag =~ /^NNP/);
		next if ($token =~ /^($Keywords::ErrosNP)(s?)$/ && ($tag =~ /^NP/ || $tag =~ /^NNP/));
		next if ($lemma =~ /^($Keywords::Stopwords)$/);
		next if ($lemma =~ /([0-9]+)/) ;
		next if ($token =~ /^[\(\)\[\]]/) ;
		next if ($lemma =~ /^[a-z]$/) ;

		if ( $tag =~ /^V|^N|^AQ|^JJ/) {
			#print STDERR "TAG: #$tag#\n";
			if  ( $tag =~ /^NC/ || $tag =~ /^NN$/ || $tag =~ /^NNS$/) {
				$tag =~ s/^N[^ ]+$/N/;
			}elsif ( $tag =~ /^NP00G00/) {
				$tag =~ s/^N[^ ]+$/LOCAL/;
			}elsif ( $tag =~ /^NP00SP0/) {
				$tag =~ s/^N[^ ]+$/PERS/;
			}elsif ( $tag =~ /^NP00O00/) {
				$tag =~ s/^N[^ ]+$/ORG/;
			}elsif ( $tag =~ /^NP00V00/) {
				$tag =~ s/^N[^ ]+$/MISC/;
			}elsif ( $tag =~ /^NP00000/ ||  $tag =~ /^NP/ || $tag =~ /^NNP/ ) {
				$tag =~ s/^N[^ ]+$/ENTITY/;
			}else {
				$tag =~ s/^([A-Z])[^\s]*/$1/;
				$tag =~ s/^J/A/; ##changing english tag for adjective (J) by usual tag "A"
			}
			$POS{$tag} = {} if (!defined($POS{$tag}));
			$POS{$tag}{$lemma}++;
			$token =~ s/_/ /g;#<ignore-line>
			$lemma =~ s/_/ /g;#<ignore-line>
			$TOKEN{$tag}{$lemma}{$token}++;#<ignore-line>
		}
		$POS++;
	}

	$N=$POS+$NEG;

	foreach my $cat (keys %POS) {
		foreach my $w (keys %{$POS{$cat}}) {
			my $a = $POS{$cat}{$w};#<double>
			my $b = 0;#<double>
			if($NEG{$cat} && $NEG{$cat}{$w}){
				$b = $NEG{$cat}{$w};
			}
			my $c = $POS - $a;#<double>
			my $d = $N - $a - $b - $c;#<double>
			#print STDERR "a=$a - b=$b - c=$c - d=$d - d2=$d2 - N=$N\n";
			##chi-square segundo o artigo chines
			my $numerador = $N * ( (($a*$d) - ($b*$c)) ** 2);#<double>

			my $denominador = ($a+$c)*($b+$d)*($a+$b)*($c+$d);#<double>
			my $chiSquare = 0;#<double>
			$chiSquare = $numerador / $denominador if ($denominador >0);

			$cat =~ s/^J/A/; ##changing english tag for adjective (J) by usual tag "A"
			$Keys{$w.' '.$cat} = $chiSquare; 
			#print STDERR "#$w# -- #$cat#\n";
		}
	}

	my $i=0;#<integer>
	foreach my $k (sort {$Keys{$b} <=> $Keys{$a} or $b cmp $a} keys %Keys ) {
		$i++;
		#print STDERR "#$k#\n";
		my $chiSquare = $Keys{$k};#<string>
		my ($w, $cat) = split (qr/ /, $k);#<string>  
		if ($i<=$th) {
			$w =~ s/_/ /g;  
			push (@saida, "$w\t$chiSquare\t$cat");  
		}else {
			last;
		}
	}
	print join("\n", @saida);
	print "\nEOC";
	return \@saida;
}

#<ignore-block>
eval(<STDIN>); # load language
for(;;) {
	my $value=<STDIN>;
	my @params = eval($value);
	my $th = shift(@params);
	keywords(\@params, $th);
}
#<ignore-block>

sub trim {    #remove all leading and trailing spaces
	my $str = $_[0];#<string>

	$str =~ s/^\s*(.*\S)\s*$/$1/;
	return $str;
}

sub colour {    #remove all leading and trailing spaces
	my $cat = $_[0];#<string>
	my $result;#<string>

	if ($cat =~ /^A/) {
		$result = "red";
	}elsif ($cat =~ /^N/) {
		$result = "blue";
	}elsif ($cat =~ /^V/) {
		$result = "green";
	}

	return $result;
}


