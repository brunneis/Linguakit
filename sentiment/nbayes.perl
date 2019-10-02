#!/usr/bin/env perl

#ProLNat Sentiment Analysis 
#autor: Grupo ProLNat@GE, CITIUS
#Universidade de Santiago de Compostela
package Nbayes;

#<ignore-block>
use strict; 
binmode STDIN, ':utf8';
binmode STDOUT, ':utf8';
use utf8;
#<ignore-block>

sub init() {
	use Storable qw(dclone);

	# Absolute path 
	use File::Basename;#<ignore-line>
	$NBayes::abs_path = ".";#<string>
	$NBayes::abs_path = dirname(__FILE__);#<ignore-line>

	%NBayes::Lex_init=();#<hash><string>
	%NBayes::Lex_contr_init=();#<hash><string>
	%NBayes::ProbCat_init=();#<hash><string>
	%NBayes::PriorProb_init=();#<hash><hash><double>
	%NBayes::featFreq_init=();#<hash><integer>
	%NBayes::list_init=();#<hash><string>
	$NBayes::N_init=1;#<integer>
	$NBayes::total_init=0;#<integer>
	$NBayes::peso_total_init=0;#<double>
	$NBayes::result_init=0;#<double>
}

sub load{
	my ($lang) = @_;#<string>

	my $TRAIN;#<file>
	open ($TRAIN, $NBayes::abs_path."/$lang/train_$lang") or die "O ficheiro não pode ser aberto: $! $lang/train_$lang\n";
	binmode $TRAIN,  ':utf8';#<ignore-line>

	my $LEX;#<file>
	open ($LEX, $NBayes::abs_path."/$lang/lex_$lang") or die "O ficheiro não pode ser aberto: $! $lang/lex_$lang\n";
	binmode $LEX,  ':utf8';#<ignore-line>


	#####################
	#                   #
	#    READING lexico #
	#                   #
	#####################
	while (my $line = <$LEX>) {   #<string>#leitura treino
		chomp $line;

		my ($word, $cat) = split ('\t', $line);#<string>
		$word = trim ($word);
		$cat = trim ($cat);
		$NBayes::Lex_init{$word} .= $cat . "|";
		$NBayes::PriorProb_init{$cat}={} if (!defined $NBayes::PriorProb_init{$cat});
		$NBayes::PriorProb_init{$cat}{$word} = 0.1;
		#print STDERR "#$word# --  $NBayes::Lex_init{$word}\n" ;
	}

	foreach my $l (keys %NBayes::Lex_init) {
		my $positive=0;#<integer>
		my $negative=0;#<integer>
		my $none=0;#<integer>
		my @pols = split ('\|', $NBayes::Lex_init{$l});#<array><string>

		foreach my $p (@pols) {
			#print STDERR "------------------ #$l# --- P=#$p#\n";
			$positive++ if ($p eq "POSITIVE");
			$negative++ if ($p eq "NEGATIVE");
			$none++ if ($p eq "NONE");
		}

		if ($positive > $negative) {
			$NBayes::Lex_init{$l} = "POSITIVE";
			$NBayes::Lex_contr_init{$l} = "NEGATIVE"; 
		}elsif ($negative > $positive) {
			$NBayes::Lex_init{$l} = "NEGATIVE";
			$NBayes::Lex_contr_init{$l} = "POSITIVE";
		}else {
			delete $NBayes::Lex_init{$l};
		}
		#print STDERR "#$l# --  $NBayes::Lex_init{$l}\n" ;
	}


	#####################
	#                   #
	#    READING TRAIN  #
	#                   #
	#####################
	($NBayes::N_init) = (<$TRAIN> =~ /<number\_of\_docs>([0-9]*)</);
	while (my $line = <$TRAIN>) { #<string>#leitura treino
		chomp $line;

		if ($line =~ /<cat>/) { 
			my ($tmp) = $line =~ /<cat>([^<]*)</;#<string>
			#print STDERR "ProbCat: ---> #$tmp# \n";
			my ($cat, $prob) = split (" ", $tmp);#<string>
			$NBayes::ProbCat_init{$cat}=$prob ;
			#print STDERR "CAT: ---> #$cat# \n";
		}elsif ($line =~ /<list>/) { 
			my ($tmp) = $line =~ /<list>([^<]*)</;#<string>
			my ($var, $list) = split (" ", $tmp);#<string>
			$NBayes::list_init{$var} = $list;
			#print STDERR "#$var# -- #$NBayes::list_init#\n";
		}else{
			my ($feat, $cat, $prob, $freq) = split(qr/ /, $line);#<string>
			if($cat){
				$NBayes::PriorProb_init{$cat} = {} if (!defined $NBayes::PriorProb_init{$cat});
				$NBayes::PriorProb_init{$cat}{$feat} = $prob if (!$NBayes::PriorProb_init{$cat}{$feat});
			}
			$NBayes::featFreq_init{$feat} = $freq;
			#print STDERR "CAT: ---> #$cat# -- #$prob# \n" ;
		}
	}

}

