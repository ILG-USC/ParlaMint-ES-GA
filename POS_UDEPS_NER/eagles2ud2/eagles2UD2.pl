#!/usr/bin/perl

# Converte um corpus EAGLES (FreeLing/LinguaKit) em formato UDv2 (CoNLL-U)
# cat corpus_fl.txt | ./eagles2UD2.pl -iln > corpus_UD.txt

#use experimental 'autoderef';
binmode STDIN, ':utf8';
binmode STDOUT, ':utf8';
use utf8;

use Getopt::Std;
$Getopt::Std::STANDARD_HELP_VERSION = 1;
our($opt_s, $opt_e, $opt_g, $opt_p, $opt_f, $opt_l, $opt_j, $opt_n);
getopts('segpflnj');

sub HELP_MESSAGE {
    my $fh = shift;
    print $fh "Usage: cat corpus_eagles.txt | ./eagles2UD2.pl [options] > output_ud2.conllu\n\n";
    print $fh "\tOptions:\n";
    print $fh "\t-f \tFreeLing (>v3), with differences in some tagsets\n";
    print $fh "\t-l \tLinguaKit (or FreeLing<=v3\n\n";
    print $fh "\t-p \tPortuguese\n";
    print $fh "\t-g \tGalician\n";
    print $fh "\t-s \tSpanish\n";
    print $fh "\t-e \tEnglish\n\n";
    print $fh "\t-j \tKeep complex proper nouns as single tokens\n";
    print $fh "\t-n \tSplits complex proper nouns\n\n";
}

sub VERSION_MESSAGE {
    my $fh = shift;
    print $fh "\nEAGLES to UDv2 0.2\n";
}

# Invalid options > prints the help
if ( (!$opt_e && !$opt_p && !$opt_g && !$opt_s) ||
     ($opt_e && ($opt_p || $opt_g || $opt_s)) ||
     ($opt_p && ($opt_e || $opt_g || $opt_s)) ||
     ($opt_g && ($opt_e || $opt_p || $opt_s)) ||
     (!$opt_j && !$opt_n) ||
     ($opt_j && $opt_n) ||
     (!$opt_l && !$opt_f) ||
     ($opt_f && $opt_l) ) {
    HELP_MESSAGE(*STDOUT);
    exit(1);
}

############
# Conversion
############

