#!/usr/bin/env perl

# ProLNat Tokenizer (provided with Sentence Identifier)
# autor: Grupo ProLNat@GE, CiTIUS
# Universidade de Santiago de Compostela


# Script que integra 2 funçoes perl: sentences e tokens
package Tokens;

#<ignore-block>
use strict; 
binmode STDIN, ':utf8';
binmode STDOUT, ':utf8';
use utf8;

#<ignore-block>

sub init {
	# Absolute path 
	use File::Basename;#<ignore-line>
	my $abs_path = ".";#<string>
	$abs_path = dirname(__FILE__);#<ignore-line>

	##variaveis globais
	$Tokens::Punct =  qr/[\,\;\«\»\“\”\'\"\&\$\#\=\(\)\<\>\!\¡\?\¿\\\[\]\{\}\|\^\*\€\·\¬\…]/;#<string>
	$Tokens::Punct_urls = qr/[\:\/\~]/;#<string>

	##para splitter:
	##########INFORMAÇAO DEPENDENTE DA LINGUA###################
	#my $pron = "(me|te|se|le|les|la|lo|las|los|nos|os)";
	###########################################################
	my $w = "[A-ZÁÉÍÓÚÀÈÌÒÙÂÊÎÔÛÑÇÜa-záéíóúàèìòùâêîôûñçü]";#<string>
}

sub tokens {
	
	my ($sentences) = @_;#<ref><list><string>

	###puntuaçoes compostas
	my $susp = "3SUSP012";#<string>
	my $duplo1 = "2DOBR111";#<string>
	my $duplo2 = "2DOBR222";#<string>
	my $duplo3 = "2DOBR333";#<string>
	my $duplo4 = "2DOBR444";#<string>

	##pontos e virgulas entre numeros
	my $dot_quant = "44DOTQUANT77";#<string>
	my $comma_quant = "44COMMQUANT77";#<string>
	my $quote_quant = "44QUOTQUANT77";#<string>

	my @saida = ();#<list><string>

	foreach my $sentence (@{$sentences}) {
		chomp $sentence;

		utf8::upgrade($sentence);

		#substituir puntuaçoes 

		$sentence =~ s/[ ]*$//;
		$sentence =~ s/\.\.\./ $susp /g ;
		$sentence =~ s/\<\</ $duplo1 /g ;
		$sentence =~ s/\>\>/ $duplo2 /g ;
		$sentence =~ s/\'\'/ $duplo3 /g ;
		$sentence =~ s/\`\`/ $duplo4 /g ;

		$sentence =~ s/([0-9]+)\.([0-9]+)/${1}$dot_quant$2 /g ;
		$sentence =~ s/([0-9]+)\,([0-9]+)/${1}$comma_quant$2 /g ;
		$sentence =~ s/([0-9]+)\'([0-9]+)/${1}$quote_quant$2 /g ;

		#print STDERR "#$sentence#\n";
		$sentence =~ s/($Tokens::Punct)/ $1 /g ;
		#print STDERR "2#$sentence#\n";
		$sentence =~ s/($Tokens::Punct_urls)(?:[\s\n]|$)/ $1 /g  ; 

		##hypen - no fim de palavra ou no principio:
		$sentence =~ s/(\w)- /$1 - /g  ;
		$sentence =~ s/ -(\w)/ - $1/g  ;
		$sentence =~ s/(\w)-$/$1 -/g  ;
		$sentence =~ s/^-(\w)/- $1/g  ;


		$sentence =~ s/\.$/ \. /g  ; ##ponto final

		my @tokens = split (" ", $sentence);#<array><string> 

		foreach my $token (@tokens) {

			$token =~ s/^[\s]*//;
			$token =~ s/[\s]*$//;
			$token =~ s/$susp/\.\.\./;
			$token =~ s/$duplo1/\<\</;
			$token =~ s/$duplo2/\>\>/;
			$token =~ s/$duplo3/\'\'/;
			$token =~ s/$duplo4/\`\`/;
			$token =~ s/$dot_quant/\./;
			$token =~ s/$comma_quant/\,/;
			$token =~ s/$quote_quant/\'/;

			push (@saida, $token);

		}
		push (@saida, "");
		
	}
	
	print "\n".join("\n", @saida);
	print "\nEOC";
	return \@saida;
}


#<ignore-block>
init();
for(;;) {
	my $value=<STDIN>;
	my @tokens = eval($value);
	tokens(\@tokens);
}
#<ignore-block>

###OUTRAS FUNÇOES

sub punct {
	my ($p) = @_ ;#<string>
	my $result ="";#<string>

	if ($p eq "\.") {
		$result = "Fp"; 
	}
	elsif ($p eq "\,") {
		$result = "Fc"; 
	}
	elsif ($p eq "\:") {
		$result = "Fd"; 
	}
	elsif ($p eq "\;") {
		$result = "Fx"; 
	}
	elsif ($p =~ /^(\-|\-\-)$/) {
		$result = "Fg"; 
	} 
	elsif ($p =~ /^(\'|\"|\`\`|\'\')$/) {
		$result = "Fe"; 
	}
	elsif ($p eq "\.\.\.") {
		$result = "Fs"; 
	}
	elsif ($p =~ /^(\<\<|«)/) {
		$result = "Fra"; 
	}
	elsif ($p =~ /^(\>\>|»)/) {
		$result = "Frc"; 
	}
	elsif ($p eq "\%") {
		$result = "Ft"; 
	}
	elsif ($p =~ /^(\/|\\)$/) {
		$result = "Fh"; 
	}
	elsif ($p eq "\(") {
		$result = "Fpa"; 
	}
	elsif ($p eq "\)") {
		$result = "Fpt"; 
	}
	elsif ($p eq "\¿") {
		$result = "Fia"; 
	} 
	elsif ($p eq "\?") {
		$result = "Fit"; 
	}
	elsif ($p eq "\¡") {
		$result = "Faa"; 
	}
	elsif ($p eq "\!") {
		$result = "Fat"; 
	}
	elsif ($p eq "\[") {
		$result = "Fca"; 
	} 
	elsif ($p eq "\]") {
		$result = "Fct"; 
	}
	elsif ($p eq "\{") {
		$result = "Fla"; 
	} 
	elsif ($p eq "\}") {
		$result = "Flt"; 
	}
	return $result;
}
