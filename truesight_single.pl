#!/usr/bin/perl -w

# 
#####
#
#	yangli9@illinois.edu
#
#####

use Getopt::Long ;
use Getopt::Long qw(:config no_ignore_case);
use POSIX;
use FindBin qw($Bin);
use Parallel::ForkManager;
use Cwd 'abs_path';

#########################################
$VERSION = 0.06;
#########################################

GetOptions(
	#MANDATORY
	'f=s' => \$Fq,
	'r|bowtie-index=s'=>\$bwt,
	#                        #OPTIONAL       
	'p|thread=i'=>\$P,
	's|segment-length=i'=>\$segment_length,
	'v|mismatch=i'=>\$V,
	'm=i'=>\$M,
	'T|clean_temp=i'=>\$clean,
	'h|help' =>\$help,
	'i|min-intron-length=i'=>\$intron_min,
	'I|max-intron-length=i'=>\$intron_max,                                                                                                
	'c|canonical'=>\$canonical_flag,
	'o|output=s'=>\$OUT_DIR,
	'segment-name'=>\$report_read_name,
#'d|mate-inner-dist=i'=>\$mate_dist,
	'C=i'=>\$cov);

if($help  || ! defined $Fq || ! defined $bwt || ! -e $Fq || ! -e "$bwt.fa"){
	if(defined $Fq && ! -e $Fq){
		print "$Fq does not exist\n";
	}
	if(defined $bwt && ! -e "$bwt.fa"){
		print "$bwt.fa does not exist\n";
	}
	print "TrueSight single-end v$VERSION\nUsage:\n
	-p/--thread             number of cores
	-f                      [MANDATORY] input file name; if there are multiple files, they should be seperated by comma; All reads should have the same length and >= 36bp
	-r/--bowtie-index       [MANDATORY] bowtie reference dir/name, thus bowtie index should be dir/name.*.ebwt, reference genome should also be located here, e.g. dir/name.fa; chromosome line for dir/name.fa should be clean and there is no space within it, such as \">XXXXX\\n\"
	-v/--mismatch           mismatches (0-3)
	-s/--segment-length     segment length (18-25)
	-o/--output             output dir, default is truesight_out
	-i/--min-intron-length
	-I/--max-intron-length
	-h/--help       
	--segment-name
	\n\n";

	exit(0);
}
$now_string = localtime;
print "$now_string:   ";
print "TrueSight single end v$VERSION\n";
$P = $P || 1;
$NOW = time;
$report_read_name = $report_read_name || 0;
$canonical_flag = $canonical_flag || 0;

$intron_min = $intron_min || 20;
$intron_max = $intron_max || 200000;
$OUT_DIR = $OUT_DIR || "truesight_out";
if(-d $OUT_DIR){
}
else{
	mkdir $OUT_DIR or die "failed to mkdir $OUT_DIR\n";
}
$segment_length = $segment_length||25 ; ## length of segments 18-25
$clean = $clean || 0;
$cov = $cov || 0;
$V = $V || 2;
$M = $M || 5;
if($segment_length > 25){
	$segment_length = 25;
}
if($segment_length < 18){
	$segment_length = 18;
}

$name = "temp";

@Fq_list = split(/,/,$Fq);

open($in,"<$Fq_list[0]");
for $i (0 .. $#Fq_list){
	push @abs_Fq_list, abs_path($Fq_list[$i]);
}
$abs_Fq = join(",", @abs_Fq_list);




$C=<$in>;
$C=<$in>;
chomp($C);
$read_length = length($C);
close($in);
$now_string = localtime;
print "$now_string:   ";

if($read_length < 36){
	print "Read length $read_length is less than 36bp can not be handled\n";
	exit(0);
}
if($read_length < 50){
	print "Read length is $read_length and segment length is forced to be ",int($read_length/2),"\n";
	$segment_length = int($read_length/2);
}
else{
	print "Read length is $read_length and segment length is $segment_length\n";
}
$bwt = abs_path($bwt);
chdir $OUT_DIR;
open(RUNLOG,">RUNLOG");

mySystem("$Bin/checkChr.pl $bwt.fa","Checking reference file");