# Comuns a FL/LK e línguas (menos inglês)
if (!$opt_e) {
    our $info = {
	# Prepositions
	"SPS00" => {
	    tag => "ADP",
	    feats => ["AdpType=Prep"],
	},
	"SP" => {
	    tag => "ADP",
	    feats => ["AdpType=Prep"],
	},
	# Numbers
	"Z" => {
	    tag => "NUM",
	    feats => ["NumType=Card"],
	},
	# Adverbs
	"RG" => {
	    tag => "ADV",
	    feats => [],
	},
	"RN" => {
	    tag => "ADV",
	    feats => ["Polarity=Neg"],
	},
	# Conjuctions
	"CC" => {
	    tag => "CCONJ",
	    feats => [],
	},
	"CS" => {
	    tag => "SCONJ",
	    feats => [],
	},
	# Determiners: articles
	"DA0FS0" => {
	    tag => "DET",
	    feats => ["Definite=Def", "Gender=Fem", "Number=Sing", "PronType=Art"],
	},
	"DA0FP0" => {
	    tag => "DET",
	    feats => ["Definite=Def", "Gender=Fem", "Number=Plur", "PronType=Art"],
	},
	"DA0MS0" => {
	    tag => "DET",
	    feats => ["Definite=Def", "Gender=Masc", "Number=Sing", "PronType=Art"],
	},
	"DA0MP0" => {
	    tag => "DET",
	    feats => ["Definite=Def", "Gender=Masc", "Number=Plur", "PronType=Art"],
	},
	"DA0CS0" => {
	    tag => "DET",
	    feats => ["Definite=Def", "Gender=Com", "Number=Sing", "PronType=Art"],
	},
	"DA0NS0" => {
	    tag => "DET",
	    feats => ["Definite=Def", "Gender=Neut", "Number=Sing", "PronType=Art"],
	},
	"DA0CP0" => {
	    tag => "DET",
	    feats => ["Definite=Def", "Gender=Com", "Number=Plur", "PronType=Art"],
	},
	"DA0CN0" => {
	    tag => "DET",
	    feats => ["Definite=Def", "Gender=Com", "PronType=Art"],
	},
	"DA0MN0" => {
	    tag => "DET",
	    feats => ["Definite=Def", "Gender=Masc", "PronType=Art"],
	},
	"DA0FN0" => {
	    tag => "DET",
	    feats => ["Definite=Def", "Gender=Fem", "PronType=Art"],
	},
	"DA00S0" => {
	    tag => "DET",
	    feats => ["Definite=Def", "Number=Sing", "PronType=Art"],
	},
	# Determiners: indefinites
	"DI0FS0" => {
	    tag => "DET",
	    feats => ["Definite=Ind", "Gender=Fem", "Number=Sing", "PronType=Art"],
	},
	"DI0FP0" => {
	    tag => "DET",
	    feats => ["Definite=Ind", "Gender=Fem", "Number=Plur", "PronType=Art"],
	},
	"DI0MS0" => {
	    tag => "DET",
	    feats => ["Definite=Ind", "Gender=Masc", "Number=Sing", "PronType=Art"],
	},
	"DI0MP0" => {
	    tag => "DET",
	    feats => ["Definite=Ind", "Gender=Masc", "Number=Plur", "PronType=Art"],
	},
	"DI0CS0" => {
	    tag => "DET",
	    feats => ["Definite=Ind", "Gender=Com", "Number=Sing", "PronType=Art"],
	},
	"DI0CP0" => {
	    tag => "DET",
	    feats => ["Definite=Ind", "Gender=Com", "Number=Plur", "PronType=Art"],
	},
	"DI0CN0" => {
	    tag => "DET",
	    feats => ["Definite=Ind", "Gender=Com", "PronType=Art"],
	},
	"DI0NN0" => {
	    tag => "DET",
	    feats => ["Definite=Ind", "Gender=Neut", "PronType=Art"],
	},
	"DI0MN0" => {
	    tag => "DET",
	    feats => ["Definite=Ind", "Gender=Masc", "PronType=Art"],
	},
	"DI0FN0" => {
	    tag => "DET",
	    feats => ["Definite=Ind", "Gender=Fem", "PronType=Art"],
	},
	# Determiners: demonstratives
	"DD0FS0" => {
	    tag => "DET",
	    feats => ["Definite=Def", "Gender=Fem", "Number=Sing", "PronType=Dem"],
	},
	"DD0FP0" => {
	    tag => "DET",
	    feats => ["Definite=Def", "Gender=Fem", "Number=Plur", "PronType=Dem"],
	},
	"DD0MS0" => {
	    tag => "DET",
	    feats => ["Definite=Def", "Gender=Masc", "Number=Sing", "PronType=Dem"],
	},
	"DD0MP0" => {
	    tag => "DET",
	    feats => ["Definite=Def", "Gender=Masc", "Number=Plur", "PronType=Dem"],
	},
	"DD0CS0" => {
	    tag => "DET",
	    feats => ["Definite=Def", "Gender=Com", "Number=Sing", "PronType=Dem"],
	},
	"DD0CP0" => {
	    tag => "DET",
	    feats => ["Definite=Def", "Gender=Com", "Number=Plur", "PronType=Dem"],
	},
	"DD0CN0" => {
	    tag => "DET",
	    feats => ["Definite=Def", "Gender=Com", "PronType=Dem"],
	},
	"DD0MN0" => {
	    tag => "DET",
	    feats => ["Definite=Def", "Gender=Masc", "PronType=Dem"],
	},
	"DD0FN0" => {
	    tag => "DET",
	    feats => ["Definite=Def", "Gender=Fem", "PronType=Dem"],
	},
	# Determiners: possessives
	"DP0FS0" => {
	    tag => "DET",
	    feats => ["Definite=Def", "Gender=Fem", "Number=Sing", "Poss=Yes"],
	},
	"DP0FP0" => {
	    tag => "DET",
	    feats => ["Definite=Def", "Gender=Fem", "Number=Plur", "Poss=Yes"],
	},
	"DP0MS0" => {
	    tag => "DET",
	    feats => ["Definite=Def", "Gender=Masc", "Number=Sing", "Poss=Yes"],
	},
	"DP0MP0" => {
	    tag => "DET",
	    feats => ["Definite=Def", "Gender=Masc", "Number=Plur", "Poss=Yes"],
	},
	"DP0CS0" => {
	    tag => "DET",
	    feats => ["Definite=Def", "Gender=Com", "Number=Sing", "Poss=Yes"],
	},
	"DP0CP0" => {
	    tag => "DET",
	    feats => ["Definite=Def", "Gender=Com", "Number=Plur", "Poss=Yes"],
	},
	"DP0CN0" => {
	    tag => "DET",
	    feats => ["Definite=Def", "Gender=Com", "Poss=Yes"],
	},
	"DP0MN0" => {
	    tag => "DET",
	    feats => ["Definite=Def", "Gender=Masc", "Poss=Yes"],
	},
	"DP0FN0" => {
	    tag => "DET",
	    feats => ["Definite=Def", "Gender=Fem", "Poss=Yes"],
	},
	"DP1FS0" => {
	    tag => "DET",
	    feats => ["Definite=Def", "Gender=Fem", "Number=Sing", "Person=1", "Poss=Yes"],
	},
	"DP1FP0" => {
	    tag => "DET",
	    feats => ["Definite=Def", "Gender=Fem", "Number=Plur", "Person=1", "Poss=Yes"],
	},
	"DP1MS0" => {
	    tag => "DET",
	    feats => ["Definite=Def", "Gender=Masc", "Number=Sing", "Person=1", "Poss=Yes"],
	},
	"DP1MP0" => {
	    tag => "DET",
	    feats => ["Definite=Def", "Gender=Masc", "Number=Plur", "Person=1", "Poss=Yes"],
	},
	"DP1CS0" => {
	    tag => "DET",
	    feats => ["Definite=Def", "Gender=Com", "Number=Sing", "Person=1", "Poss=Yes"],
	},
	"DP1CP0" => {
	    tag => "DET",
	    feats => ["Definite=Def", "Gender=Com", "Number=Plur", "Person=1", "Poss=Yes"],
	},
	"DP1CN0" => {
	    tag => "DET",
	    feats => ["Definite=Def", "Gender=Com", "Person=1", "Poss=Yes"],
	},
	"DP1MN0" => {
	    tag => "DET",
	    feats => ["Definite=Def", "Gender=Masc", "Person=1", "Poss=Yes"],
	},
	"DP1FN0" => {
	    tag => "DET",
	    feats => ["Definite=Def", "Gender=Fem", "Person=1", "Poss=Yes"],
	},
	"DP2FS0" => {
	    tag => "DET",
	    feats => ["Definite=Def", "Gender=Fem", "Number=Sing", "Person=2", "Poss=Yes"],
	},
	"DP2FP0" => {
	    tag => "DET",
	    feats => ["Definite=Def", "Gender=Fem", "Number=Plur", "Person=2", "Poss=Yes"],
	},
	"DP2MS0" => {
	    tag => "DET",
	    feats => ["Definite=Def", "Gender=Masc", "Number=Sing", "Person=2", "Poss=Yes"],
	},
	"DP2MP0" => {
	    tag => "DET",
	    feats => ["Definite=Def", "Gender=Masc", "Number=Plur", "Person=2", "Poss=Yes"],
	},
	"DP2CS0" => {
	    tag => "DET",
	    feats => ["Definite=Def", "Gender=Com", "Number=Sing", "Person=2", "Poss=Yes"],
	},
	"DP2CP0" => {
	    tag => "DET",
	    feats => ["Definite=Def", "Gender=Com", "Number=Plur", "Person=2", "Poss=Yes"],
	},
	"DP2CN0" => {
	    tag => "DET",
	    feats => ["Definite=Def", "Gender=Com", "Person=2", "Poss=Yes"],
	},
	"DP2MN0" => {
	    tag => "DET",
	    feats => ["Definite=Def", "Gender=Masc", "Person=2", "Poss=Yes"],
	},
	"DP2FN0" => {
	    tag => "DET",
	    feats => ["Definite=Def", "Gender=Fem", "Person=2", "Poss=Yes"],
	},
	"DP3FS0" => {
	    tag => "DET",
	    feats => ["Definite=Def", "Gender=Fem", "Number=Sing", "Person=3", "Poss=Yes"],
	},
	"DP3FP0" => {
	    tag => "DET",
	    feats => ["Definite=Def", "Gender=Fem", "Number=Plur", "Person=3", "Poss=Yes"],
	},
	"DP3MS0" => {
	    tag => "DET",
	    feats => ["Definite=Def", "Gender=Masc", "Number=Sing", "Person=3", "Poss=Yes"],
	},
	"DP3MP0" => {
	    tag => "DET",
	    feats => ["Definite=Def", "Gender=Masc", "Number=Plur", "Person=3", "Poss=Yes"],
	},
	"DP3CS0" => {
	    tag => "DET",
	    feats => ["Definite=Def", "Gender=Com", "Number=Sing", "Person=3", "Poss=Yes"],
	},
	"DP3CP0" => {
	    tag => "DET",
	    feats => ["Definite=Def", "Gender=Com", "Number=Plur", "Person=3", "Poss=Yes"],
	},
	"DP3CN0" => {
	    tag => "DET",
	    feats => ["Definite=Def", "Gender=Com", "Person=3", "Poss=Yes"],
	},
	"DP3MN0" => {
	    tag => "DET",
	    feats => ["Definite=Def", "Gender=Masc", "Person=3", "Poss=Yes"],
	},
	"DP3FN0" => {
	    tag => "DET",
	    feats => ["Definite=Def", "Gender=Fem", "Person=3", "Poss=Yes"],
	},
	"DP1FPP" => {
	    tag => "DET",
	    feats => ["Poss=Yes", "Person=1", "Number[psor]=Plur", "Gender=Fem", "Number=Plur"],
	},
	"DP1FPS" => {
	    tag => "DET",
	    feats => ["Poss=Yes", "Person=1", "Number[psor]=Sing", "Gender=Fem", "Number=Plur"],
	},
	"DP1FSP" => {
	    tag => "DET",
	    feats => ["Poss=Yes", "Person=1", "Number[psor]=Plur", "Gender=Fem", "Number=Sing"],
	},
	"DP1FSS" => {
	    tag => "DET",
	    feats => ["Poss=Yes", "Person=1", "Number[psor]=Sing", "Gender=Fem", "Number=Sing"],
	},
	"DP1MPP" => {
	    tag => "DET",
	    feats => ["Poss=Yes", "Person=1", "Number[psor]=Plur", "Gender=Masc", "Number=Plur"],
	},
	"DP1MPS" => {
	    tag => "DET",
	    feats => ["Poss=Yes", "Person=1", "Number[psor]=Sing", "Gender=Masc", "Number=Plur"],
	},
	"DP1MSP" => {
	    tag => "DET",
	    feats => ["Poss=Yes", "Person=1", "Number[psor]=Plur", "Gender=Masc", "Number=Sing"],
	},
	"DP1MSS" => {
	    tag => "DET",
	    feats => ["Poss=Yes", "Person=1", "Number[psor]=Sing", "Gender=Masc", "Number=Sing"],
	},
	"DP2FPP" => {
	    tag => "DET",
	    feats => ["Poss=Yes", "Person=2", "Number[psor]=Plur", "Gender=Fem", "Number=Plur"],
	},
	"DP2FPS" => {
	    tag => "DET",
	    feats => ["Poss=Yes", "Person=2", "Number[psor]=Sing", "Gender=Fem", "Number=Plur"],
	},
	"DP2FSP" => {
	    tag => "DET",
	    feats => ["Poss=Yes", "Person=2", "Number[psor]=Plur", "Gender=Fem", "Number=Sing"],
	},
	"DP2FSS" => {
	    tag => "DET",
	    feats => ["Poss=Yes", "Person=2", "Number[psor]=Sing", "Gender=Fem", "Number=Sing"],
	},
	"DP2MPP" => {
	    tag => "DET",
	    feats => ["Poss=Yes", "Person=2", "Number[psor]=Plur", "Gender=Masc", "Number=Plur"],
	},
	"DP2MPS" => {
	    tag => "DET",
	    feats => ["Poss=Yes", "Person=2", "Number[psor]=Sing", "Gender=Masc", "Number=Plur"],
	},
	"DP2MSP" => {
	    tag => "DET",
	    feats => ["Poss=Yes", "Person=2", "Number[psor]=Plur", "Gender=Masc", "Number=Sing"],
	},
	"DP2MSS" => {
	    tag => "DET",
	    feats => ["Poss=Yes", "Person=2", "Number[psor]=Sing", "Gender=Masc", "Number=Sing"],
	},
	"DP3FPP" => {
	    tag => "DET",
	    feats => ["Poss=Yes", "Person=3", "Number[psor]=Plur", "Gender=Fem", "Number=Plur"],
	},
	"DP3FPS" => {
	    tag => "DET",
	    feats => ["Poss=Yes", "Person=3", "Number[psor]=Sing", "Gender=Fem", "Number=Plur"],
	},
	"DP3FSP" => {
	    tag => "DET",
	    feats => ["Poss=Yes", "Person=3", "Number[psor]=Plur", "Gender=Fem", "Number=Sing"],
	},
	"DP3FSS" => {
	    tag => "DET",
	    feats => ["Poss=Yes", "Person=3", "Number[psor]=Sing", "Gender=Fem", "Number=Sing"],
	},
	"DP3MPP" => {
	    tag => "DET",
	    feats => ["Poss=Yes", "Person=3", "Number[psor]=Plur", "Gender=Masc", "Number=Plur"],
	},
	"DP3MPS" => {
	    tag => "DET",
	    feats => ["Poss=Yes", "Person=3", "Number[psor]=Sing", "Gender=Masc", "Number=Plur"],
	},
	"DP3MSP" => {
	    tag => "DET",
	    feats => ["Poss=Yes", "Person=3", "Number[psor]=Plur", "Gender=Masc", "Number=Sing"],
	},
	"DP3MSS" => {
	    tag => "DET",
	    feats => ["Poss=Yes", "Person=3", "Number[psor]=Sing", "Gender=Masc", "Number=Sing"],
	},
	"DP3CSN" => {
	    tag => "DET",
	    feats => ["Poss=Yes", "Person=3", "Gender=Masc", "Number=Sing"],
	},
	"DP3CPN" => {
	    tag => "DET",
	    feats => ["Poss=Yes", "Person=3", "Gender=Masc", "Number=Plur"],
	},
	"DP2CSS" => {
	    tag => "DET",
	    feats => ["Poss=Yes", "Person=2", "Number[psor]=Sing", "Gender=Masc", "Number=Sing"],
	},
	"DP2CPS" => {
	    tag => "DET",
	    feats => ["Poss=Yes", "Person=2", "Number[psor]=Sing", "Gender=Masc", "Number=Plur"],
	},
	"DP1CSS" => {
	    tag => "DET",
	    feats => ["Poss=Yes", "Person=1", "Number[psor]=Sing", "Gender=Masc", "Number=Sing"],
	},
	"DP1CPS" => {
	    tag => "DET",
	    feats => ["Poss=Yes", "Person=1", "Number[psor]=Sing", "Gender=Masc", "Number=Plur"],
	},
	# Determiners: interrogatives
	"DT0FS0" => {
	    tag => "DET",
	    feats => ["Gender=Fem", "Number=Sing", "PronType=Int"],
	},
	"DT0FP0" => {
	    tag => "DET",
	    feats => ["Gender=Fem", "Number=Plur", "PronType=Int"],
	},
	"DT0MS0" => {
	    tag => "DET",
	    feats => ["Gender=Masc", "Number=Sing", "PronType=Int"],
	},
	"DT0MP0" => {
	    tag => "DET",
	    feats => ["Gender=Masc", "Number=Plur", "PronType=Int"],
	},
	"DT0CS0" => {
	    tag => "DET",
	    feats => ["Gender=Com", "Number=Sing", "PronType=Int"],
	},
	"DT0CP0" => {
	    tag => "DET",
	    feats => ["Gender=Com", "Number=Plur", "PronType=Int"],
	},
	"DT0CN0" => {
	    tag => "DET",
	    feats => ["Gender=Com", "PronType=Int"],
	},
	"DT0MN0" => {
	    tag => "DET",
	    feats => ["Gender=Masc", "PronType=Int"],
	},
	"DT0FN0" => {
	    tag => "DET",
	    feats => ["Gender=Fem", "PronType=Int"],
	},
	# Determiners: exclamatives
	"DE0FS0" => {
	    tag => "DET",
	    feats => ["Gender=Fem", "Number=Sing", "PronType=Exc"],
	},
	"DE0FP0" => {
	    tag => "DET",
	    feats => ["Gender=Fem", "Number=Plur", "PronType=Exc"],
	},
	"DE0MS0" => {
	    tag => "DET",
	    feats => ["Gender=Masc", "Number=Sing", "PronType=Exc"],
	},
	"DE0MP0" => {
	    tag => "DET",
	    feats => ["Gender=Masc", "Number=Plur", "PronType=Exc"],
	},
	"DE0CS0" => {
	    tag => "DET",
	    feats => ["Gender=Com", "Number=Sing", "PronType=Exc"],
	},
	"DE0CP0" => {
	    tag => "DET",
	    feats => ["Gender=Com", "Number=Plur", "PronType=Exc"],
	},
	"DE0CN0" => {
	    tag => "DET",
	    feats => ["Gender=Com", "PronType=Exc"],
	},
	"DE0MN0" => {
	    tag => "DET",
	    feats => ["Gender=Masc", "PronType=Exc"],
	},
	"DE0FN0" => {
	    tag => "DET",
	    feats => ["Gender=Fem", "PronType=Exc"],
	},
	# Adjectives: qualificatives
	"AQ0MS0" => {
	    tag => "ADJ",
	    feats => ["Gender=Masc", "Number=Sing"],
	},
	"AQ0MP0" => {
	    tag => "ADJ",
	    feats => ["Gender=Masc", "Number=Plur"],
	},
	"AQ0FS0" => {
	    tag => "ADJ",
	    feats => ["Gender=Fem", "Number=Sing"],
	},
	"AQ0FP0" => {
	    tag => "ADJ",
	    feats => ["Gender=Fem", "Number=Plur"],
	},
	"AQ0CS0" => {
	    tag => "ADJ",
	    feats => ["Gender=Com", "Number=Sing"],
	},
	"AQ0CP0" => {
	    tag => "ADJ",
	    feats => ["Gender=Com", "Number=Plur"],
	},
	# Adjectives: ordinal numbers
	"AO0MS0" => {
	    tag => "NUM",
	    feats => ["Gender=Masc", "Number=Sing", "NumType=Ord"],
	},
	"AO0MP0" => {
	    tag => "NUM",
	    feats => ["Gender=Masc", "Number=Plur", "NumType=Ord"],
	},
	"AO0FS0" => {
	    tag => "NUM",
	    feats => ["Gender=Fem", "Number=Sing", "NumType=Ord"],
	},
	"AO0FP0" => {
	    tag => "NUM",
	    feats => ["Gender=Fem", "Number=Plur", "NumType=Ord"],
	},
	"AO0CS0" => {
	    tag => "NUM",
	    feats => ["Gender=Com", "Number=Sing", "NumType=Ord"],
	},
	"AO0CP0" => {
	    tag => "NUM",
	    feats => ["Gender=Com", "Number=Plur", "NumType=Ord"],
	},
	# Special
	"AT0MP0" => {
	    tag => "PRON",
	    feats => ["PronType=Int", "Gender=Masc", "Number=Plur"],
	},
	# Adjectives: possessives > Pronouns
	"AP0MS00" => {
	    tag => "PRON",
	    feats => ["Poss=Yes", "Gender=Masc", "Number=Sing"],
	},
	"AP0MP00" => {
	    tag => "PRON",
	    feats => ["Poss=Yes", "Gender=Masc", "Number=Plur"],
	},
	"AP0FS00" => {
	    tag => "PRON",
	    feats => ["Poss=Yes", "Gender=Fem", "Number=Sing"],
	},
	"AP0FP00" => {
	    tag => "PRON",
	    feats => ["Poss=Yes", "Gender=Fem", "Number=Plur"],
	},
	"AP0MS1N" => {
	    tag => "PRON",
	    feats => ["Poss=Yes", "Gender=Masc", "Number=Sing", "Person=1"],
	},
	"AP0MS2N" => {
	    tag => "PRON",
	    feats => ["Poss=Yes", "Gender=Masc", "Number=Sing", "Person=2"],
	},
	"AP0MS3N" => {
	    tag => "PRON",
	    feats => ["Poss=Yes", "Gender=Masc", "Number=Sing", "Person=3"],
	},
	"AP0MP1N" => {
	    tag => "PRON",
	    feats => ["Poss=Yes", "Gender=Masc", "Number=Plur", "Person=1"],
	},
	"AP0MP2N" => {
	    tag => "PRON",
	    feats => ["Poss=Yes", "Gender=Masc", "Number=Plur", "Person=2"],
	},
	"AP0MP3N" => {
	    tag => "PRON",
	    feats => ["Poss=Yes", "Gender=Masc", "Number=Plur", "Person=3"],
	},
	"AP0MS1S" => {
	    tag => "PRON",
	    feats => ["Poss=Yes", "Gender=Masc", "Number=Sing", "Number[psor]=Sing", "Person=1"],
	},
	"AP0MS2S" => {
	    tag => "PRON",
	    feats => ["Poss=Yes", "Gender=Masc", "Number=Sing", "Number[psor]=Sing", "Person=2"],
	},
	"AP0MS3S" => {
	    tag => "PRON",
	    feats => ["Poss=Yes", "Gender=Masc", "Number=Sing", "Number[psor]=Sing", "Person=3"],
	},
	"AP0MP1S" => {
	    tag => "PRON",
	    feats => ["Poss=Yes", "Gender=Masc", "Number=Plur", "Number[psor]=Sing", "Person=1"],
	},
	"AP0MP2S" => {
	    tag => "PRON",
	    feats => ["Poss=Yes", "Gender=Masc", "Number=Plur", "Number[psor]=Sing", "Person=2"],
	},
	"AP0MP3S" => {
	    tag => "PRON",
	    feats => ["Poss=Yes", "Gender=Masc", "Number=Plur", "Number[psor]=Sing", "Person=3"],
	},
	"AP0MS1P" => {
	    tag => "PRON",
	    feats => ["Poss=Yes", "Gender=Masc", "Number=Sing", "Number[psor]=Plur", "Person=1"],
	},
	"AP0MS2P" => {
	    tag => "PRON",
	    feats => ["Poss=Yes", "Gender=Masc", "Number=Sing", "Number[psor]=Plur", "Person=2"],
	},
	"AP0MS3P" => {
	    tag => "PRON",
	    feats => ["Poss=Yes", "Gender=Masc", "Number=Sing", "Number[psor]=Plur", "Person=3"],
	},
	"AP0MP1P" => {
	    tag => "PRON",
	    feats => ["Poss=Yes", "Gender=Masc", "Number=Plur", "Number[psor]=Plur", "Person=1"],
	},
	"AP0MP2P" => {
	    tag => "PRON",
	    feats => ["Poss=Yes", "Gender=Masc", "Number=Plur", "Number[psor]=Plur", "Person=2"],
	},
	"AP0MP3P" => {
	    tag => "PRON",
	    feats => ["Poss=Yes", "Gender=Masc", "Number=Plur", "Number[psor]=Plur", "Person=3"],
	},
	"AP0FS1N" => {
	    tag => "PRON",
	    feats => ["Poss=Yes", "Gender=Fem", "Number=Sing", "Person=1"],
	},
	"AP0FS2N" => {
	    tag => "PRON",
	    feats => ["Poss=Yes", "Gender=Fem", "Number=Sing", "Person=2"],
	},
	"AP0MS3N" => {
	    tag => "PRON",
	    feats => ["Poss=Yes", "Gender=Fem", "Number=Sing", "Person=3"],
	},
	"AP0FP1N" => {
	    tag => "PRON",
	    feats => ["Poss=Yes", "Gender=Fem", "Number=Plur", "Person=1"],
	},
	"AP0FP2N" => {
	    tag => "PRON",
	    feats => ["Poss=Yes", "Gender=Fem", "Number=Plur", "Person=2"],
	},
	"AP0FP3N" => {
	    tag => "PRON",
	    feats => ["Poss=Yes", "Gender=Fem", "Number=Plur", "Person=3"],
	},
	"AP0FS1S" => {
	    tag => "PRON",
	    feats => ["Poss=Yes", "Gender=Fem", "Number=Sing", "Number[psor]=Sing", "Person=1"],
	},
	"AP0FS2S" => {
	    tag => "PRON",
	    feats => ["Poss=Yes", "Gender=Fem", "Number=Sing", "Number[psor]=Sing", "Person=2"],
	},
	"AP0FS3S" => {
	    tag => "PRON",
	    feats => ["Poss=Yes", "Gender=Fem", "Number=Sing", "Number[psor]=Sing", "Person=3"],
	},
	"AP0FP1S" => {
	    tag => "PRON",
	    feats => ["Poss=Yes", "Gender=Fem", "Number=Plur", "Number[psor]=Sing", "Person=1"],
	},
	"AP0FP2S" => {
	    tag => "PRON",
	    feats => ["Poss=Yes", "Gender=Fem", "Number=Plur", "Number[psor]=Sing", "Person=2"],
	},
	"AP0FP3S" => {
	    tag => "PRON",
	    feats => ["Poss=Yes", "Gender=Fem", "Number=Plur", "Number[psor]=Sing", "Person=3"],
	},
	"AP0FS1P" => {
	    tag => "PRON",
	    feats => ["Poss=Yes", "Gender=Fem", "Number=Sing", "Number[psor]=Plur", "Person=1"],
	},
	"AP0FS2P" => {
	    tag => "PRON",
	    feats => ["Poss=Yes", "Gender=Fem", "Number=Sing", "Number[psor]=Plur", "Person=2"],
	},
	"AP0FS3P" => {
	    tag => "PRON",
	    feats => ["Poss=Yes", "Gender=Fem", "Number=Sing", "Number[psor]=Plur", "Person=3"],
	},
	"AP0FP1P" => {
	    tag => "PRON",
	    feats => ["Poss=Yes", "Gender=Fem", "Number=Plur", "Number[psor]=Plur", "Person=1"],
	},
	"AP0FP2P" => {
	    tag => "PRON",
	    feats => ["Poss=Yes", "Gender=Fem", "Number=Plur", "Number[psor]=Plur", "Person=2"],
	},
	"AP0FP3P" => {
	    tag => "PRON",
	    feats => ["Poss=Yes", "Gender=Fem", "Number=Plur", "Number[psor]=Plur", "Person=3"],
	},
	# Nouns: common
	"NCMS000" => {
	    tag => "NOUN",
	    feats => ["Gender=Masc", "Number=Sing"],
	},
	"NCMP000" => {
	    tag => "NOUN",
	    feats => ["Gender=Masc", "Number=Plur"],
	},
	"NCFS000" => {
	    tag => "NOUN",
	    feats => ["Gender=Fem", "Number=Sing"],
	},
	"NCFP000" => {
	    tag => "NOUN",
	    feats => ["Gender=Fem", "Number=Plur"],
	},
	"NCCS000" => {
	    tag => "NOUN",
	    feats => ["Gender=Com", "Number=Sing"],
	},
	"NCCP000" => {
	    tag => "NOUN",
	    feats => ["Gender=Com", "Number=Plur"],
	},
	"NCCN000" => {
	    tag => "NOUN",
	    feats => ["Gender=Com"],
	},
	"NCMN000" => {
	    tag => "NOUN",
	    feats => ["Gender=Masc"],
	},
	"NCMC000" => {
	    tag => "NOUN",
	    feats => ["Gender=Masc"],
	},
	"NCFN000" => {
	    tag => "NOUN",
	    feats => ["Gender=Fem"],
	},
	"NCFC000" => {
	    tag => "NOUN",
	    feats => ["Gender=Fem"],
	},
	# Degree=Dim + Degree=Aug?
	"NCFP00D" => {
	    tag => "NOUN",
	    feats => ["Gender=Fem", "Number=Plur"],
	},
	"NCFS00D" => {
	    tag => "NOUN",
	    feats => ["Gender=Fem", "Number=Sing"],
	},
	"NCMP00D" => {
	    tag => "NOUN",
	    feats => ["Gender=Masc", "Number=Plur"],
	},
	"NCMS00D" => {
	    tag => "NOUN",
	    feats => ["Gender=Masc", "Number=Sing"],
	},
	"NCFP00A" => {
	    tag => "NOUN",
	    feats => ["Gender=Fem", "Number=Plur"],
	},
	"NCFS00A" => {
	    tag => "NOUN",
	    feats => ["Gender=Fem", "Number=Sing"],
	},
	"NCMP00A" => {
	    tag => "NOUN",
	    feats => ["Gender=Masc", "Number=Plur"],
	},
	"NCMS00A" => {
	    tag => "NOUN",
	    feats => ["Gender=Masc", "Number=Sing"],
	},
	"NCCS00D" => {
	    tag => "NOUN",
	    feats => ["Gender=Com", "Number=Sing"],
	},
	"NCCP00D" => {
	    tag => "NOUN",
	    feats => ["Gender=Com", "Number=Plur"],
	},
	"NCCS00A" => {
	    tag => "NOUN",
	    feats => ["Gender=Com", "Number=Sing"],
	},
	"NCCP00A" => {
	    tag => "NOUN",
	    feats => ["Gender=Com", "Number=Plur"],
	},
	# Pronouns: demonstratives
	# last element not necessary if FL>3
	"PD0MS000" => {
	    tag => "PRON",
	    feats => ["Gender=Masc", "Number=Sing", "PronType=Dem"],
	},
	"PD0MP000" => {
	    tag => "PRON",
	    feats => ["Gender=Masc", "Number=Plur", "PronType=Dem"],
	},
	"PD0MN000" => {
	    tag => "PRON",
	    feats => ["Gender=Masc", "PronType=Dem"],
	},
	"PD0FS000" => {
	    tag => "PRON",
	    feats => ["Gender=Fem", "Number=Sing", "PronType=Dem"],
	},
	"PD0FP000" => {
	    tag => "PRON",
	    feats => ["Gender=Fem", "Number=Plur", "PronType=Dem"],
	},
	"PD0FN000" => {
	    tag => "PRON",
	    feats => ["Gender=Fem", "PronType=Dem"],
	},
	"PD0CS000" => {
	    tag => "PRON",
	    feats => ["Gender=Neut", "Number=Sing", "PronType=Dem"],
	},
	"PD0CP000" => {
	    tag => "PRON",
	    feats => ["Gender=Neut", "Number=Plur", "PronType=Dem"],
	},
	"PD0CN000" => {
	    tag => "PRON",
	    feats => ["Gender=Neut", "PronType=Dem"],
	},
	# Pronouns: indefinites
	"PI0MS000" => {
	    tag => "PRON",
	    feats => ["Gender=Masc", "Number=Sing", "PronType=Ind"],
	},
	"PI0MP000" => {
	    tag => "PRON",
	    feats => ["Gender=Masc", "Number=Plur", "PronType=Ind"],
	},
	"PI0MN000" => {
	    tag => "PRON",
	    feats => ["Gender=Masc", "PronType=Ind"],
	},
	"PI0FS000" => {
	    tag => "PRON",
	    feats => ["Gender=Fem", "Number=Sing", "PronType=Ind"],
	},
	"PI0FP000" => {
	    tag => "PRON",
	    feats => ["Gender=Fem", "Number=Plur", "PronType=Ind"],
	},
	"PI0FN000" => {
	    tag => "PRON",
	    feats => ["Gender=Fem", "PronType=Ind"],
	},
	"PI0CS000" => {
	    tag => "PRON",
	    feats => ["Gender=Neut", "Number=Sing", "PronType=Ind"],
	},
	"PI0CP000" => {
	    tag => "PRON",
	    feats => ["Gender=Neut", "Number=Plur", "PronType=Ind"],
	},
	"PI0CN000" => {
	    tag => "PRON",
	    feats => ["Gender=Neut", "PronType=Ind"],
	},
	# Pronouns: exclamatives
	"PE0CN000" => {
	    tag => "PRON",
	    feats => ["Gender=Neut", "PronType=Exc"],
	},
	"PE0CS000" => {
	    tag => "PRON",
	    feats => ["Gender=Neut", "Number=Sing", "PronType=Exc"],
	},
	"PE0CP000" => {
	    tag => "PRON",
	    feats => ["Gender=Neut", "Number=Plur", "PronType=Exc"],
	},
	# Pronouns: interrogatives
	"PT0CN000" => {
	    tag => "PRON",
	    feats => ["Gender=Neut", "PronType=Int"],
	},
	"PT0CS000" => {
	    tag => "PRON",
	    feats => ["Gender=Neut", "Number=Sing", "PronType=Int"],
	},
	"PT0CP000" => {
	    tag => "PRON",
	    feats => ["Gender=Neut", "Number=Plur", "PronType=Int"],
	},
	# Pronouns: relative
	"PR0CN000" => {
	    tag => "PRON",
	    feats => ["Gender=Neut", "PronType=Rel"],
	},
	"PR0CS000" => {
	    tag => "PRON",
	    feats => ["Gender=Neut", "Number=Sing", "PronType=Rel"],
	},
	"PR0CP000" => {
	    tag => "PRON",
	    feats => ["Gender=Neut", "Number=Plur", "PronType=Rel"],
	},
	# Pronouns: personal
	"PP0MS000" => {
	    tag => "PRON",
	    feats => ["Gender=Masc", "Number=Sing", "PronType=Prs"],
	},
	"PP0MP000" => {
	    tag => "PRON",
	    feats => ["Gender=Masc", "Number=Plur", "PronType=Prs"],
	},
	"PP0FS000" => {
	    tag => "PRON",
	    feats => ["Gender=Fem", "Number=Sing", "PronType=Prs"],
	},
	"PP0FP000" => {
	    tag => "PRON",
	    feats => ["Gender=Fem", "Number=Plur", "PronType=Prs"],
	},
	"PP0CS000" => {
	    tag => "PRON",
	    feats => ["Gender=Com", "Number=Sing", "PronType=Prs"],
	},
	"PP0CP000" => {
	    tag => "PRON",
	    feats => ["Gender=Com", "Number=Plur", "PronType=Prs"],
	},
	"PP0CN000" => {
	    tag => "PRON",
	    feats => ["Gender=Com", "PronType=Prs"],
	},
	"PP1MS000" => {
	    tag => "PRON",
	    feats => ["Gender=Masc", "Number=Sing", "Person=1", "PronType=Prs"],
	},
	"PP1MP000" => {
	    tag => "PRON",
	    feats => ["Gender=Masc", "Number=Plur", "Person=1", "PronType=Prs"],
	},
	"PP1FS000" => {
	    tag => "PRON",
	    feats => ["Gender=Fem", "Number=Sing", "Person=1", "PronType=Prs"],
	},
	"PP1FP000" => {
	    tag => "PRON",
	    feats => ["Gender=Fem", "Number=Plur", "Person=1", "PronType=Prs"],
	},
	"PP1CS000" => {
	    tag => "PRON",
	    feats => ["Gender=Com", "Number=Sing", "Person=1", "PronType=Prs"],
	},
	"PP1CP000" => {
	    tag => "PRON",
	    feats => ["Gender=Com", "Number=Plur", "Person=1", "PronType=Prs"],
	},
	"PP1CN000" => {
	    tag => "PRON",
	    feats => ["Gender=Com", "Person=1", "PronType=Prs"],
	},
	"PP2MS000" => {
	    tag => "PRON",
	    feats => ["Gender=Masc", "Number=Sing", "Person=2", "PronType=Prs"],
	},
	"PP2MP000" => {
	    tag => "PRON",
	    feats => ["Gender=Masc", "Number=Plur", "Person=2", "PronType=Prs"],
	},
	"PP2FS000" => {
	    tag => "PRON",
	    feats => ["Gender=Fem", "Number=Sing", "Person=2", "PronType=Prs"],
	},
	"PP2FP000" => {
	    tag => "PRON",
	    feats => ["Gender=Fem", "Number=Plur", "Person=2", "PronType=Prs"],
	},
	"PP2CS000" => {
	    tag => "PRON",
	    feats => ["Gender=Com", "Number=Sing", "Person=2", "PronType=Prs"],
	},
	"PP2CP000" => {
	    tag => "PRON",
	    feats => ["Gender=Com", "Number=Plur", "Person=2", "PronType=Prs"],
	},
	"PP2CN000" => {
	    tag => "PRON",
	    feats => ["Gender=Com", "Person=2", "PronType=Prs"],
	},
	"PP3MS000" => {
	    tag => "PRON",
	    feats => ["Gender=Masc", "Number=Sing", "Person=3", "PronType=Prs"],
	},
	"PP3MP000" => {
	    tag => "PRON",
	    feats => ["Gender=Masc", "Number=Plur", "Person=3", "PronType=Prs"],
	},
	"PP3FS000" => {
	    tag => "PRON",
	    feats => ["Gender=Fem", "Number=Sing", "Person=3", "PronType=Prs"],
	},
	"PP3FP000" => {
	    tag => "PRON",
	    feats => ["Gender=Fem", "Number=Plur", "Person=3", "PronType=Prs"],
	},
	"PP3CS000" => {
	    tag => "PRON",
	    feats => ["Gender=Com", "Number=Sing", "Person=3", "PronType=Prs"],
	},
	"PP3CP000" => {
	    tag => "PRON",
	    feats => ["Gender=Com", "Number=Plur", "Person=3", "PronType=Prs"],
	},
	"PP3CN000" => {
	    tag => "PRON",
	    feats => ["Gender=Com", "Person=3", "PronType=Prs"],
	},
	# Nominative
	"PP0MSN00" => {
	    tag => "PRON",
	    feats => ["Case=Nom", "Gender=Masc", "Number=Sing", "PronType=Prs"],
	},
	"PP0MPN00" => {
	    tag => "PRON",
	    feats => ["Case=Nom", "Gender=Masc", "Number=Plur", "PronType=Prs"],
	},
	"PP0FSN00" => {
	    tag => "PRON",
	    feats => ["Case=Nom", "Gender=Fem", "Number=Sing", "PronType=Prs"],
	},
	"PP0FPN00" => {
	    tag => "PRON",
	    feats => ["Case=Nom", "Gender=Fem", "Number=Plur", "PronType=Prs"],
	},
	"PP0CSN00" => {
	    tag => "PRON",
	    feats => ["Case=Nom", "Gender=Com", "Number=Sing", "PronType=Prs"],
	},
	"PP0CPN00" => {
	    tag => "PRON",
	    feats => ["Case=Nom", "Gender=Com", "Number=Plur", "PronType=Prs"],
	},
	"PP0CNN00" => {
	    tag => "PRON",
	    feats => ["Case=Nom", "Gender=Com", "PronType=Prs"],
	},
	"PP1MSN00" => {
	    tag => "PRON",
	    feats => ["Case=Nom", "Gender=Masc", "Number=Sing", "Person=1", "PronType=Prs"],
	},
	"PP1MPN00" => {
	    tag => "PRON",
	    feats => ["Case=Nom", "Gender=Masc", "Number=Plur", "Person=1", "PronType=Prs"],
	},
	"PP1FSN00" => {
	    tag => "PRON",
	    feats => ["Case=Nom", "Gender=Fem", "Number=Sing", "Person=1", "PronType=Prs"],
	},
	"PP1FPN00" => {
	    tag => "PRON",
	    feats => ["Case=Nom", "Gender=Fem", "Number=Plur", "Person=1", "PronType=Prs"],
	},
	"PP1CSN00" => {
	    tag => "PRON",
	    feats => ["Case=Nom", "Gender=Com", "Number=Sing", "Person=1", "PronType=Prs"],
	},
	"PP1CPN00" => {
	    tag => "PRON",
	    feats => ["Case=Nom", "Gender=Com", "Number=Plur", "Person=1", "PronType=Prs"],
	},
	"PP1CNN00" => {
	    tag => "PRON",
	    feats => ["Case=Nom", "Gender=Com", "Person=1", "PronType=Prs"],
	},
	"PP2MSN00" => {
	    tag => "PRON",
	    feats => ["Case=Nom", "Gender=Masc", "Number=Sing", "Person=2", "PronType=Prs"],
	},
	"PP2MPN00" => {
	    tag => "PRON",
	    feats => ["Case=Nom", "Gender=Masc", "Number=Plur", "Person=2", "PronType=Prs"],
	},
	"PP2FSN00" => {
	    tag => "PRON",
	    feats => ["Case=Nom", "Gender=Fem", "Number=Sing", "Person=2", "PronType=Prs"],
	},
	"PP2FPN00" => {
	    tag => "PRON",
	    feats => ["Case=Nom", "Gender=Fem", "Number=Plur", "Person=2", "PronType=Prs"],
	},
	"PP2CSN00" => {
	    tag => "PRON",
	    feats => ["Case=Nom", "Gender=Com", "Number=Sing", "Person=2", "PronType=Prs"],
	},
	"PP2CPN00" => {
	    tag => "PRON",
	    feats => ["Case=Nom", "Gender=Com", "Number=Plur", "Person=2", "PronType=Prs"],
	},
	"PP2CNN00" => {
	    tag => "PRON",
	    feats => ["Case=Nom", "Gender=Com", "Person=2", "PronType=Prs"],
	},
	"PP3MSN00" => {
	    tag => "PRON",
	    feats => ["Case=Nom", "Gender=Masc", "Number=Sing", "Person=3", "PronType=Prs"],
	},
	"PP3MPN00" => {
	    tag => "PRON",
	    feats => ["Case=Nom", "Gender=Masc", "Number=Plur", "Person=3", "PronType=Prs"],
	},
	"PP3FSN00" => {
	    tag => "PRON",
	    feats => ["Case=Nom", "Gender=Fem", "Number=Sing", "Person=3", "PronType=Prs"],
	},
	"PP3FPN00" => {
	    tag => "PRON",
	    feats => ["Case=Nom", "Gender=Fem", "Number=Plur", "Person=3", "PronType=Prs"],
	},
	"PP3CSN00" => {
	    tag => "PRON",
	    feats => ["Case=Nom", "Gender=Com", "Number=Sing", "Person=3", "PronType=Prs"],
	},
	"PP3CPN00" => {
	    tag => "PRON",
	    feats => ["Case=Nom", "Gender=Com", "Number=Plur", "Person=3", "PronType=Prs"],
	},
	"PP3CNN00" => {
	    tag => "PRON",
	    feats => ["Case=Nom", "Gender=Com", "Person=3", "PronType=Prs"],
	},
	# Accusative
	"PP0MSA00" => {
	    tag => "PRON",
	    feats => ["Case=Acc", "Gender=Masc", "Number=Sing", "PronType=Prs"],
	},
	"PP0MPA00" => {
	    tag => "PRON",
	    feats => ["Case=Acc", "Gender=Masc", "Number=Plur", "PronType=Prs"],
	},
	"PP0FSA00" => {
	    tag => "PRON",
	    feats => ["Case=Acc", "Gender=Fem", "Number=Sing", "PronType=Prs"],
	},
	"PP0FPA00" => {
	    tag => "PRON",
	    feats => ["Case=Acc", "Gender=Fem", "Number=Plur", "PronType=Prs"],
	},
	"PP0CSA00" => {
	    tag => "PRON",
	    feats => ["Case=Acc", "Gender=Com", "Number=Sing", "PronType=Prs"],
	},
	"PP0CPA00" => {
	    tag => "PRON",
	    feats => ["Case=Acc", "Gender=Com", "Number=Plur", "PronType=Prs"],
	},
	"PP0CNA00" => {
	    tag => "PRON",
	    feats => ["Case=Acc", "Gender=Com", "PronType=Prs"],
	},
	"PP1MSA00" => {
	    tag => "PRON",
	    feats => ["Case=Acc", "Gender=Masc", "Number=Sing", "Person=1", "PronType=Prs"],
	},
	"PP1MPA00" => {
	    tag => "PRON",
	    feats => ["Case=Acc", "Gender=Masc", "Number=Plur", "Person=1", "PronType=Prs"],
	},
	"PP1FSA00" => {
	    tag => "PRON",
	    feats => ["Case=Acc", "Gender=Fem", "Number=Sing", "Person=1", "PronType=Prs"],
	},
	"PP1FPA00" => {
	    tag => "PRON",
	    feats => ["Case=Acc", "Gender=Fem", "Number=Plur", "Person=1", "PronType=Prs"],
	},
	"PP1CSA00" => {
	    tag => "PRON",
	    feats => ["Case=Acc", "Gender=Com", "Number=Sing", "Person=1", "PronType=Prs"],
	},
	"PP1CPA00" => {
	    tag => "PRON",
	    feats => ["Case=Acc", "Gender=Com", "Number=Plur", "Person=1", "PronType=Prs"],
	},
	"PP1CNA00" => {
	    tag => "PRON",
	    feats => ["Case=Acc", "Gender=Com", "Person=1", "PronType=Prs"],
	},
	"PP2MSA00" => {
	    tag => "PRON",
	    feats => ["Case=Acc", "Gender=Masc", "Number=Sing", "Person=2", "PronType=Prs"],
	},
	"PP2MPA00" => {
	    tag => "PRON",
	    feats => ["Case=Acc", "Gender=Masc", "Number=Plur", "Person=2", "PronType=Prs"],
	},
	"PP2FSA00" => {
	    tag => "PRON",
	    feats => ["Case=Acc", "Gender=Fem", "Number=Sing", "Person=2", "PronType=Prs"],
	},
	"PP2FPA00" => {
	    tag => "PRON",
	    feats => ["Case=Acc", "Gender=Fem", "Number=Plur", "Person=2", "PronType=Prs"],
	},
	"PP2CSA00" => {
	    tag => "PRON",
	    feats => ["Case=Acc", "Gender=Com", "Number=Sing", "Person=2", "PronType=Prs"],
	},
	"PP2CPA00" => {
	    tag => "PRON",
	    feats => ["Case=Acc", "Gender=Com", "Number=Plur", "Person=2", "PronType=Prs"],
	},
	"PP2CNA00" => {
	    tag => "PRON",
	    feats => ["Case=Acc", "Gender=Com", "Person=2", "PronType=Prs"],
	},
	"PP3MSA00" => {
	    tag => "PRON",
	    feats => ["Case=Acc", "Gender=Masc", "Number=Sing", "Person=3", "PronType=Prs"],
	},
	"PP3MPA00" => {
	    tag => "PRON",
	    feats => ["Case=Acc", "Gender=Masc", "Number=Plur", "Person=3", "PronType=Prs"],
	},
	"PP3FSA00" => {
	    tag => "PRON",
	    feats => ["Case=Acc", "Gender=Fem", "Number=Sing", "Person=3", "PronType=Prs"],
	},
	"PP3FPA00" => {
	    tag => "PRON",
	    feats => ["Case=Acc", "Gender=Fem", "Number=Plur", "Person=3", "PronType=Prs"],
	},
	"PP3CSA00" => {
	    tag => "PRON",
	    feats => ["Case=Acc", "Gender=Com", "Number=Sing", "Person=3", "PronType=Prs"],
	},
	"PP3CPA00" => {
	    tag => "PRON",
	    feats => ["Case=Acc", "Gender=Com", "Number=Plur", "Person=3", "PronType=Prs"],
	},
	"PP3CNA00" => {
	    tag => "PRON",
	    feats => ["Case=Acc", "Gender=Com", "Person=3", "PronType=Prs"],
	},
	# Dative
	"PP0MSD00" => {
	    tag => "PRON",
	    feats => ["Case=Dat", "Gender=Masc", "Number=Sing", "PronType=Prs"],
	},
	"PP0MPD00" => {
	    tag => "PRON",
	    feats => ["Case=Dat", "Gender=Masc", "Number=Plur", "PronType=Prs"],
	},
	"PP0FSD00" => {
	    tag => "PRON",
	    feats => ["Case=Dat", "Gender=Fem", "Number=Sing", "PronType=Prs"],
	},
	"PP0FPD00" => {
	    tag => "PRON",
	    feats => ["Case=Dat", "Gender=Fem", "Number=Plur", "PronType=Prs"],
	},
	"PP0CSD00" => {
	    tag => "PRON",
	    feats => ["Case=Dat", "Gender=Com", "Number=Sing", "PronType=Prs"],
	},
	"PP0CPD00" => {
	    tag => "PRON",
	    feats => ["Case=Dat", "Gender=Com", "Number=Plur", "PronType=Prs"],
	},
	"PP0CND00" => {
	    tag => "PRON",
	    feats => ["Case=Dat", "Gender=Com", "PronType=Prs"],
	},
	"PP1MSD00" => {
	    tag => "PRON",
	    feats => ["Case=Dat", "Gender=Masc", "Number=Sing", "Person=1", "PronType=Prs"],
	},
	"PP1MPD00" => {
	    tag => "PRON",
	    feats => ["Case=Dat", "Gender=Masc", "Number=Plur", "Person=1", "PronType=Prs"],
	},
	"PP1FSD00" => {
	    tag => "PRON",
	    feats => ["Case=Dat", "Gender=Fem", "Number=Sing", "Person=1", "PronType=Prs"],
	},
	"PP1FPD00" => {
	    tag => "PRON",
	    feats => ["Case=Dat", "Gender=Fem", "Number=Plur", "Person=1", "PronType=Prs"],
	},
	"PP1CSD00" => {
	    tag => "PRON",
	    feats => ["Case=Dat", "Gender=Com", "Number=Sing", "Person=1", "PronType=Prs"],
	},
	"PP1CPD00" => {
	    tag => "PRON",
	    feats => ["Case=Dat", "Gender=Com", "Number=Plur", "Person=1", "PronType=Prs"],
	},
	"PP1CND00" => {
	    tag => "PRON",
	    feats => ["Case=Dat", "Gender=Com", "Person=1", "PronType=Prs"],
	},
	"PP2MSD00" => {
	    tag => "PRON",
	    feats => ["Case=Dat", "Gender=Masc", "Number=Sing", "Person=2", "PronType=Prs"],
	},
	"PP2MPD00" => {
	    tag => "PRON",
	    feats => ["Case=Dat", "Gender=Masc", "Number=Plur", "Person=2", "PronType=Prs"],
	},
	"PP2FSD00" => {
	    tag => "PRON",
	    feats => ["Case=Dat", "Gender=Fem", "Number=Sing", "Person=2", "PronType=Prs"],
	},
	"PP2FPD00" => {
	    tag => "PRON",
	    feats => ["Case=Dat", "Gender=Fem", "Number=Plur", "Person=2", "PronType=Prs"],
	},
	"PP2CSD00" => {
	    tag => "PRON",
	    feats => ["Case=Dat", "Gender=Com", "Number=Sing", "Person=2", "PronType=Prs"],
	},
	"PP2CPD00" => {
	    tag => "PRON",
	    feats => ["Case=Dat", "Gender=Com", "Number=Plur", "Person=2", "PronType=Prs"],
	},
	"PP2CND00" => {
	    tag => "PRON",
	    feats => ["Case=Dat", "Gender=Com", "Person=2", "PronType=Prs"],
	},
	"PP3MSD00" => {
	    tag => "PRON",
	    feats => ["Case=Dat", "Gender=Masc", "Number=Sing", "Person=3", "PronType=Prs"],
	},
	"PP3MPD00" => {
	    tag => "PRON",
	    feats => ["Case=Dat", "Gender=Masc", "Number=Plur", "Person=3", "PronType=Prs"],
	},
	"PP3FSD00" => {
	    tag => "PRON",
	    feats => ["Case=Dat", "Gender=Fem", "Number=Sing", "Person=3", "PronType=Prs"],
	},
	"PP3FPD00" => {
	    tag => "PRON",
	    feats => ["Case=Dat", "Gender=Fem", "Number=Plur", "Person=3", "PronType=Prs"],
	},
	"PP3CSD00" => {
	    tag => "PRON",
	    feats => ["Case=Dat", "Gender=Com", "Number=Sing", "Person=3", "PronType=Prs"],
	},
	"PP3CPD00" => {
	    tag => "PRON",
	    feats => ["Case=Dat", "Gender=Com", "Number=Plur", "Person=3", "PronType=Prs"],
	},
	"PP3CND00" => {
	    tag => "PRON",
	    feats => ["Case=Dat", "Gender=Com", "Person=3", "PronType=Prs"],
	},
	# Oblique Case=Cmp?
	"PP0MSO00" => {
	    tag => "PRON",
	    feats => ["Gender=Masc", "Number=Sing", "PronType=Prs"],
	},
	"PP0MPO00" => {
	    tag => "PRON",
	    feats => ["Gender=Masc", "Number=Plur", "PronType=Prs"],
	},
	"PP0FSO00" => {
	    tag => "PRON",
	    feats => ["Gender=Fem", "Number=Sing", "PronType=Prs"],
	},
	"PP0FPO00" => {
	    tag => "PRON",
	    feats => ["Gender=Fem", "Number=Plur", "PronType=Prs"],
	},
	"PP0CSO00" => {
	    tag => "PRON",
	    feats => ["Gender=Com", "Number=Sing", "PronType=Prs"],
	},
	"PP0CPO00" => {
	    tag => "PRON",
	    feats => ["Gender=Com", "Number=Plur", "PronType=Prs"],
	},
	"PP0CNO00" => {
	    tag => "PRON",
	    feats => ["Gender=Com", "PronType=Prs"],
	},
	"PP1MSO00" => {
	    tag => "PRON",
	    feats => ["Gender=Masc", "Number=Sing", "Person=1", "PronType=Prs"],
	},
	"PP1MPO00" => {
	    tag => "PRON",
	    feats => ["Gender=Masc", "Number=Plur", "Person=1", "PronType=Prs"],
	},
	"PP1FSO00" => {
	    tag => "PRON",
	    feats => ["Gender=Fem", "Number=Sing", "Person=1", "PronType=Prs"],
	},
	"PP1FPO00" => {
	    tag => "PRON",
	    feats => ["Gender=Fem", "Number=Plur", "Person=1", "PronType=Prs"],
	},
	"PP1CSO00" => {
	    tag => "PRON",
	    feats => ["Gender=Com", "Number=Sing", "Person=1", "PronType=Prs"],
	},
	"PP1CPO00" => {
	    tag => "PRON",
	    feats => ["Gender=Com", "Number=Plur", "Person=1", "PronType=Prs"],
	},
	"PP1CNO00" => {
	    tag => "PRON",
	    feats => ["Gender=Com", "Person=1", "PronType=Prs"],
	},
	"PP2MSO00" => {
	    tag => "PRON",
	    feats => ["Gender=Masc", "Number=Sing", "Person=2", "PronType=Prs"],
	},
	"PP2MPO00" => {
	    tag => "PRON",
	    feats => ["Gender=Masc", "Number=Plur", "Person=2", "PronType=Prs"],
	},
	"PP2FSO00" => {
	    tag => "PRON",
	    feats => ["Gender=Fem", "Number=Sing", "Person=2", "PronType=Prs"],
	},
	"PP2FPO00" => {
	    tag => "PRON",
	    feats => ["Gender=Fem", "Number=Plur", "Person=2", "PronType=Prs"],
	},
	"PP2CSO00" => {
	    tag => "PRON",
	    feats => ["Gender=Com", "Number=Sing", "Person=2", "PronType=Prs"],
	},
	"PP2CPO00" => {
	    tag => "PRON",
	    feats => ["Gender=Com", "Number=Plur", "Person=2", "PronType=Prs"],
	},
	"PP2CNO00" => {
	    tag => "PRON",
	    feats => ["Gender=Com", "Person=2", "PronType=Prs"],
	},
	"PP3MSO00" => {
	    tag => "PRON",
	    feats => ["Gender=Masc", "Number=Sing", "Person=3", "PronType=Prs"],
	},
	"PP3MPO00" => {
	    tag => "PRON",
	    feats => ["Gender=Masc", "Number=Plur", "Person=3", "PronType=Prs"],
	},
	"PP3FSO00" => {
	    tag => "PRON",
	    feats => ["Gender=Fem", "Number=Sing", "Person=3", "PronType=Prs"],
	},
	"PP3FPO00" => {
	    tag => "PRON",
	    feats => ["Gender=Fem", "Number=Plur", "Person=3", "PronType=Prs"],
	},
	"PP3CSO00" => {
	    tag => "PRON",
	    feats => ["Gender=Com", "Number=Sing", "Person=3", "PronType=Prs"],
	},
	"PP3CPO00" => {
	    tag => "PRON",
	    feats => ["Gender=Com", "Number=Plur", "Person=3", "PronType=Prs"],
	},
	"PP3CNO00" => {
	    tag => "PRON",
	    feats => ["Gender=Com", "Person=3", "PronType=Prs"],
	},
	# Possessive pronouns
	"PX1FP0P0" => {
	    tag => "PRON",
	    feats => ["Poss=Yes", "PronType=Prs", "Person=1", "Number[psor]=Plur", "Gender=Fem", "Number=Plur"],
	},
	"PX1FP0S0" => {
	    tag => "PRON",
	    feats => ["Poss=Yes", "PronType=Prs", "Person=1", "Number[psor]=Sing", "Gender=Fem", "Number=Plur"],
	},
	"PX1FS0P0" => {
	    tag => "PRON",
	    feats => ["Poss=Yes", "PronType=Prs", "Person=1", "Number[psor]=Plur", "Gender=Fem", "Number=Sing"],
	},
	"PX1FS0S0" => {
	    tag => "PRON",
	    feats => ["Poss=Yes", "PronType=Prs", "Person=1", "Number[psor]=Sing", "Gender=Fem", "Number=Sing"],
	},
	"PX1MP0P0" => {
	    tag => "PRON",
	    feats => ["Poss=Yes", "PronType=Prs", "Person=1", "Number[psor]=Plur", "Gender=Masc", "Number=Plur"],
	},
	"PX1MP0S0" => {
	    tag => "PRON",
	    feats => ["Poss=Yes", "PronType=Prs", "Person=1", "Number[psor]=Sing", "Gender=Masc", "Number=Plur"],
	},
	"PX1MS0P0" => {
	    tag => "PRON",
	    feats => ["Poss=Yes", "PronType=Prs", "Person=1", "Number[psor]=Plur", "Gender=Masc", "Number=Sing"],
	},
	"PX1MS0S0" => {
	    tag => "PRON",
	    feats => ["Poss=Yes", "PronType=Prs", "Person=1", "Number[psor]=Sing", "Gender=Masc", "Number=Sing"],
	},
	"PX2FP0P0" => {
	    tag => "PRON",
	    feats => ["Poss=Yes", "PronType=Prs", "Person=2", "Number[psor]=Plur", "Gender=Fem", "Number=Plur"],
	},
	"PX2FP0S0" => {
	    tag => "PRON",
	    feats => ["Poss=Yes", "PronType=Prs", "Person=2", "Number[psor]=Sing", "Gender=Fem", "Number=Plur"],
	},
	"PX2FS0P0" => {
	    tag => "PRON",
	    feats => ["Poss=Yes", "PronType=Prs", "Person=2", "Number[psor]=Plur", "Gender=Fem", "Number=Sing"],
	},
	"PX2FS0S0" => {
	    tag => "PRON",
	    feats => ["Poss=Yes", "PronType=Prs", "Person=2", "Number[psor]=Sing", "Gender=Fem", "Number=Sing"],
	},
	"PX2MP0P0" => {
	    tag => "PRON",
	    feats => ["Poss=Yes", "PronType=Prs", "Person=2", "Number[psor]=Plur", "Gender=Masc", "Number=Plur"],
	},
	"PX2MP0S0" => {
	    tag => "PRON",
	    feats => ["Poss=Yes", "PronType=Prs", "Person=2", "Number[psor]=Sing", "Gender=Masc", "Number=Plur"],
	},
	"PX2MS0P0" => {
	    tag => "PRON",
	    feats => ["Poss=Yes", "PronType=Prs", "Person=2", "Number[psor]=Plur", "Gender=Masc", "Number=Sing"],
	},
	"PX2MS0S0" => {
	    tag => "PRON",
	    feats => ["Poss=Yes", "PronType=Prs", "Person=2", "Number[psor]=Sing", "Gender=Masc", "Number=Sing"],
	},
	"PX3FP0P0" => {
	    tag => "PRON",
	    feats => ["Poss=Yes", "PronType=Prs", "Person=3", "Number[psor]=Plur", "Gender=Fem", "Number=Plur"],
	},
	"PX3FP0S0" => {
	    tag => "PRON",
	    feats => ["Poss=Yes", "PronType=Prs", "Person=3", "Number[psor]=Sing", "Gender=Fem", "Number=Plur"],
	},
	"PX3FS0P0" => {
	    tag => "PRON",
	    feats => ["Poss=Yes", "PronType=Prs", "Person=3", "Number[psor]=Plur", "Gender=Fem", "Number=Sing"],
	},
	"PX3FS0S0" => {
	    tag => "PRON",
	    feats => ["Poss=Yes", "PronType=Prs", "Person=3", "Number[psor]=Sing", "Gender=Fem", "Number=Sing"],
	},
	"PX3MP0P0" => {
	    tag => "PRON",
	    feats => ["Poss=Yes", "PronType=Prs", "Person=3", "Number[psor]=Plur", "Gender=Masc", "Number=Plur"],
	},
	"PX3MP0S0" => {
	    tag => "PRON",
	    feats => ["Poss=Yes", "PronType=Prs", "Person=3", "Number[psor]=Sing", "Gender=Masc", "Number=Plur"],
	},
	"PX3MS0P0" => {
	    tag => "PRON",
	    feats => ["Poss=Yes", "PronType=Prs", "Person=3", "Number[psor]=Plur", "Gender=Masc", "Number=Sing"],
	},
	"PX3MS0S0" => {
	    tag => "PRON",
	    feats => ["Poss=Yes", "PronType=Prs", "Person=3", "Number[psor]=Sing", "Gender=Masc", "Number=Sing"],
	},
	# Verbs
	"VMN0000" => {
	    tag => "VERB",
	    feats => ["VerbForm=Inf"],
	},
	"VMG0000" => {
	    tag => "VERB",
	    feats => ["VerbForm=Ger"], },
	"VMG02P0" => {
	    tag => "VERB",
	    feats => ["VerbForm=Ger", "Person=2", "Number=Plur"],
	},
	"VMIC1P0" => {
	    tag => "VERB",
	    feats => ["Mood=Cnd,Ind", "Person=1", "Number=Plur"],
	},
	"VMIC1S0" => {
	    tag => "VERB",
	    feats => ["Mood=Cnd,Ind", "Person=1", "Number=Sing"],
	},
	"VMIC2P0" => {
	    tag => "VERB",
	    feats => ["Mood=Cnd,Ind", "Person=2", "Number=Plur"],
	},
	"VMIC2S0" => {
	    tag => "VERB",
	    feats => ["Mood=Cnd,Ind", "Person=2", "Number=Sing"],
	},
	"VMIC3P0" => {
	    tag => "VERB",
	    feats => ["Mood=Cnd,Ind", "Person=3", "Number=Plur"],
	},
	"VMIC3S0" => {
	    tag => "VERB",
	    feats => ["Mood=Cnd,Ind", "Person=3", "Number=Sing"],
	},
	"VMIF1P0" => {
	    tag => "VERB",
	    feats => ["Mood=Ind", "Tense=Fut", "Person=1", "Number=Plur"],
	},
	"VMIF1S0" => {
	    tag => "VERB",
	    feats => ["Mood=Ind", "Tense=Fut", "Person=1", "Number=Sing"],
	},
	"VMIF2P0" => {
	    tag => "VERB",
	    feats => ["Mood=Ind", "Tense=Fut", "Person=2", "Number=Plur"],
	},
	"VMIF2S0" => {
	    tag => "VERB",
	    feats => ["Mood=Ind", "Tense=Fut", "Person=2", "Number=Sing"],
	},
	"VMIF3P0" => {
	    tag => "VERB",
	    feats => ["Mood=Ind", "Tense=Fut", "Person=3", "Number=Plur"],
	},
	"VMIF3S0" => {
	    tag => "VERB",
	    feats => ["Mood=Ind", "Tense=Fut", "Person=3", "Number=Sing"],
	},
	"VMII1P0" => {
	    tag => "VERB",
	    feats => ["Mood=Ind", "Tense=Imp", "Person=1", "Number=Plur"],
	},
	"VMII1S0" => {
	    tag => "VERB",
	    feats => ["Mood=Ind", "Tense=Imp", "Person=1", "Number=Sing"],
	},
	"VMII2P0" => {
	    tag => "VERB",
	    feats => ["Mood=Ind", "Tense=Imp", "Person=2", "Number=Plur"],
	},
	"VMII2S0" => {
	    tag => "VERB",
	    feats => ["Mood=Ind", "Tense=Imp", "Person=2", "Number=Sing"],
	},
	"VMII3P0" => {
	    tag => "VERB",
	    feats => ["Mood=Ind", "Tense=Imp", "Person=3", "Number=Plur"],
	},
	"VMII3S0" => {
	    tag => "VERB",
	    feats => ["Mood=Ind", "Tense=Imp", "Person=3", "Number=Sing"],
	},
	"VMIM1P0" => {
	    tag => "VERB",
	    feats => ["Mood=Ind", "Tense=Pqp", "Person=1", "Number=Plur"],
	},
	"VMIM1S0" => {
	    tag => "VERB",
	    feats => ["Mood=Ind", "Tense=Pqp", "Person=1", "Number=Sing"],
	},
	"VMIM2P0" => {
	    tag => "VERB",
	    feats => ["Mood=Ind", "Tense=Pqp", "Person=2", "Number=Plur"],
	},
	"VMIM2S0" => {
	    tag => "VERB",
	    feats => ["Mood=Ind", "Tense=Pqp", "Person=2", "Number=Sing"],
	},
	"VMIM3P0" => {
	    tag => "VERB",
	    feats => ["Mood=Ind", "Tense=Pqp", "Person=3", "Number=Plur"],
	},
	"VMIM3S0" => {
	    tag => "VERB",
	    feats => ["Mood=Ind", "Tense=Pqp", "Person=3", "Number=Sing"],
	},
	"VMIP1P0" => {
	    tag => "VERB",
	    feats => ["Mood=Ind", "Tense=Pres", "Person=1", "Number=Plur"],
	},
	"VMIP1S0" => {
	    tag => "VERB",
	    feats => ["Mood=Ind", "Tense=Pres", "Person=1", "Number=Sing"],
	},
	"VMIP2P0" => {
	    tag => "VERB",
	    feats => ["Mood=Ind", "Tense=Pres", "Person=2", "Number=Plur"],
	},
	"VMIP2S0" => {
	    tag => "VERB",
	    feats => ["Mood=Ind", "Tense=Pres", "Person=2", "Number=Sing"],
	},
	"VMIP3P0" => {
	    tag => "VERB",
	    feats => ["Mood=Ind", "Tense=Pres", "Person=3", "Number=Plur"],
	},
	"VMIP3S0" => {
	    tag => "VERB",
	    feats => ["Mood=Ind", "Tense=Pres", "Person=3", "Number=Sing"],
	},
	"VMIS1P0" => {
	    tag => "VERB",
	    feats => ["Mood=Ind", "Tense=Past", "Person=1", "Number=Plur"],
	},
	"VMIS1S0" => {
	    tag => "VERB",
	    feats => ["Mood=Ind", "Tense=Past", "Person=1", "Number=Sing"],
	},
	"VMIS2P0" => {
	    tag => "VERB",
	    feats => ["Mood=Ind", "Tense=Past", "Person=2", "Number=Plur"],
	},
	"VMIS2S0" => {
	    tag => "VERB",
	    feats => ["Mood=Ind", "Tense=Past", "Person=2", "Number=Sing"],
	},
	"VMIS3P0" => {
	    tag => "VERB",
	    feats => ["Mood=Ind", "Tense=Past", "Person=3", "Number=Plur"],
	},
	"VMIS3S0" => {
	    tag => "VERB",
	    feats => ["Mood=Ind", "Tense=Past", "Person=3", "Number=Sing"],
	},
	"VMM01P0" => {
	    tag => "VERB",
	    feats => ["Mood=Imp", "Person=1", "Number=Plur"],
	},
	"VMM02P0" => {
	    tag => "VERB",
	    feats => ["Mood=Imp", "Person=2", "Number=Plur"],
	},
	"VMM02S0" => {
	    tag => "VERB",
	    feats => ["Mood=Imp", "Person=2", "Number=Sing"],
	},
	"VMM03P0" => {
	    tag => "VERB",
	    feats => ["Mood=Imp", "Person=3", "Number=Plur"],
	},
	"VMM03S0" => {
	    tag => "VERB",
	    feats => ["Mood=Imp", "Person=3", "Number=Sing"],
	},
	"VMM05P0" => {
	    tag => "VERB",
	    feats => ["Mood=Imp", "Person=2", "Number=Plur"],
	},
	"VMM06P0" => {
	    tag => "VERB",
	    feats => ["Mood=Imp", "Person=3", "Number=Plur"],
	},
	"VMN01P0" => {
	    tag => "VERB",
	    feats => ["VerbForm=Inf", "Person=1", "Number=Plur"],
	},
	"VMN01S0" => {
	    tag => "VERB",
	    feats => ["VerbForm=Inf", "Person=1", "Number=Sing"],
	},
	"VMN02P0" => {
	    tag => "VERB",
	    feats => ["VerbForm=Inf", "Person=2", "Number=Plur"],
	},
	"VMN02S0" => {
	    tag => "VERB",
	    feats => ["VerbForm=Inf", "Person=2", "Number=Sing"],
	},
	"VMN03P0" => {
	    tag => "VERB",
	    feats => ["VerbForm=Inf", "Person=3", "Number=Plur"],
	},
	"VMN03S0" => {
	    tag => "VERB",
	    feats => ["VerbForm=Inf", "Person=3", "Number=Sing"],
	},
	"VMP0000" => {
	    tag => "VERB",
	    feats => ["VerbForm=Part"],
	},
	"VMP00PF" => {
	    tag => "VERB",
	    feats => ["VerbForm=Part", "Number=Plur", "Gender=Fem"],
	},
	"VMP00PM" => {
	    tag => "VERB",
	    feats => ["VerbForm=Part", "Number=Plur", "Gender=Masc"],
	},
	"VMP00P0" => {
	    tag => "VERB",
	    feats => ["VerbForm=Part", "Number=Plur"],
	},
	"VMP00S0" => {
	    tag => "VERB",
	    feats => ["VerbForm=Part", "Number=Sing"],
	},
	"VMP00SF" => {
	    tag => "VERB",
	    feats => ["VerbForm=Part", "Number=Sing", "Gender=Fem"],
	},
	"VMP00SM" => {
	    tag => "VERB",
	    feats => ["VerbForm=Part", "Number=Sing", "Gender=Masc"],
	},
	"VMSF1P0" => {
	    tag => "VERB",
	    feats => ["Mood=Sub", "Tense=Fut", "Person=1", "Number=Plur"],
	},
	"VMSF1S0" => {
	    tag => "VERB",
	    feats => ["Mood=Sub", "Tense=Fut", "Person=1", "Number=Sing"],
	},
	"VMSF2P0" => {
	    tag => "VERB",
	    feats => ["Mood=Sub", "Tense=Fut", "Person=2", "Number=Plur"],
	},
	"VMSF2S0" => {
	    tag => "VERB",
	    feats => ["Mood=Sub", "Tense=Fut", "Person=2", "Number=Sing"],
	},
	"VMSF3P0" => {
	    tag => "VERB",
	    feats => ["Mood=Sub", "Tense=Fut", "Person=3", "Number=Plur"],
	},
	"VMSF3S0" => {
	    tag => "VERB",
	    feats => ["Mood=Sub", "Tense=Fut", "Person=3", "Number=Sing"],
	},
	"VMSI1P0" => {
	    tag => "VERB",
	    feats => ["Mood=Sub", "Tense=Imp", "Person=1", "Number=Plur"],
	},
	"VMSI1S0" => {
	    tag => "VERB",
	    feats => ["Mood=Sub", "Tense=Imp", "Person=1", "Number=Sing"],
	},
	"VMSI2P0" => {
	    tag => "VERB",
	    feats => ["Mood=Sub", "Tense=Imp", "Person=2", "Number=Plur"],
	},
	"VMSI2S0" => {
	    tag => "VERB",
	    feats => ["Mood=Sub", "Tense=Imp", "Person=2", "Number=Sing"],
	},
	"VMSI3P0" => {
	    tag => "VERB",
	    feats => ["Mood=Sub", "Tense=Imp", "Person=3", "Number=Plur"],
	},
	"VMSI3S0" => {
	    tag => "VERB",
	    feats => ["Mood=Sub", "Tense=Imp", "Person=3", "Number=Sing"],
	},
	"VMSP1P0" => {
	    tag => "VERB",
	    feats => ["Mood=Sub", "Tense=Pres", "Person=1", "Number=Plur"],
	},
	"VMSP1S0" => {
	    tag => "VERB",
	    feats => ["Mood=Sub", "Tense=Pres", "Person=1", "Number=Sing"],
	},
	"VMSP2P0" => {
	    tag => "VERB",
	    feats => ["Mood=Sub", "Tense=Pres", "Person=2", "Number=Plur"],
	},
	"VMSP2S0" => {
	    tag => "VERB",
	    feats => ["Mood=Sub", "Tense=Pres", "Person=2", "Number=Sing"],
	},
	"VMSP3P0" => {
	    tag => "VERB",
	    feats => ["Mood=Sub", "Tense=Pres", "Person=3", "Number=Plur"],
	},
	"VMSP3S0" => {
	    tag => "VERB",
	    feats => ["Mood=Sub", "Tense=Pres", "Person=3", "Number=Sing"],
	},
	# Auxiliar verbs
	"VSG0000" => {
	    tag => "AUX",
	    feats => ["VerbForm=Ger"],
	},
	"VSG02P0" => {
	    tag => "AUX",
	    feats => ["VerbForm=Ger", "Person=2", "Number=Plur"],
	},
	"VSIC1P0" => {
	    tag => "AUX",
	    feats => ["Mood=Cnd,Ind", "Person=1", "Number=Plur"],
	},
	"VSIC1S0" => {
	    tag => "AUX",
	    feats => ["Mood=Cnd,Ind", "Person=1", "Number=Sing"],
	},
	"VSIC2P0" => {
	    tag => "AUX",
	    feats => ["Mood=Cnd,Ind", "Person=2", "Number=Plur"],
	},
	"VSIC2S0" => {
	    tag => "AUX",
	    feats => ["Mood=Cnd,Ind", "Person=2", "Number=Sing"],
	},
	"VSIC3P0" => {
	    tag => "AUX",
	    feats => ["Mood=Cnd,Ind", "Person=3", "Number=Plur"],
	},
	"VSIC3S0" => {
	    tag => "AUX",
	    feats => ["Mood=Cnd,Ind", "Person=3", "Number=Sing"],
	},
	"VSIF1P0" => {
	    tag => "AUX",
	    feats => ["Mood=Ind", "Tense=Fut", "Person=1", "Number=Plur"],
	},
	"VSIF1S0" => {
	    tag => "AUX",
	    feats => ["Mood=Ind", "Tense=Fut", "Person=1", "Number=Sing"],
	},
	"VSIF2P0" => {
	    tag => "AUX",
	    feats => ["Mood=Ind", "Tense=Fut", "Person=2", "Number=Plur"],
	},
	"VSIF2S0" => {
	    tag => "AUX",
	    feats => ["Mood=Ind", "Tense=Fut", "Person=2", "Number=Sing"],
	},
	"VSIF3P0" => {
	    tag => "AUX",
	    feats => ["Mood=Ind", "Tense=Fut", "Person=3", "Number=Plur"],
	},
	"VSIF3S0" => {
	    tag => "AUX",
	    feats => ["Mood=Ind", "Tense=Fut", "Person=3", "Number=Sing"],
	},
	"VSII1P0" => {
	    tag => "AUX",
	    feats => ["Mood=Ind", "Tense=Imp", "Person=1", "Number=Plur"],
	},
	"VSII1S0" => {
	    tag => "AUX",
	    feats => ["Mood=Ind", "Tense=Imp", "Person=1", "Number=Sing"],
	},
	"VSII2P0" => {
	    tag => "AUX",
	    feats => ["Mood=Ind", "Tense=Imp", "Person=2", "Number=Plur"],
	},
	"VSII2S0" => {
	    tag => "AUX",
	    feats => ["Mood=Ind", "Tense=Imp", "Person=2", "Number=Sing"],
	},
	"VSII3P0" => {
	    tag => "AUX",
	    feats => ["Mood=Ind", "Tense=Imp", "Person=3", "Number=Plur"],
	},
	"VSII3S0" => {
	    tag => "AUX",
	    feats => ["Mood=Ind", "Tense=Imp", "Person=3", "Number=Sing"],
	},
	"VSIM1P0" => {
	    tag => "AUX",
	    feats => ["Mood=Ind", "Tense=Pqp", "Person=1", "Number=Plur"],
	},
	"VSIM1S0" => {
	    tag => "AUX",
	    feats => ["Mood=Ind", "Tense=Pqp", "Person=1", "Number=Sing"],
	},
	"VSIM2P0" => {
	    tag => "AUX",
	    feats => ["Mood=Ind", "Tense=Pqp", "Person=2", "Number=Plur"],
	},
	"VSIM2S0" => {
	    tag => "AUX",
	    feats => ["Mood=Ind", "Tense=Pqp", "Person=2", "Number=Sing"],
	},
	"VSIM3P0" => {
	    tag => "AUX",
	    feats => ["Mood=Ind", "Tense=Pqp", "Person=3", "Number=Plur"],
	},
	"VSIM3S0" => {
	    tag => "AUX",
	    feats => ["Mood=Ind", "Tense=Pqp", "Person=3", "Number=Sing"],
	},
	"VSIP1P0" => {
	    tag => "AUX",
	    feats => ["Mood=Ind", "Tense=Pres", "Person=1", "Number=Plur"],
	},
	"VSIP1S0" => {
	    tag => "AUX",
	    feats => ["Mood=Ind", "Tense=Pres", "Person=1", "Number=Sing"],
	},
	"VSIP2P0" => {
	    tag => "AUX",
	    feats => ["Mood=Ind", "Tense=Pres", "Person=2", "Number=Plur"],
	},
	"VSIP2S0" => {
	    tag => "AUX",
	    feats => ["Mood=Ind", "Tense=Pres", "Person=2", "Number=Sing"],
	},
	"VSIP3P0" => {
	    tag => "AUX",
	    feats => ["Mood=Ind", "Tense=Pres", "Person=3", "Number=Plur"],
	},
	"VSIP3S0" => {
	    tag => "AUX",
	    feats => ["Mood=Ind", "Tense=Pres", "Person=3", "Number=Sing"],
	},
	"VSIS1P0" => {
	    tag => "AUX",
	    feats => ["Mood=Ind", "Tense=Past", "Person=1", "Number=Plur"],
	},
	"VSIS1S0" => {
	    tag => "AUX",
	    feats => ["Mood=Ind", "Tense=Past", "Person=1", "Number=Sing"],
	},
	"VSIS2P0" => {
	    tag => "AUX",
	    feats => ["Mood=Ind", "Tense=Past", "Person=2", "Number=Plur"],
	},
	"VSIS2S0" => {
	    tag => "AUX",
	    feats => ["Mood=Ind", "Tense=Past", "Person=2", "Number=Sing"],
	},
	"VSIS3P0" => {
	    tag => "AUX",
	    feats => ["Mood=Ind", "Tense=Past", "Person=3", "Number=Plur"],
	},
	"VSIS3S0" => {
	    tag => "AUX",
	    feats => ["Mood=Ind", "Tense=Past", "Person=3", "Number=Sing"],
	},
	"VSM01P0" => {
	    tag => "AUX",
	    feats => ["Mood=Imp", "Person=1", "Number=Plur"],
	},
	"VSM02P0" => {
	    tag => "AUX",
	    feats => ["Mood=Imp", "Person=2", "Number=Plur"],
	},
	"VSM02S0" => {
	    tag => "AUX",
	    feats => ["Mood=Imp", "Person=2", "Number=Sing"],
	},
	"VSM03P0" => {
	    tag => "AUX",
	    feats => ["Mood=Imp", "Person=3", "Number=Plur"],
	},
	"VSM03S0" => {
	    tag => "AUX",
	    feats => ["Mood=Imp", "Person=3", "Number=Sing"],
	},
	"VSN0000" => {
	    tag => "AUX",
	    feats => ["VerbForm=Inf"],
	},
	"VSN01P0" => {
	    tag => "AUX",
	    feats => ["VerbForm=Inf", "Person=1", "Number=Plur"],
	},
	"VSN01S0" => {
	    tag => "AUX",
	    feats => ["VerbForm=Inf", "Person=1", "Number=Sing"],
	},
	"VSN02P0" => {
	    tag => "AUX",
	    feats => ["VerbForm=Inf", "Person=2", "Number=Plur"],
	},
	"VSN02S0" => {
	    tag => "AUX",
	    feats => ["VerbForm=Inf", "Person=2", "Number=Sing"],
	},
	"VSN03P0" => {
	    tag => "AUX",
	    feats => ["VerbForm=Inf", "Person=3", "Number=Plur"],
	},
	"VSN03S0" => {
	    tag => "AUX",
	    feats => ["VerbForm=Inf", "Person=3", "Number=Sing"],
	},
	"VSP00PF" => {
	    tag => "AUX",
	    feats => ["VerbForm=Part", "Gender=Fem", "Number=Plur"],
	},
	"VSP00PM" => {
	    tag => "AUX",
	    feats => ["VerbForm=Part", "Gender=Masc", "Number=Plur"],
	},
	"VSP00SF" => {
	    tag => "AUX",
	    feats => ["VerbForm=Part", "Gender=Fem", "Number=Sing"],
	},
	"VSP00SM" => {
	    tag => "AUX",
	    feats => ["VerbForm=Part", "Gender=Masc", "Number=Sing"],
	},
	"VSSF1P0" => {
	    tag => "AUX",
	    feats => ["Mood=Sub", "Tense=Fut", "Person=1", "Number=Plur"],
	},
	"VSSF1S0" => {
	    tag => "AUX",
	    feats => ["Mood=Sub", "Tense=Fut", "Person=1", "Number=Sing"],
	},
	"VSSF2P0" => {
	    tag => "AUX",
	    feats => ["Mood=Sub", "Tense=Fut", "Person=2", "Number=Plur"],
	},
	"VSSF2S0" => {
	    tag => "AUX",
	    feats => ["Mood=Sub", "Tense=Fut", "Person=2", "Number=Sing"],
	},
	"VSSF3P0" => {
	    tag => "AUX",
	    feats => ["Mood=Sub", "Tense=Fut", "Person=3", "Number=Plur"],
	},
	"VSSF3S0" => {
	    tag => "AUX",
	    feats => ["Mood=Sub", "Tense=Fut", "Person=3", "Number=Sing"],
	},
	"VSSI1P0" => {
	    tag => "AUX",
	    feats => ["Mood=Sub", "Tense=Imp", "Person=1", "Number=Plur"],
	},
	"VSSI1S0" => {
	    tag => "AUX",
	    feats => ["Mood=Sub", "Tense=Imp", "Person=1", "Number=Sing"],
	},
	"VSSI2P0" => {
	    tag => "AUX",
	    feats => ["Mood=Sub", "Tense=Imp", "Person=2", "Number=Plur"],
	},
	"VSSI2S0" => {
	    tag => "AUX",
	    feats => ["Mood=Sub", "Tense=Imp", "Person=2", "Number=Sing"],
	},
	"VSSI3P0" => {
	    tag => "AUX",
	    feats => ["Mood=Sub", "Tense=Imp", "Person=3", "Number=Plur"],
	},
	"VSSI3S0" => {
	    tag => "AUX",
	    feats => ["Mood=Sub", "Tense=Imp", "Person=3", "Number=Sing"],
	},
	"VSSP1P0" => {
	    tag => "AUX",
	    feats => ["Mood=Sub", "Tense=Pres", "Person=1", "Number=Plur"],
	},
	"VSSP1S0" => {
	    tag => "AUX",
	    feats => ["Mood=Sub", "Tense=Pres", "Person=1", "Number=Sing"],
	},
	"VSSP2P0" => {
	    tag => "AUX",
	    feats => ["Mood=Sub", "Tense=Pres", "Person=2", "Number=Plur"],
	},
	"VSSP2S0" => {
	    tag => "AUX",
	    feats => ["Mood=Sub", "Tense=Pres", "Person=2", "Number=Sing"],
	},
	"VSSP3P0" => {
	    tag => "AUX",
	    feats => ["Mood=Sub", "Tense=Pres", "Person=3", "Number=Plur"],
	},
	"VSSP3S0" => {
	    tag => "AUX",
	    feats => ["Mood=Sub", "Tense=Pres", "Person=3", "Number=Sing"],
	},
    };
}

