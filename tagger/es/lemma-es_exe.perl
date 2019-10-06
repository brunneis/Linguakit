#!/usr/bin/env perl

#ProLNat NER 
#autor: Grupo ProLNat@GE, CITIUS
#Universidade de Santiago de Compostela

package Lemma;

#<ignore-block>
use strict; 
binmode STDIN, ':utf8';
binmode STDOUT, ':utf8';
use open qw(:std :utf8);
use utf8;
#<ignore-block>

sub init() {
	# Absolute path 
	use File::Basename;#<ignore-line>
	my $abs_path = ".";#<string>
	$abs_path = dirname(__FILE__);#<ignore-line>
	unshift(@INC, $abs_path);#<ignore-line>
	do "store_lex.perl";

	##ficheiros de recursos
	$Lemma::Entry;#<ref><hash><string>
	$Lemma::Lex;#<ref><hash><integer>
	$Lemma::StopWords;#<ref><hash><string>
	$Lemma::Noamb;#<ref><hash><boolean>
	($Lemma::Entry,$Lemma::Lex,$Lemma::StopWords,$Lemma::Noamb) = Store::read();

	##lexico de formas ambiguas
	my $AMB;#<file>
	open ($AMB, $abs_path."/lexicon/ambig.txt") or die "O ficheiro de palavras ambiguas não pode ser aberto: $!\n";
	binmode $AMB,  ':utf8';#<ignore-line>

	#print STDERR "$abs_path\n";
	##variaveis globais
	##para sentences e tokens:
	$Lemma::UpperCase = "[A-ZÁÉÍÓÚÀÈÌÒÙÂÊÎÔÛÑÇÜ]";#<string>
	$Lemma::LowerCase = "[a-záéíóúàèìòùâêîôûñçü]";#<string>
	$Lemma::Punct =  qr/[\,\;\«\»\“\”\'\"\&\$\#\=\(\)\<\>\!\¡\?\¿\\\[\]\{\}\|\^\*\€\·\¬\…\-\+]/;#<string>
	$Lemma::Punct_urls = qr/[\:\/\~]/;#<string>

	##carregando palavras ambiguas
	%Lemma::Ambig=();#<hash><boolean>
	##cargando palavras ambiguas
	while (my $t = <$AMB>) {#<string>
		$t = Trim ($t);
		$Lemma::Ambig{$t}=1;
	}
	close $AMB;

	######################info dependente da língua!!!####################################################################################
	$Lemma::cifra = "(dos|tres|catro|cinco|seis|siete|ocho|nueve|diez|cien|mil)"; #<string>#hai que criar as cifras básicas: once, doce... veintidós, treinta y uno...
	######################info dependente da língua!!!####################################################################################
}

sub lemma{
	my $N=10;#<integer>
	my @saida=();#<list><string> 

	my $SEP = "_";#<string>
	my %Tag = ();#<hash><string>
	my $Candidate;#<string>
	my $token;#<string>

	my ($lines) = @_;#<ref><list><string>
	my @tokens=@{$lines};#<list><string>

	for (my $i=0; $i<=$#tokens; $i++) {#<integer>
		##marcar fim de frase
		$Tag{$tokens[$i]} = "";
		my $lowercase = lowercase ($tokens[$i]);#<string>
		if ($tokens[$i] =~ /^[ ]*$/) {
			$tokens[$i] = "#SENT#";
		}
		my $k = $i - 1;#<string>
		my $j = $i + 1;#<string>
	 
		####CADEA COM TODAS PALAVRAS EM MAIUSCULA
		if ($tokens[$i] =~ /^$Lemma::UpperCase+$/ && $tokens[$j] =~ /^$Lemma::UpperCase+$/ && $Lemma::Lex->{$lowercase} && $Lemma::Lex->{lowercase($tokens[$j])}) {
			$Tag{$tokens[$i]} = "UNK"; ##identificamos cadeas de tokens so em maiusculas e estao no dicionario
		}elsif ($tokens[$i] =~ /^$Lemma::UpperCase+$/ && $tokens[$k] =~ /^$Lemma::UpperCase+$/ && $Lemma::Lex->{$lowercase} && $Lemma::Lex->{lowercase($tokens[$k])} &&
		  ($tokens[$j] =~ /^(\#SENT\#|\<blank\>|\"|\»|\”|\.|\-|\s|\?|\!|\:)$/ || $i == $#tokens ) ) { ##ultimo token de uma cadea com so maiusculas
			$Tag{$tokens[$i]} = "UNK";             
		}
		####CADEAS ENTRE ASPAS com palavras que começam por maiuscula 
		elsif ($tokens[$k]  =~ /^(\"|\“|\«|\')/ && $tokens[$i] =~ /^$Lemma::UpperCase/ &&
		  $tokens[$i+1] =~ /^$Lemma::UpperCase/ && $tokens[$i+2] =~ /[\"\»\”\']/) {
			$Candidate =  $tokens[$i] . $SEP . $tokens[$i+1];  
			$i = $i + 1; 
			$tokens[$i] = $Candidate;
		}elsif ($tokens[$k]  =~ /^(\"|\“|\«|\')/ && $tokens[$i] =~ /^$Lemma::UpperCase/ &&
		  $tokens[$i+1] =~ /^$Lemma::UpperCase/ && $tokens[$i+2] =~ /^$Lemma::UpperCase/ && $tokens[$i+3] =~ /[\"\»\”\']/) {
			$Candidate =  $tokens[$i] . $SEP . $tokens[$i+1] . $SEP . $tokens[$i+2];   
			$i = $i + 2;
			$tokens[$i] = $Candidate;	    
		}elsif ($tokens[$k]  =~ /^(\"|\“|\«|\')/ && $tokens[$i] =~ /^$Lemma::UpperCase/ &&
		  $tokens[$i+1] =~ /^$Lemma::UpperCase/ && $tokens[$i+2] =~ /^$Lemma::UpperCase/ &&
		  $tokens[$i+3] =~ /^$Lemma::UpperCase/ && $tokens[$i+4] =~ /[\"\»\”\']/) {
			$Candidate =  $tokens[$i] . $SEP . $tokens[$i+1] . $SEP .  $tokens[$i+2] . $SEP . $tokens[$i+3];   
			$i = $i + 3;   
			$tokens[$i] = $Candidate;           
		}elsif ($tokens[$k]  =~ /^(\"|\“|\«|\')/ && $tokens[$i] =~ /^$Lemma::UpperCase/ &&
		  $tokens[$i+1] =~ /^$Lemma::UpperCase/ && $tokens[$i+2] =~ /^$Lemma::UpperCase/ &&
		  $tokens[$i+3] =~ /^$Lemma::UpperCase/ && $tokens[$i+4] =~ /^$Lemma::UpperCase/ && $tokens[$i+5] =~ /[\"\»\”\']/) {
			$Candidate =  $tokens[$i] . $SEP . $tokens[$i+1] . $SEP .  $tokens[$i+2] . $SEP . $tokens[$i+3] . $SEP . $tokens[$i+4];   
			$i = $i + 4;   
			$tokens[$i] = $Candidate;           
		}elsif ($tokens[$k]  =~ /^(\"|\“|\«|\')/ && $tokens[$i] =~ /^$Lemma::UpperCase/ &&
		$tokens[$i+1] =~ /^$Lemma::UpperCase/ && $tokens[$i+2] =~ /^$Lemma::UpperCase/ &&
		$tokens[$i+3] =~ /^$Lemma::UpperCase/ && $tokens[$i+4] =~ /^$Lemma::UpperCase/ && $tokens[$i+5] && $tokens[$i+6] =~ /[\"\»\”\']/) {
		$Candidate =  $tokens[$i] . $SEP . $tokens[$i+1] . $SEP .  $tokens[$i+2] . $SEP . $tokens[$i+3] . $SEP . $tokens[$i+4] . $SEP . $tokens[$i+5];   
		$i = $i + 5;   
		$tokens[$i] = $Candidate;
		}
		###Palavras que começam por maiúscula e nao estao no dicionario com maiusculas
		elsif ( $tokens[$i] =~ /^$Lemma::UpperCase/ && $Lemma::Noamb->{$tokens[$i]} ) { ##começa por maiúscula e e um nome proprio nao ambiguo no dicionario
		    $Tag{$tokens[$i]} = "NP00000";
		}elsif ( $tokens[$i] =~ /^$Lemma::UpperCase/ && $Lemma::Ambig{$lowercase} ) { ##começa por maiúscula e e um nome proprio ambiguo no dicionario
			$Tag{$tokens[$i]} = "NP00000";
		}
		#elsif ( ($tokens[$i] =~ /^$Lemma::UpperCase/) &&  !$Lemma::Lex->{$lowercase} && 
		elsif ($tokens[$i] =~ /^$Lemma::UpperCase/ &&  !$Lemma::StopWords->{$lowercase} &&
		  $tokens[$k] !~ /^(\#SENT\#|\<blank\>|\"|\“|\«|\.|\-|\s|\¿|\¡|\?|\!|\:|\`\`)$/ && $tokens[$k] !~ /^\.\.\.$/  && $i>0 ) { ##começa por maiúscula e nao vai a principio de frase
			$Tag{$tokens[$i]} = "NP00000";
			#print  STDERR "1TOKEN::: ##$i## --  ##$tokens[$i]## - - #$Tag{$tokens[$i]}# --  prev:#$tokens[$k]# --  post:#$tokens[$j]#\n" if ($tokens[$i] eq "De");
		}
		## elsif   ( ($tokens[$i] =~ /^$Lemma::UpperCase/ &&  !$Lemma::Lex->{$lowercase} &&
		elsif   ( ($tokens[$i] =~ /^$Lemma::UpperCase/ &&  !$Lemma::StopWords->{$lowercase} &&
			$tokens[$k]  =~ /^(\#SENT\#|\<blank\>|\"|\“|\«|\.|\-|\s|\¿|\¡|\?|\!|\:|\`\`)$/) || ($i==0) ) { ##começa por maiúscula e vai a principio de frase 
			#$token = lowercase ($tokens[$i]);
			# print STDERR "2TOKEN::: lowercase: #$lowercase# -- token: #$tokens[$i]# --  token_prev: #$tokens[$k]# --  post:#$tokens[$j]#--- #$Tag{$tokens[$i]}#\n" if ($tokens[$i] eq "De");       
			if (!$Lemma::Lex->{$lowercase} || $Lemma::Ambig{$lowercase}) {
				#print STDERR "--AMBIG::: #$lowercase#\n";
				$Tag{$tokens[$i]} = "NP00000"; 
				#print STDERR "OKKKK::: lowercase: #$lowercase# -- token: #$tokens[$i]# --  token_prev: #$tokens[$k]#  --  post:#$tokens[$j]#\n" ;       
			}
			#print STDERR "##$tokens[$i]## -  #$tokens[$k]#\n" if ($tokens[$i] eq "De");
		}
		## if   ( $tokens[$i] =~ /^$Lemma::UpperCase$Lemma::LowerCase+/ && ($Lemma::StopWords->{$lowercase} && ($tokens[$k]  =~ /^(\#SENT\#|\<blank\>|\"|\“|\«|\.|\-|\s|\¿|\¡)$/) || ($i==0)) ) {   }##se em principio de frase a palavra maiuscula e uma stopword, nao fazemos nada

		if   ( ($tokens[$i] =~ /^$Lemma::UpperCase$Lemma::LowerCase+/ && $Lemma::Lex->{$lowercase} &&  !$Lemma::Ambig{$lowercase}) && ($tokens[$k]  =~ /^(\#SENT\#|\<blank\>|\"|\“|\«|\.|\-|\s|\¿|\¡|\?|\!|\:|\`\`)$/ || $i==0) ) {  
			#print  STDERR "1TOKEN::: ##$lowercase## // #!$Lemma::Ambig{$lowercase}# - - #$Tag{$tokens[$i]}# --  #$tokens[$k]#\n" ;      
		}##se em principio de frase a palavra maiuscula e está no lexico sem ser ambigua, nao fazemos nada
		##se não lhe foi assigado o tag NP, entao UNK (provisional)
		if (! $Tag{$tokens[$i]}) {
			$Tag{$tokens[$i]} = "UNK" ; 
		}
                ##Numeros romanos 
                elsif ($tokens[$i] =~ /^$Lemma::UpperCase/ && $Lemma::Entry->{$tokens[$i]} =~ / Z$/) {
                    $Tag{$tokens[$i]} = $Lemma::Entry->{$tokens[$i]};
                    #print STDERR "OKK $tokens[$i] - #$Tag{$tokens[$i]}#\n";
                }
		##se é UNK (é dizer nao é NP), entao vamos buscar no lexico
		if ($Tag{$tokens[$i]} eq "UNK") {
			$token = lowercase ($tokens[$i]);
			#print STDERR "2--: $tokens[$i] - $Tag{$tokens[$i]}\n";
			if ($Lemma::Lex->{$token}) {
				$Tag{$tokens[$i]} = $Lemma::Entry->{$token};
				#print STDERR "3--: $tokens[$i] - $Tag{$tokens[$i]}\n";
			}elsif ($tokens[$i] =~ /\-/) { ##se o token é composto, dever ser um sustantivo
				$Tag{$tokens[$i]} = "$tokens[$i] NC00000";
			}
		}elsif ($Tag{$tokens[$i]} eq "NP00000") {
			$token = lowercase ($tokens[$i]); 
		} 
		##os numeros, medidas e datas #USAR O FICHEIRO QUANTITIES.DAT##################

		##CIFRAS OU NUMEROS
		 if ($tokens[$i] =~ /[0-9]+/ || $tokens[$i] =~ /^$Lemma::cifra$/) {
			$token = $tokens[$i];
			$Tag{$tokens[$i]} = "Z"; 
		}         

		#agora etiquetamos os simbolos de puntuaçao
		if ($tokens[$i] eq "\.") {
			$token = "\.";
			$Tag{$tokens[$i]} = "Fp"; 
		}elsif ($tokens[$i] eq "#SENT#" && $tokens[$i-1] ne "\." && $tokens[$i-1] ne "<blank>" ){
			# print STDERR "--- #$tokens[$i]# #$tokens[$i-1]#\n";
			$tokens[$i] = "<blank>";
			$token = "<blank>";
			$Tag{$tokens[$i]} = "Fp"; 
		}elsif ($tokens[$i] =~ /^$Lemma::Punct$/ || $tokens[$i] =~ /^$Lemma::Punct_urls$/ || 
			$tokens[$i] =~ /^(\.\.\.|\`\`|\'\'|\<\<|\>\>|\-\-)$/ ) {
			$Tag{$tokens[$i]} = punct ($tokens[$i]);
			$token = $tokens[$i]; 
			#print STDERR "token: #$token# -- #$tokens[$i]# -- #$Tag{$tokens[$i]}# \n";
		}
		 
		##as linhas em branco eliminam-se 
		if ($tokens[$i] eq  "#SENT#") {
			next;
		}
  
		##parte final..
		my $tag = $Tag{$tokens[$i]};#<string>
		$tag= $token . " " . $tag if ( $tag =~ /^(UNK|F|NP|Z|W)/  );
		push (@saida, "$tokens[$i] ".$tag);
		if($Tag{$tokens[$i]} eq "Fp"){
			push (@saida, "");
		}

		$Tag{$tokens[$i]} = "";
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

	for (my $i=0; $i<=$#lines; $i++) {
		chomp $lines[$i];
	}

	lemma(\@lines);
}
#<ignore-block>


###OUTRAS FUNÇOES

sub punct {
	my ($p) = @_ ;#<string>
	my $result;#<string>

	if ($p eq "\.") {
		$result = "Fp"; 
	}elsif ($p eq "\,") {
		$result = "Fc"; 
	}elsif ($p eq "\:") {
		$result = "Fd"; 
	}elsif ($p eq "\;") {
		$result = "Fx"; 
	}elsif ($p =~ /^(\-|\-\-)$/) {
		$result = "Fg"; 
	}elsif ($p =~ /^(\'|\"|\`\`|\'\')$/) {
		$result = "Fe"; 
	}elsif ($p eq "\.\.\.") {
		$result = "Fs"; 
	}elsif ($p =~ /^(\<\<|«|\“)/) {
		$result = "Fra"; 
	}elsif ($p =~ /^(\>\>|»|\”)/) {
		$result = "Frc"; 
	}elsif ($p eq "\%") {
		$result = "Ft"; 
	}elsif ($p =~ /^(\/|\\)$/) {
		$result = "Fh"; 
	}elsif ($p eq "\(") {
		$result = "Fpa"; 
	}elsif ($p eq "\)") {
		$result = "Fpt"; 
	}elsif ($p eq "\¿") {
		$result = "Fia"; 
	}elsif ($p eq "\?") {
		$result = "Fit"; 
	}elsif ($p eq "\¡") {
		$result = "Faa"; 
	}elsif ($p eq "\!") {
		$result = "Fat"; 
	}elsif ($p eq "\[") {
		$result = "Fca"; 
	}elsif ($p eq "\]") {
		$result = "Fct"; 
	}elsif ($p eq "\{") {
		$result = "Fla"; 
	}elsif ($p eq "\}") {
		$result = "Flt"; 
	}elsif ($p eq "\…") {
		$result = "Fz"; 
	}elsif ($p =~ /^[\+\*\#\&]$/) {
		$result = "Fz"; 
	}
	return $result;
}

sub lowercase {
	my ($x) = @_ ;#<string>
	$x = lc ($x);
	$x =~  tr/ÁÉÍÓÚÇÑ/áéíóúçñ/;

	return $x;    
}

sub Trim {
	my ($x) = @_ ;#<string>

	$x =~ s/^[\s]*//;  
	$x =~ s/[\s]$//;  

	return $x;
}
       