mySystem("$Bin/readID_single.pl $abs_Fq > truesight_name_link","Preparing reads");

mySystem("$Bin/bowtie --quiet --sam --sam-nohead -k 20 -v $V -p $P --un $name.un.fq $bwt truesight_single_temp.fastq $name 2>>run.log", "Full alignment");
system("rm truesight_single_temp.fastq");



open($out,">$name.sam");
open($in,"<$name");
while(<$in>){
	@m=split(/\t/);
	if($m[2] eq "*"){
		next;
	}
	print $out $_;
}
close($out);
mySystem("rm $name",0);

$pm=new Parallel::ForkManager($P);
for ($i=1;$i<=2;$i++){
	my $pid = $pm->start and next;
	if($i == 1){
		mySystem("sort -t '	' -k 3,3 -k 4,4n $name.sam > $name.sam.sort; rm $name.sam");
		mySystem("sort -k 1,1n $name.sam.sort > $name.sam.sort_by_name");
	}
	else{
		mySystem("$Bin/centralPlan.pl $segment_length $P $bwt 1", "Distribute unmapped reads");
	}
	$pm->finish;
}
$pm->wait_all_children;


open(my $in,"<temp_data/list");
my @list = <$in>;
chomp(@list);
my $total_job = scalar @list;
$sparse = 0;
if(substr($list[0],0,-2) eq "temp_data/temp.un"){
	$sparse = 1;
}



for (my $i=0; $i<scalar @list; $i++){
	my $id = $i+1;
	open($in,"<N");
	$N_frag = <$in>;
	chomp($N_frag);
	if($sparse == 1){
		mySystem("$Bin/GappedAlignment4sparse $N_frag $segment_length $list[$i].bwt 5 8 $V $canonical_flag $bwt.fa $list[$i].fq $P $intron_max $intron_min $read_length > $id.log","Gapped alignment on $id of $total_job subsets");
	}
	else{
		mySystem("$Bin/GappedAlignment $N_frag $segment_length $list[$i].bwt 5 8 $V $canonical_flag $bwt.fa $list[$i].fq $P $intron_max $intron_min $read_length > $id.log","Gapped alignment on $id of $total_job subsets");
	}
	mySystem("mv solid solid.$id; mv multi multi.$id; mv new_full.sam new_full.sam.$id; mv non_solid non_solid.$id; rm new_full.sam.$id", 0);
	$solid .= "solid.$id ";
	$multi .= "multi.$id ";
	$non_solid .= "non_solid.$id ";
	if($clean == 0){
		mySystem("rm $list[$i]*", 0);
	}
	#$non_multi .= "non_multi.$id ";
}


mySystem("cat $solid | sort -k 1,1n | $Bin/solid_filter_mem.pl > solid; rm solid.*");# use / as separater
mySystem("cat $multi > multi_temp; rm multi.*");
#mySystem("cat $non_multi > non_multi");

mySystem("cat $non_solid | sort -k 1,1n | $Bin/filter_non_from_solid.pl solid | $Bin/solid_filter_mem.pl  > non_solid; rm non_solid.*");
mySystem("$Bin/filter_multi_from_solid.pl solid multi_temp > multi");

##Markov scoring
mySystem("$Bin/clean_multi.pl multi > multi_; mv multi_ multi");

mySystem("$Bin/mmSplicer multi $bwt.fa solid $N_frag $name.sam.sort $read_length $segment_length > mmlog", "EM logistic regression");

$pm=new Parallel::ForkManager($P);
for ($i=1;$i<=3;$i++){
	my $pid = $pm->start and next;
	if($i == 1){
		mySystem("$Bin/updateReadScore.pl final_junctions solid > solid_score");
	}
	if($i == 2){
		mySystem("$Bin/updateReadScore.pl final_junctions multi.solid > multi.solid_score");
	}
	if($i == 3){
		mySystem("$Bin/updateReadScore.pl final_junctions_noncano solid > non_cano_score");
	}
	$pm->finish;

}
$pm->wait_all_children;
mySystem("cat solid_score multi.solid_score non_cano_score > Gapped.sam");
mySystem("cat final_junctions final_junctions_noncano > junctions_score");