if ($opt_e) {
    our $info = {
	# Conjuctions
	"CC" => {
	    tag => "CCONJ",
	    feats => [],
	},
	"CS" => {
	    tag => "SCONJ",
	    feats => [],
	},
	# Adjectives
    	"JJ" => {
    	    tag => "ADJ",
    	    feats => [],
    	},
    	"JJR" => {
    	    tag => "ADJ",
    	    feats => ["Degree=Cmp"],
    	},
    	"JJS" => {
    	    tag => "ADJ",
    	    feats => ["Degree=Sup"],
    	},
	# Adposition ???
    	"POS" => {
    	    tag => "AUX",
    	    feats => ["Poss=Yes"],
    	},
	# Adverb
    	"RG" => {
    	    tag => "ADV",
    	    feats => [""],
    	},
    	"RB" => {
    	    tag => "ADV",
    	    feats => [""],
    	},
    	"RBR" => {
    	    tag => "ADV",
    	    feats => ["Degree=Cmp"],
    	},
    	"RBS" => {
    	    tag => "ADV",
    	    feats => ["Degree=Sup"],
    	},
    	"WRB" => {
    	    tag => "PRON",
    	    feats => ["PronType=Int"],
    	},
	# Determiners
	"DT" => {
	    tag => "DET",
	    feats => ["PronType=Art"],
	},
	"DR" => {
	    tag => "DET",
	    feats => ["PronType=Art"],
	},
	"WDT" => {
	    tag => "DET",
	    feats => ["PronType=Int"],
	},
	"PDT" => {
	    tag => "DET",
	    feats => [],
	},
	# Nouns
	"NN" => {
	    tag => "NOUN",
	    feats => ["Number=Plur"],
	},
	"NNS" => {
	    tag => "NOUN",
	    feats => ["Number=Sing"],
	},
	"NNP" => {
	    tag => "PROPN",
	    feats => [],
	},
	"NP" => {
	    tag => "PROPN",
	    feats => [],
	},
	"NNPS" => {
	    tag => "PROPN",
	    feats => ["Number=Plur"],
	},
	# Particles
	"RP" => {
	    tag => "SCONJ",
	    feats => [],
	},
	"TO" => {
	    tag => "PART",
	    feats => [],
	},
	# Preposition
	"IN" => {
	    tag => "ADP",
	    feats => [],
	},
	# Pronoun
	"EX" => {
	    tag => "PRON",
	    feats => [],
	},
	"WP" => {
	    tag => "PRON",
	    feats => ["PronType=Int"],
	},
	"PRP" => {
	    tag => "PRON",
	    feats => ["PronType=Prs"],
	},
	"PRP\$" => {
	    tag => "PRON",
	    feats => ["Poss=Yes", "PronType=Prs"],
	},
	"WP\$" => {
	    tag => "PRON",
	    feats => ["Poss=Yes", "PronType=Int"],
	},
	# Verb
	"MD" => {
	    tag => "VERB",
	    feats => [],
	},
	"VBG" => {
	    tag => "VERB",
	    feats => ["VerbForm=Ger"],
	},
	"VB" => {
	    tag => "VERB",
	    feats => ["VerbForm=Inf"],
	},
	"VBN" => {
	    tag => "VERB",
	    feats => ["Tense=Past", "VerbForm=Part"],
	},
	"VBD" => {
	    tag => "VERB",
	    feats => ["Mood=Ind", "Tense=Past", "VerbForm=Fin"],
	},
	"VBP" => {
	    tag => "VERB",
	    feats => ["Mood=Ind", "Tense=Pres", "VerbForm=Fin"],
	},
	"VBZ" => {
	    tag => "VERB",
	    feats => ["Mood=Ind", "Number=Sing", "Person=3", "Tense=Pres", "VerbForm=Fin"],
	},
	"VBZb" => {
	    tag => "VERB",
	    feats => ["Mood=Ind", "Number=Sing", "Person=3", "Tense=Pres", "VerbForm=Fin"],
	},
	"VBZh" => {
	    tag => "VERB",
	    feats => ["Mood=Ind", "Number=Sing", "Person=3", "Tense=Pres", "VerbForm=Fin"],
	},
    },
}
############

