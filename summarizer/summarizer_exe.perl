#!/usr/bin/env perl

package Summarizer;


#<ignore-block>
use strict; 
binmode STDIN, ':utf8';
binmode STDOUT, ':utf8';
use utf8;
use open qw(:std :utf8);
#<ignore-block>

sub init() {
	# Absolute path 
	use Cwd 'abs_path';#<ignore-line>
	use File::Basename;#<ignore-line>
	my $abs_path = ".";#<string>
	$abs_path = dirname(abs_path($0));#<ignore-line>

	do $abs_path.'/Sentence.pl';

	my $DIR=$abs_path;
	$DIR =~ s/\/summarizer//;
}


sub set_sentences {
	my ($lines) = @_;#<ref><list><string>
	my @analitation=@{$lines};#<list><string>
   
    #print STDERR "-->anal: #@analitation#\n";
    @Summarizer::sentences = ();
    #Creamos el objeto que guardará la frase
    my $sentence = Sentence::new("Sentence");
    
    foreach my $line (@analitation) {
        if ($line eq "\n") {
            push(@Summarizer::sentences, $sentence);
            $sentence = Sentence::new("Sentence");
            next;
        }
		chomp $line;
		$sentence->valor($line);
    }
}

sub set_keywords {
	my ($lines) = @_;#<ref><list><string>
	@Summarizer::keys = @{$lines};#<list><string>
}

sub summarizer {
	my $percentage_to_summarize =  $_[0]; ##percentage of the abstract

	#Proceso de pesado keys
	for my $keyword (@Summarizer::keys) {
		##keyword info
		my @parts = split "\t", $keyword;
		my $term_key = lc($parts[0]);
		my $score_key = $parts[1];
		#print STDERR "-->keyword: #$keyword#\n";
		for my $line (@Summarizer::sentences) {
			$line->keywords(appearanceKeyword($line->valor(), $term_key, $score_key));
		}
	}

	#Debería estar en otro metodo pero en perl el paso de más de 1 array a una subrrutina es muerte por lo tanto lo dejo asi, sorry por no ser muy clean code :(
	my @resumen = ();
	my @ordenado = my @array = sort {$b->peso() <=> $a->peso()} @Summarizer::sentences;

	#Porcentaje de frases del total que devolveremos
	my $porcentaje = int((($#ordenado * $percentage_to_summarize)/100));
	
	for my $line (0 .. $porcentaje){
	    push(@resumen , $ordenado[$line]->valor());
	}

	#Proceso de anotado del texto y ordenado de las frases según el orden en el texto.
	my @anotado = ();
	my @sumarition_ordened = ();
	for my $sentence (@Summarizer::sentences) {
		my $anotacion = $sentence->valor();
		for my $mark (@resumen) {
			if($sentence->valor() eq $mark){
				#$sentence = "<tag>"+$sentence+"</tag>";
				$anotacion = "<span class=\"cilenisAPI_SUMMARIZER\">".$sentence->valor()."</span>";
				push(@sumarition_ordened , $sentence->valor());
			#	next;
			}
		}

		push(@anotado , $anotacion);
	}

	

	#@resumen = (join(" ",@anotado) , join(" ",@sumarition_ordened)); ## Esta saída contém o texto anotado!!
	@resumen = join(" ",@sumarition_ordened);

	return @resumen;
	
}


sub appearanceKeyword{
	my($sentence, $term, $score) = @_;
	if (lc($sentence) =~ m/ $term /) {
		#return 1;
		return int($score);
	}else{
		return 0;
	}
}

sub appearanceMultiword{
	my($sentence, $term, $score) = @_;
	$term =~ s/-/.*/gi;

	if (lc($sentence) =~ m/ $term /) {
		#return 1;
		return int($score)*100;
	}else{
		return 0;
	}
}

#<ignore-block>
for(;;) {
	my $value=<STDIN>;
	my @sentences = eval($value);
	set_sentences(\@sentences);

	$value=<STDIN>;
	my @keywords = eval($value);
	set_keywords(\@keywords);

	$value=<STDIN>;
	my $percentage = eval($value);
	
	my $result = summarizer($percentage);
	print "$result\n";
	print "\nEOC";
}
#<ignore-block>