sub nbayes{

	%NBayes::Lex = %{dclone(\%NBayes::Lex_init)};#<hash><string>
	%NBayes::Lex_contr = %{dclone(\%NBayes::Lex_contr_init)};#<hash><string>
	%NBayes::ProbCat = %{dclone(\%NBayes::ProbCat_init)};#<hash><string>
	%NBayes::PriorProb = %{dclone(\%NBayes::PriorProb_init)};#<hash><hash><double>
	%NBayes::featFreq = %{dclone(\%NBayes::featFreq_init)};#<hash><integer>
	%NBayes::list = %{dclone(\%NBayes::list_init)};#<hash><string>
	$NBayes::N = $NBayes::N_init;#<integer>
	$NBayes::total = $NBayes::total_init;#<integer>
	$NBayes::peso_total = $NBayes::peso_total_init;#<double>
	$NBayes::result = $NBayes::result_init;#<double>

	my ($text) = @_;#<ref><list><string>

	my $previous = "";#<string>
	my $previous2;#<string>
	my $LEX="";#<string>
	my $default_value = "NONE";#<string>
	my $POS_EMOT=0;#<integer>
	my $NEG_EMOT=0;#<integer>
	my %Compound=();#<hash><boolean>
	my @A=();#<list><string>
	my $lines="";#string
	


	foreach my $line (@{$text}) {
		chomp $line;
	
		if ($line !~ /\w/) {next;}
		my ($token, $lemma, $tag) = split (" ", $line);#<string>
		#print STDERR "#$token# - #$lemma# - #$tag#\n" ;
		$token =~ s/<blank>/ /;
		$lines .= $token . " ";
		if ($token eq "EMOT_POS") { ##Contar os emoticons positivos
			$POS_EMOT++;
			#print STDERR "LEX:#$lemma#\n";
		} elsif ($token eq "EMOT_NEG") { ##Contar os emoticons positivos
			$NEG_EMOT++;
			# print STDERR "NEG-EMOT:#$lemma#\n";
		}

		if ($tag =~ /^([FI])/) {
			$previous="";
		} elsif ($tag =~ /^(V|N|AQ|R|JJ)/ && $lemma !~ /^($NBayes::list{'light_words'})$/) {   
			my $lemma_orig;#<string>
			if ($NBayes::Lex{$lemma}) { ##Contar os lemas da frase de entrada que estao no léxico.
				$LEX++;
				$lemma_orig=$lemma;
				#print STDERR "LEX:#$lemma#\n";
			}
			if ($NBayes::Lex{$lemma} && $tag =~ /^(AQ|JJ)/ && $previous =~ /^($NBayes::list{'quant_adj'})$/ ) { ##muy bonito
				$lemma = $previous . "_" . $lemma;
				#print STDERR "#$lemma# #$previous# #$previous2# \n";
				if ($previous2 =~ /^($NBayes::list{'neg_noun'})$/ && $lemma =~ /^$NBayes::list{'quant_adj'}\_/) { ##no muy bonito
					$lemma = $previous2 . "_" . $lemma;
					$NBayes::PriorProb{$NBayes::Lex_contr{$lemma_orig}}{$lemma} =  $NBayes::PriorProb{$NBayes::Lex{$lemma_orig}}{$lemma_orig}  if ($NBayes::Lex{$lemma_orig});
					$NBayes::PriorProb{$NBayes::Lex{$lemma_orig}}{$lemma} =  0 if ($NBayes::Lex{$lemma_orig});
					push (@A, $lemma);
					$Compound{$lemma}=1;
					#print STDERR "LEM:#$lemma# - #$lema_orig# -- #$NBayes::Lex_contr{$lemma_orig}#\n";
				} else { 
					$NBayes::PriorProb{$NBayes::Lex{$lemma_orig}}{$lemma} =  $NBayes::PriorProb{$NBayes::Lex{$lemma_orig}}{$lemma_orig}  if ($NBayes::Lex{$lemma_orig});
					# $NBayes::PriorProb{$NBayes::Lex{$lemma_orig}}{$lemma} =  0 if ($NBayes::Lex{$lemma_orig});
					$Compound{$lemma}=1;
					push (@A, $lemma);
				}
			} elsif ($NBayes::Lex{$lemma} && $tag =~ /(^N|^AQ|^JJ)/ && $previous =~ /^($NBayes::list{'neg_noun'})$/) { ##no bonito
				#print STDERR "LEM:#$lemma# - #$lemma_orig# #Previous: #$previous#\n";
				$lemma = $previous . "_" . $lemma;
				$NBayes::PriorProb{$NBayes::Lex_contr{$lemma_orig}}{$lemma} =  $NBayes::PriorProb{$NBayes::Lex{$lemma_orig}}{$lemma_orig}  if ($NBayes::Lex{$lemma_orig});
				$NBayes::PriorProb{$NBayes::Lex{$lemma_orig}}{$lemma} =  0 if ($NBayes::Lex{$lemma_orig});
				$Compound{$lemma}=1;
				push (@A, $lemma);
				#print STDERR "LEM:#$lemma# - #$lemma_orig# #Previous: #$previous# -- #$NBayes::Lex_contr{$lemma_orig}# --- #$NBayes::PriorProb{$NBayes::Lex_contr{$lemma_orig}}{$lemma}# -- #$NBayes::PriorProb{$NBayes::Lex{$lemma_orig}}{$lemma}#\n";
				#print STDERR "LEMMA COM NEG: #$lemma#\n";
			} elsif ($NBayes::Lex{$lemma} && $tag =~ /^V/ && $previous =~ /^($NBayes::list{'neg_verb'})$/) { #no me gusta
				$lemma = $previous . "_" . $lemma;
				#print STDERR "VERB COM NEG: #$lemma#\n";
				$NBayes::PriorProb{$NBayes::Lex_contr{$lemma_orig}}{$lemma} =  $NBayes::PriorProb{$NBayes::Lex{$lemma_orig}}{$lemma_orig}  if ($NBayes::Lex{$lemma_orig});
				$NBayes::PriorProb{$NBayes::Lex{$lemma_orig}}{$lemma} =  0 if ($NBayes::Lex{$lemma_orig});
				$Compound{$lemma}=1;
				push (@A, $lemma);
			} else {
				push (@A, $lemma);
			}
			$previous2 = $previous;
			$previous = $lemma;
			#print STDERR "Lemma-previous: #$lemma# -- #$previous#\n";
		}    
	} 


	#########################################
	#                                       #
	#       Classification                  #
	#                                       #
	#########################################
 

	if ($POS_EMOT > $NEG_EMOT){ #if there is more positive emoticons: positive
		$NBayes::total++;
		$NBayes::peso_total += 1;
		print "$lines\tPOSITIVE\t1";
		print "\nEOC\n";
		return "$lines\tPOSITIVE\t1";
	} elsif ($POS_EMOT < $NEG_EMOT){#if there is more negative emoticons: negative
		$NBayes::total++;
		$NBayes::peso_total -= 1;
		print "$lines\tNEGATIVE\t1";
		print "\nEOC\n";
		return "$lines\tNEGATIVE\t1";
	} elsif (!$LEX) {
	        $NBayes::total++;
		print "$lines\t$default_value\t1"; #if there is no lemma from the polartity lexicon: NONE.
		print "\nEOC\n";
		return "$lines\t$default_value\t1"; #if there is no lemma from the polartity lexicon: NONE.
	}

	my $smooth = 1/$NBayes::N;#<double>
	my $Normalizer = 0;#<double>
	my %PostProb=();#<hash><double>
	my %found=();#<hash><boolean>
	my $found;#<boolean>

	foreach my $cat (keys %NBayes::PriorProb) {
		if (!$cat) { next;}
		$PostProb{$cat}  = $NBayes::ProbCat{$cat};
		#print STDERR "ProbCat:#$cat# - #$NBayes::ProbCat{$cat}#\n";
		$found{$cat}=0;
		foreach my $word (@A) {
			#if (!$NBayes::featFreq{$word} ||  $NBayes::PriorProb{$cat}{$word} <= $th) {next} ;
			if (!$NBayes::featFreq{$word} &&  !$Compound{$word} && !$NBayes::Lex{$word}) { next;};
			#print STDERR " priorprob-$word:#$NBayes::PriorProb{$cat}{$word}#\n";
			$NBayes::PriorProb{$cat}{$word}  = $smooth if ($NBayes::PriorProb{$cat}{$word}  ==0) ;
			$found{$cat}=1; 
			$PostProb{$cat} = $PostProb{$cat} * $NBayes::PriorProb{$cat}{$word};
			#print STDERR "----#$cat# - #$word# PriorProb#$NBayes::PriorProb{$cat}{$word}# PostProb#$PostProb{$cat}#\n";
		}
 
		if ($found{$cat}){
			$PostProb{$cat} =  $PostProb{$cat} * $NBayes::ProbCat{$cat};
		} else{
			$PostProb{$cat} = 0;
		}
		$Normalizer +=   $PostProb{$cat};
		#print STDERR "PROB: #$cat# -  PostProb#$PostProb{$cat}#  ProbCat#$NBayes::ProbCat{$cat}#\n";
	}
	$found=0;
	foreach my $c (keys %PostProb) {
		#print STDERR "$c - #$PostProb{$c}#\n" if ($c);
		$PostProb{$c} = $PostProb{$c} / $Normalizer if ($Normalizer);
		$found=1 if ($found{$c});
	}

	if (!$found) {
	        $NBayes::total++;
		print "$lines\t$default_value\t1";
		print "\nEOC\n";
		return "$lines\t$default_value\t1"; 
	} else {
		foreach my $c (sort {$PostProb{$b} <=> $PostProb{$a} } keys %PostProb ) {
		        #$NBayes::total++;
			if ($c eq "POSITIVE") {
			    $NBayes::peso_total += $PostProb{$c};
			    $NBayes::total++;
			}
			elsif ($c eq "NEGATIVE") {
			    $NBayes::peso_total -= $PostProb{$c};
			    $NBayes::total++;
			}
			print "$lines\t$c\t$PostProb{$c}";
			print "\nEOC\n";
			return "$lines\t$c\t$PostProb{$c}";
		}
	}	
}


#<ignore-block>
init();
eval(<STDIN>); # load language
for(;;) {
	my $value=<STDIN>;
	my @lines = eval($value);
	nbayes(\@lines);
}
#<ignore-block>

sub trim {    #remove all leading and trailing spaces
	my $str = $_[0];#<string>

	$str =~ s/^\s*(.*\S)\s*$/$1/;
	return $str;
}