my $sent = 1;
my $pos = 0;
my %corpus = ();
my %text = ();
while (my $line = <STDIN>) {
    chomp $line;

    if ($line ne "" && $line !~ /<blank>/ && $line !~ / Fp$/) {
	$pos++;
	my ($token, $lema, $etag, $val) = split(" ", $line);

	# TEST
	if ($token =~ /^_./) {
	    $t = $token;
	    $t =~ s/^_//g;
	    $token = $t;
	}
	if ($token =~ /._$/) {
	    $t = $token;
	    $t =~ s/_$//g;
	    $token = $t;
	}

	# Text (no split)
	if ($opt_j) {
	    $text{$pos} = $token;
	} elsif ($opt_n && $token !~ /_[^_]/) {
	    $text{$pos} = $token;
	}

	# Previous replacements
	if ($etag =~ /^VA/) {
	    $etag =~ s/^VA/VS/;
	}
	elsif ($etag =~ /^AQ....0/) {
	    $etag =~ s/0$//;
	}
	elsif ($etag =~ /^P......$/) {
	    $etag =~ s/$/0/;
	}

	# Split
	if ($opt_n) {
	    if ($token =~ /[^_]_[^_]/ && $etag !~ /^Z/) {
		my @toks = split("_", $token);
		for (my $i=0;$i<=$#toks;$i++) {
		    my $l = "\L$toks[$i]";

		    # Split contractions: experimental
		    my @ctc = splitc($toks[$i]);
		    if (@ctc) {
			for (my $c=0;$c<=$#ctc;$c++) {
			    my($tk, $lm, $tg) = split("_", $ctc[$c]);
			    $corpus{$pos} = "$pos\t$tk\t$lm\t$tg\t$etag\t_\t_\t_\t_\t_";
			    if ($c<$#ctc) {
				$pos++;
			    }
			}
		    }
		    # Main elements (not contracted) [keep NP/PROPN tag]
		    else {
			my $UDtag = default($etag,$toks[$i]);
			$corpus{$pos} = "$pos\t$toks[$i]\t$l\t$UDtag\t$etag\t_\t_\t_\t_\t_";
		    }
		    $text{$pos} = $toks[$i];
		    if ($i<$#toks) {
			$pos++;
		    }
		}
	    }
	    # Experimental: quantities, etc. (not splitted so far)
	    elsif ($token =~ /_[^_]/ && $etag =~ /^Z/) {
		$corpus{$pos} = "$pos\t$token\t$lema\tNUM\t$etag\t_\t_\t_\t_\t_";
	    }
	}
	# Prints mwe (not splitted)
	else {
	    # Experimental
	    if ($etag =~ /^Z/) {
		$corpus{$pos} = "$pos\t$token\t$lema\tNUM\t$etag\t_\t_\t_\t_\t_";
	    } else {
		my $UDtag = default($etag);
		if ($UDtag) {
		    $corpus{$pos} = "$pos\t$token\t$lema\t$UDtag\t$etag\t_\t_\t_\t_\t_";
		} else {
		    $corpus{$pos} = "$pos\t$token\t$lema\tX\t$etag\t_\t_\t_\t_\t_";
		}
	    }
	}
	# Prints default conversions
	my $UDtag = default($etag);
	if ($UDtag && $token !~ /_[^_]/) {
	    $corpus{$pos} = "$pos\t$token\t$lema\t$UDtag\t$etag\t_\t_\t_\t_\t_";
	}

	##############
	# Large List #
	##############
	elsif (defined $$info{$etag}) {

	    # Prevent printing again splitted lines
	    unless ($opt_n && $token =~ /_[^_]/) {
		# POS-tag
		my $UDtag = $$info{$etag}{tag};

		# Feats
		my @feats = ();
#		foreach my $f(values $$info{$etag}{feats}) {
		foreach my $f(@{$$info{$etag}{feats}}) {
		    push(@feats, $f);
		}
		my @sort_feats = sort {$a cmp $b} @feats;

		# Copulative verbs # be?
		if ($lema =~ /^(ser|estar|parecer)$/) {
		    $corpus{$pos} = "$pos\t$token\t$lema\tAUX\t$etag";
		} else {
		    $corpus{$pos} = "$pos\t$token\t$lema\t$UDtag\t$etag";
		}

		if (!@sort_feats) {
		    $corpus{$pos} .= "\t_\t_\t_\t_\t_";
		}
		elsif ($#sort_feats <= 0) {
		    $corpus{$pos} .= "\t$sort_feats[0]\t_\t_\t_\t_";
		} else {
		    $corpus{$pos} .= "\t";
		    for (my $i = 0; $i<=$#feats; $i++) {
			if ($i == $#sort_feats) {
			    $corpus{$pos} .= "$sort_feats[$i]";
			} else {
			    $corpus{$pos} .= "$sort_feats[$i]|";
			}
		    }
		    $corpus{$pos} .= "\t_\t_\t_\t_";
		}
	    }
	} elsif ($token !~ /[^_]_[^_]/) {
	    # Default
	    if ($etag =~ /^AP/) {
		$corpus{$pos} = "$pos\t$token\t$lema\tPRON\t$etag\tPoss=Yes\t_\t_\t_\t_";
	    } elsif ($etag =~ /^AO/) {
		$corpus{$pos} = "$pos\t$token\t$lema\tNUM\t$etag\tNumType=Ord\t_\t_\t_\t_";
	    } elsif ($etag =~ /^AQ/) {
		$corpus{$pos} = "$pos\t$token\t$lema\tADJ\t$etag\t_\t_\t_\t_\t_";
	    } elsif ($etag =~ /^NP/) {
		$corpus{$pos} = "$pos\t$token\t$lema\tPROPN\t$etag\t_\t_\t_\t_\t_";
	    } elsif ($etag =~ /^N/) {
		$corpus{$pos} = "$pos\t$token\t$lema\tNOUN\t$etag\tToDo\t_\t_\t_\t_";
	    } elsif ($etag =~ /^PP/) {
		$corpus{$pos} = "$pos\t$token\t$lema\tPRON\t$etag\tPronType=Prs\t_\t_\t_\t_";
	    } elsif ($etag =~ /^PD/) {
		$corpus{$pos} = "$pos\t$token\t$lema\tPRON\t$etag\tPronType=Dem\t_\t_\t_\t_";
	    } elsif ($etag =~ /^PX/) {
		$corpus{$pos} = "$pos\t$token\t$lema\tPRON\t$etag\tPoss=Yes|PronType=Prs\t_\t_\t_\t_";
	    } elsif ($etag =~ /^PR/) {
		$corpus{$pos} = "$pos\t$token\t$lema\tPRON\t$etag\tPronType=Rel\t_\t_\t_\t_";
	    } elsif ($etag =~ /^PI/) {
		$corpus{$pos} = "$pos\t$token\t$lema\tPRON\t$etag\tPronType=Ind\t_\t_\t_\t_";
	    } elsif ($etag =~ /^PE/) {
		$corpus{$pos} = "$pos\t$token\t$lema\tPRON\t$etag\tPronType=Exc\t_\t_\t_\t_";
	    } elsif ($etag =~ /^PT/) {
		$corpus{$pos} = "$pos\t$token\t$lema\tPRON\t$etag\tPronType=Int\t_\t_\t_\t_";
	    } elsif ($etag =~ /^P/) {
		$corpus{$pos} = "$pos\t$token\t$lema\tPRON\t$etag\t_\t_\t_\t_\t_";
	    } elsif ($etag =~ /^D/) {
		$corpus{$pos} = "$pos\t$token\t$lema\tDET\t$etag\tToDo\t_\t_\t_\t_";
	    } elsif ($etag =~ /^Z/) {
		$corpus{$pos} = "$pos\t$token\t$lema\tNUM\t$etag\tToDo\t_\t_\t_\t_";
	    } elsif ($etag =~ /^VS/) {
		$corpus{$pos} = "$pos\t$token\t$lema\tAUX\t$etag\tToDo\t_\t_\t_\t_";
	    } elsif ($etag =~ /^VA/) {
		$corpus{$pos} = "$pos\t$token\t$lema\tAUX\t$etag\tToDo\t_\t_\t_\t_";
	    } elsif ($etag =~ /^V/) {
		$corpus{$pos} = "$pos\t$token\t$lema\tVERB\t$etag\tToDo\t_\t_\t_\t_";
	    } elsif ($etag =~ /^C/) {
		$corpus{$pos} = "$pos\t$token\t$lema\tSCONJ\t$etag\tToDo\t_\t_\t_\t_";
	    } else {
		#$corpus{$pos} = "$pos\t$token\t$lema\tToDo\t$etag\t_\t_\t_\t_\t_";
		$corpus{$pos} = "$pos\t$token\t$lema\tX\t$etag\t_\t_\t_\t_\t_";
	    }
	}
    } else {

	# LinguaKit sentence boundary
	if ($opt_l && $line =~ /. . Fp$/) {
	    $pos++;
	    $corpus{$pos} = "$pos\t.\t.\tPUNCT\tFp\t_\t_\t_\t_\t_";
	    $text{$pos} = ".";
	}

	# Final Print
	#############
	if (keys(%corpus) > 0) {
	    print "# sent_id = $sent\n";
	    print "# text =";
	    foreach my $t(sort {$a <=> $b} keys %text) {
		print " $text{$t}";
	    }
	    print "\n";
	    foreach my $c(sort {$a <=> $b} keys %corpus) {
		# Cambio para evitar tokens sem tag -> X (HARTA)
		my @feats = split('\t', $corpus{$c});
		my $UDTag = $feats[3];
		if ($UDTag eq "") {
		    my $correct = $corpus{$c};
		    $correct =~ s/\t\t/\tX\t/;
		    $corpus{$c} = $correct;
		} else {
		    print "$corpus{$c}\n";
		}
	    }
	    print "\n";
	}
	$pos = 0;
	$sent++;
	%corpus = ();
	%text = ();
    }
}


