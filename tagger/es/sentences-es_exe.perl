#!/usr/bin/env perl

# Separador de frases
# autor: Pablo Gamallo e Marcos Garcia
# Grupo ProlNat@GE, CiTIUS
# Universidade de Santiago de Compostela

# SEPARA FRASES IDENTIFICANDO O PONTO FINAL
package Sentences;

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

	##ficheiros de recursos
	my $ABR;#<file>
	open ($ABR, $abs_path."/lexicon/abreviaturas-es.txt") or die "Faltam as abreviaturas: $!\n";
	binmode $ABR,  ':utf8';#<ignore-line>

	##variaveis globais
	$Sentences::UpperCase = "[A-ZÁÉÍÓÚÀÈÌÒÙÂÊÎÔÛÑÇÜ]";#<string>
	$Sentences::LowerCase = "[a-záéíóúàèìòùâêîôûñçü]";#<string>

	$Sentences::Abr = "";#<string>
	while(my $line = <$ABR>) { #<string>#lendo as abreviaturas...
		chomp $line;
		my ($abr, $trad);#<string>
		($abr, $trad) = split (" ", $line) if ($line =~ /\./);
		$abr =~ s/\./\\./g;
		#$abr = lc $abr; ## Marcos: comento isto para dar cobertura a abreviaturas em maiúscula (Prof. X). Dupliquei as abreviaturas na lista
		$Sentences::Abr .= "|" . "$abr" ;
	}
	close $ABR;

	$Sentences::Abr =~ s/\|[\|]+/\|/g;
	$Sentences::Abr =~ s/^\|//g;
}

sub sentences {
	my @saida = ();#<list><string>
	my ($lines) = @_;#<ref><list><string>

	foreach my $texto (@{$lines}) {
		chomp $texto;

		my $mark_abr = "<ABR-TMP>";#<string>
		my $mark_sigla= "<SIGLA-TMP>";#<string>

		##identificando abreviaturas no texto e substitui-las por um marcador temporal
		$texto =~ s/ ($Sentences::Abr) / $1$mark_abr /ig;
		#print STDERR "--#$texto#\n";

		$texto =~ s/\.($mark_abr)/$1/g;

		##identificar pontos dentro de urls, emails..
		$texto =~ s/($Sentences::LowerCase)\.($Sentences::LowerCase)/$1$mark_sigla$2/g;

		##identificar tres pontos
		$texto =~ s/\.\.\./$mark_sigla$mark_sigla$mark_sigla/g;

		##identificar pontos entre quantidades:
		$texto =~  s/([0-9]+)\.([0-9]+)/$1$mark_sigla$2/g;

		#Identificar siglas com ponto intermedio
		#print STDERR "1#$texto#";
		$texto =~ s/($Sentences::UpperCase)\.($Sentences::UpperCase)/$1$mark_sigla$2/g;
		$texto =~ s/($mark_sigla$Sentences::UpperCase)\.($Sentences::UpperCase)/$1$mark_sigla$2/g;

		$texto =~ s/($mark_sigla$Sentences::UpperCase)\.([\s]+)($Sentences::LowerCase)/$1$mark_sigla$2$3/g; ##o P.P. está ....

		#print STDERR "2#$texto#";

		#$texto =~ s/\./\.\n/g; ##resto de pontos: final de frase 
		$texto =~ s/\.([^\"'])/\.\n$1/g;
		$texto =~ s/$/\n/ ; ##final de texto: final de frase

		##limpar espaços principio de linha
		$texto =~ s/(\n)[\s]+/$1/g;

		##restaurar pontos que não marcam final de frase
		$texto =~ s/$mark_abr/\./g;
		$texto =~ s/$mark_sigla/\./g;

		push (@saida, split("\n", $texto));

	}
	print "\n".join("\n", @saida);
	print "\nEOC";
	return \@saida;

}

#<ignore-block>
init();
for(;;) {
	my $value=<STDIN>;
	my @lines = eval($value);
	sentences(\@lines);
}
#<ignore-block>