mySystem("$Bin/presentJunc.pl junctions_score Gapped.sam > SJS");
$now_string = localtime;
print "$now_string:   ";
print "Remap on annotated junctions\n";

mySystem("$Bin/getCanoFlag.pl SJS $bwt.fa > SJS_canoflag");
mySystem("$Bin/rmSickNoncanoJunc.pl SJS_canoflag > SJS_canoflag_clean");


open(I,"<SJS_canoflag_clean");
my $LINE_COUNTS = 0;
while(<I>){
	$LINE_COUNTS++;
}

if($LINE_COUNTS > 400000){
	$sparse = 1;
}
if($sparse == 1 || $cov == 1){
	mySystem("$Bin/reMapFromJunction SJS_canoflag_clean $bwt.fa $read_length > REMAP.fa");
}
else{
	mySystem("$Bin/reMapFromJunction_new SJS_canoflag_clean $bwt.fa $read_length > REMAP.fa");
	open(I,"<REMAP.fa");
	my $REMAP_SIZE = 0;
	$REMAP_FLAG = 0;
	while(<I>){
		chomp;
		if(substr($_,0,1) eq ">"){
			next;
		}
		$REMAP_SIZE += length($_);
		if($REMAP_SIZE > 4194967295){
			$REMAP_FLAG = 1;
			last;
		}
	}
	if($REMAP_FLAG == 1){
		mySystem("$Bin/reMapFromJunction SJS_canoflag_clean $bwt.fa $read_length > REMAP.fa");
	}
}







mySystem("$Bin/bowtie-build --quiet REMAP.fa REMAP; $Bin/bowtie --quiet -k 20 -v $V -p $P REMAP temp.un.fq REMAP.bwt");
mySystem("rm REMAP.fa; rm REMAP.*.ebwt",0);

mySystem("$Bin/translateRemapBWT.pl $read_length REMAP.bwt > REMAP.sam");

mySystem("rm REMAP.bwt",0);

mySystem("cat Gapped.sam REMAP.sam | sort -k 1,1n | $Bin/mergeRemapSAM_memfix.pl SJS_canoflag 2 $bwt.fa > final.sam; rm Gapped.sam");
mySystem("rm REMAP.sam",0);
mySystem("$Bin/presentJunc_single.pl SJS_canoflag  junctions_score final.sam $bwt.fa");


$pm=new Parallel::ForkManager($P);
for ($i=1;$i<=2;$i++){
	my $pid = $pm->start and next;
	if($i == 1){
		mySystem("$Bin/ID2name_single.pl truesight_name_link temp.sam.sort_by_name > temp.sam.sort_; mv temp.sam.sort_ temp.sam.sort");
	}
	if($i == 2){
		mySystem("$Bin/ID2name_single.pl truesight_name_link GapAli.sam > GapAli.sam_; mv GapAli.sam_ GapAli.sam");
	}
	$pm->finish;
}
$pm->wait_all_children;



`cat head GapAli.sam temp.sam.sort | samtools view -Sb - | samtools sort - alignment`;

#`rm head temp.sam.sort`;

if($clean == 0){
	`rm -r temp_data`;
	mySystem("rm multi* head solid* non* temp* SJS* train* N chr_num new* final* *.log k mmlog initial_train_sets.csv junctions_score truesight*",0);
}
$NOW = time -$NOW;
printf("\n\nTotal running time: %02d:%02d:%02d\n\n", int($NOW / 3600), int(($NOW % 3600) / 60),int($NOW % 60));

sub mySystem{
	my $systemCommand = $_[0];
	if(defined $_[1]){
		if($_[1] =~ /^0$/){
			system( $systemCommand );
			return;
		}
		$now_string = localtime;
		print "$now_string:   ";
		print $_[1],"\n";
		print RUNLOG "$now_string:   ";
		print RUNLOG $_[1],"\n";
	}

	my $returnCode = system( $systemCommand );
	if ( $returnCode != 0 ) {
		print RUNLOG "Failed executing [$systemCommand]\n";
		die "Failed executing [$systemCommand]\n";
	}
}