##############
# Conversion #
##############
sub default {

    my $tag = $_[0];
    my $tok = $_[1];
    my $UDtag = ();

    # Punctuation
    if ($tag =~ /F[zt]/) {
	$UDtag = "SYM";
    } elsif ($tag =~ /^F/) {
	$UDtag = "PUNCT";
    }
    # Default
    elsif ($tag =~ /NP/) {
	$UDtag = "PROPN";
    } elsif ($tag eq "W") {
	if ($tok && $tok =~ /^(de|of|en|em)$/) {
	    $UDtag = "ADP";
	} elsif ($tok && $tok =~ /[A-Za-z]/ && $tok !~ /[0-9]/) {
	    $UDtag = "NOUN";
	} else {
	    $UDtag = "NUM";
	}
    } elsif ($tag =~ /^(I|UH)$/) {
	$UDtag = "INTJ";
    }
    if ($tag =~ /^N?NP/ && $tok) {
	if ($tok =~ /^(de|en|em|of)$/) {
	    $UDtag = "ADP";
	}
    }
    return $UDtag;
}

#############################
# Split contractions in mwe #
#############################
sub splitc {

    my $input = shift;
    my @out;

    # Galician/Portuguese
    if ($opt_g || $opt_p) {

	if ($input eq "do") {
	    push(@out, "de_de_ADP");
	    push(@out, "o_o_DET");
	} elsif ($input eq "da") {
	    push(@out, "de_de_ADP");
	    push(@out, "a_o_DET");
	} elsif ($input eq "dos") {
	    push(@out, "de_de_ADP");
	    push(@out, "os_o_DET");
	} elsif ($input eq "das") {
	    push(@out, "de_de_ADP");
	    push(@out, "as_o_DET");
	} elsif ($input eq "no") {
	    if ($opt_g) {
		push(@out, "en_en_ADP");
		push(@out, "o_o_DET");
	    } else {
		push(@out, "em_em_ADP");
		push(@out, "o_o_DET");
	    }
	} elsif ($input eq "na") {
	    if ($opt_g) {
		push(@out, "en_en_ADP");
		push(@out, "a_o_DET");
	    } else {
		push(@out, "em_em_ADP");
		push(@out, "a_o_DET");
	    }
	} elsif ($input eq "nos") {
	    if ($opt_g) {
		push(@out, "en_en_ADP");
		push(@out, "os_o_DET");
	    } else {
		push(@out, "em_em_ADP");
		push(@out, "os_o_DET");
	    }
	} elsif ($input eq "nas") {
	    if ($opt_g) {
		push(@out, "en_en_ADP");
		push(@out, "as_o_DET");
	    } else {
		push(@out, "em_em_ADP");
		push(@out, "as_o_DET");
	    }
	} elsif ($input eq "pelo") {
	    push(@out, "por_por_ADP");
	    push(@out, "o_o_DET");
	} elsif ($input eq "pela") {
	    push(@out, "por_por_ADP");
	    push(@out, "a_o_DET");
	} elsif ($input eq "pelos") {
	    push(@out, "por_por_ADP");
	    push(@out, "os_o_DET");
	} elsif ($input eq "pelas") {
	    push(@out, "por_por_ADP");
	    push(@out, "as_o_DET");
	} elsif ($input eq "polo") {
	    push(@out, "por_por_ADP");
	    push(@out, "o_o_DET");
	} elsif ($input eq "pola") {
	    push(@out, "por_por_ADP");
	    push(@out, "a_o_DET");
	} elsif ($input eq "polos") {
	    push(@out, "por_por_ADP");
	    push(@out, "os_o_DET");
	} elsif ($input eq "polas") {
	    push(@out, "por_por_ADP");
	    push(@out, "as_o_DET");
	} elsif ($input eq "co") {
	    push(@out, "con_con_ADP");
	    push(@out, "o_o_DET");
	} elsif ($input eq "cos") {
	    push(@out, "con_con_ADP");
	    push(@out, "os_o_DET");
	} elsif ($input eq "coa") {
	    push(@out, "con_con_ADP");
	    push(@out, "a_o_DET");
	} elsif ($input eq "coas") {
	    push(@out, "con_con_ADP");
	    push(@out, "as_o_DET");
	}
    }
    # Spanish
    elsif ($opt_s) {
	if($input eq "del") {
	    push(@out, "de_de_ADP");
	    push(@out, "el_el_DET");
	}
    }
    return @out;
}
