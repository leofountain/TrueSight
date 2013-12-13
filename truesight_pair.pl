#!/usr/bin/perl -w
######
#
#	Li, Yang
#
#	yangli9@illinois.edu
#
#
######
use Getopt::Long ;
use Getopt::Long qw(:config no_ignore_case);
use POSIX;
use FindBin qw($Bin);
use Parallel::ForkManager;
use Cwd 'abs_path';

GetOptions(
	#MANDATORY
	'f=s{1,}' => \@Fq, 
	'r|bowtie-index=s'=>\$bwt,
	#OPTIONAL	
	'p|thread=i'=>\$P,
	's|segment-length=i'=>\$segment_length, 
	'v|mismatch=i'=>\$V, 
	'm=i'=>\$M, 
	'T|clean_temp=i'=>\$clean,
	'h|help' =>\$help,
	'i|min-intron-length=i'=>\$intron_min,
	'I|max-intron-length=i'=>\$intron_max,	
	'o|output=s'=>\$OUT_DIR,
	'c|canonical'=>\$canonical_flag,
	'segment-name'=>\$report_read_name, ## template name or original read name
	'C=i'=>\$cov);

#################################
$VERSION = 0.06;
#################################

if(scalar @Fq == 0 || $help || $bwt eq ""){
	if(defined $bwt && ! -e "$bwt.fa"){
		print "$bwt.fa does not exist\n";
	}
	print "TrueSight paired-end v$VERSION\nUsage:\n
	-p/--thread		number of cores
	-f      		[MANDATORY] input file name, fq_1 fq_2; if there are multiple files for fq_1/fq_2, they should be seperated by comma; All reads should have the same length and >= 36bp
	-r/--bowtie-index	[MANDATORY] bowtie reference dir/name, thus bowtie index should be dir/name.*.ebwt, reference genome should also be located here, e.g. dir/name.fa; chromosome line for dir/name.fa should be clean and there is no space within it, such as \">XXXXX\\n\"
	-v/--mismatch		mismatches (0-3)
	-s/--segment-length     segment length (18-25)
	-i/--min-intron-length
	-I/--max-intron-length
	-c/--canonical		if canonical
	-o/--output		output dir, default is truesight_out
	-h/--help	
	--segment-name
	\n\n";

	exit(0);
}
$NOW = time;

$now_string = localtime;
$bwt = abs_path($bwt);


print "$now_string:   ";
print "TrueSight paired-end v$VERSION\n";

$now_string = localtime;
print "$now_string:   ";
print "Checking configurations\n";

$intron_min = $intron_min || 20;
$intron_max = $intron_max || 200000;

$segment_length = $segment_length||25 ; ## length of segments 18-25
$clean = $clean || 0;
$cov = $cov || 0;
$V = $V || 2;
$M = $M || 5;
$report_read_name = $report_read_name || 0;
$canonical_flag = $canonical_flag || 0;

$OUT_DIR = $OUT_DIR || "truesight_out";
if(-d $OUT_DIR){
}
else{
	mkdir $OUT_DIR or die "failed to mkdir $OUT_DIR\n";
}
#chdir $OUT_DIR;

if($segment_length > 25){
	$segment_length = 25;
}
if($segment_length < 18){
	$segment_length = 18;
}


$P = $P || 1;

if(! -s "$bwt.fa"){
	print "Reference genome $bwt.fa not found!\n";
	exit(0);
}

if(! -s "$bwt.1.ebwt"){
	print "Bowtie index not found!\n";
	exit(0);
}
if($clean == 1){
	print "\t\tTemp files will not be deleted\n";
	if($report_read_name == 1){
		print "\t\tWill print original read names instead of template names\n";
	}
}


$name1 = "temp1";
$name2 = "temp2";
$name = "temp";

#open(RUNLOG,">>RUNLOG");
@Fq_list_1 = split(/,/,$Fq[0]);
@Fq_list_2 = split(/,/,$Fq[1]);

@abs_Fq_list_1 = ();
@abs_Fq_list_2 = ();

for $i (0 .. $#Fq_list_1){
	push @abs_Fq_list_1, abs_path($Fq_list_1[$i]);
}
for $i (0 .. $#Fq_list_2){
	push @abs_Fq_list_2, abs_path($Fq_list_2[$i]);
}
$abs_Fq_1 = join(",", @abs_Fq_list_1);
$abs_Fq_2 = join(",", @abs_Fq_list_2);

open($in,"<$Fq_list_1[0]");
$C=<$in>;
$C=<$in>;
chomp($C);
$read_length = length($C);



$now_string = localtime;
print "$now_string:   ";
if($read_length < 36){
	print "Read length $read_length is less than 36bp can not be handled\n";
	exit(0);
}
if($read_length < 50){
	print "Read length is $read_length and segment length is forced to be",int($read_length/2),"\n";
	$segment_length = int($read_length/2);
}
else{
	print "Read length is $read_length and segment length is $segment_length\n";
}

close($in);

$Fq[1] = abs_path($Fq[1]);
chdir $OUT_DIR;
open(RUNLOG,">>RUNLOG");
mySystem("$Bin/checkChr.pl $bwt.fa","Checking reference file");


$pm=new Parallel::ForkManager($P);
for ($i=1;$i<=2;$i++){
	my $pid = $pm->start and next;
	if($i == 1){
		mySystem("$Bin/readID_pair.pl $abs_Fq_1 1 > truesight_name_link","Preparing reads");
	}
	else{
		mySystem("$Bin/readID_pair.pl $abs_Fq_2 2");
	}
	$pm->finish;
}
$pm->wait_all_children;

mySystem("$Bin/bowtie --quiet --sam --sam-nohead -k 30 -v 2 -p $P --un $name1.un.fq $bwt truesight_pair_temp.1.fastq $name1 2>>run.log","Full alignment on left reads");
system("rm truesight_pair_temp.1.fastq");


mySystem("$Bin/bowtie --quiet --sam --sam-nohead -k 30 -v 2 -p $P --un $name2.un.fq $bwt truesight_pair_temp.2.fastq $name2 2>>run.log","Full alignment on right reads");
system("rm truesight_pair_temp.2.fastq");

$pm=new Parallel::ForkManager($P);
for ($i=1;$i<=2;$i++){
	my $pid = $pm->start and next;
	if($i == 1){
		mySystem("awk {'FS = \"\\t\" ; if(\$2 != 4) print \$0}' $name1 $name2 | sort -t '	' -k 3,3 -k 4,4n > $name.sam.sort; rm $name1 $name2");# sort fully aligned reads based on position
		mySystem("sort -t '/' -k 1,1n $name.sam.sort > $name.sam.sort_by_name");
	}
	else{
		mySystem("$Bin/centralPlan.pl $segment_length $P $bwt 2","Distribute unmapped reads");
	}
	$pm->finish;
}
$pm->wait_all_children;


mySystem("$Bin/getUnPairFullAli.pl temp.un.fq $name.sam.sort_by_name | $Bin/finalLink.pl $read_length  > EX_FULL");


open(my $in,"<temp_data/list");
my @list = <$in>;
chomp(@list);
my $total_job = scalar @list;
$sparse = 0;
if(substr($list[0],0,-2) eq "temp_data/temp.un"){
	$sparse = 1;
}

$C=0;
for (my $i=0; $i<scalar @list; $i++){
	$C++;
	my $id = $i+1;
	open($in,"<N");
	$N_frag = <$in>;
	chomp($N_frag);
	if($sparse == 1){
		mySystem("$Bin/GappedAlignment4sparse $N_frag $segment_length $list[$i].bwt $M 8 $V $canonical_flag $bwt.fa $list[$i].fq $P $intron_max $intron_min $read_length > $id.log","Gapped alignment on $id of $total_job subsets");
	}
	else{
		mySystem("$Bin/GappedAlignment $N_frag $segment_length $list[$i].bwt $M 8 $V $canonical_flag $bwt.fa $list[$i].fq $P $intron_max $intron_min $read_length > $id.log","Gapped alignment on $id of $total_job subsets");
	}
	system("mv solid solid.$id; mv multi multi.$id; mv new_full.sam new_full.sam.$id; mv non_solid non_solid.$id; rm new_full.sam.$id");#rm non_multi
	$solid .= "solid.$id ";
	$multi .= "multi.$id ";
	$non_solid .= "non_solid.$id ";
	#$non_multi .= "non_multi.$id ";
}


mySystem("cat $solid | sort -t '/' -k 1,1n | $Bin/solid_filter_mem.pl > solid_temp; rm solid.*");# use / as separater
mySystem("cat $multi > multi_temp");
#mySystem("cat $non_multi > non_multi");


mySystem("cat solid_temp temp_file.sam | sort -t '/' -k 1,1n | $Bin/rmUnPairGapAli_new.pl > solid");


mySystem("cat $non_solid | sort -t '/' -k 1,1n | $Bin/filter_non_from_solid.pl solid | $Bin/solid_filter_mem.pl > non_solid; $Bin/rm_non_Duplicate.pl non_solid > non_solid_");

mySystem("cat non_solid_ temp_file.sam | sort -t '/' -k 1,1n | $Bin/rmUnPairGapAli_new.pl > non_solid");

mySystem("$Bin/filter_multi_from_solid.pl solid multi_temp > multi");

mySystem("$Bin/clean_multi.pl multi > multi_; mv multi_ multi");


##Markov scoring

mySystem("$Bin/mmSplicer multi $bwt.fa solid $N_frag $name.sam.sort $read_length $segment_length > mmlog","EM logistic regression");# ECM



mySystem("cat multi.solid temp_file.sam | sort -t '/' -k 1,1n | $Bin/rmUnPairGapAli_new.pl > multi.solid_1");

mySystem("cat non_solid | $Bin/filter_non_from_solid.pl multi.solid_1 > non_solid_1;");

$pm=new Parallel::ForkManager($P);
for ($i=1;$i<=3;$i++){
	my $pid = $pm->start and next;
	if($i == 1){
		mySystem("$Bin/updateReadScore.pl final_junctions solid > solid_score");
	}
	if($i == 2){
		mySystem("$Bin/updateReadScore.pl final_junctions multi.solid_1 > multi.solid_score");
	}
	if($i == 3){
		mySystem("$Bin/updateReadScore.pl final_junctions_noncano non_solid_1 > non_cano_score");
	}
	$pm->finish;

}
$pm->wait_all_children;

mySystem("cat final_junctions final_junctions_noncano > junctions_score");


mySystem("cat solid_score multi.solid_score non_cano_score | $Bin/linkPair_Report_memfix.pl 1  > Gapped.sam_4");#  For paired-end 3<--------->2  1<-->2 remove 3 for it's far away.

mySystem("$Bin/presentJunc.pl junctions_score Gapped.sam_4 > SJS");

mySystem("$Bin/getCanoFlag.pl SJS $bwt.fa > SJS_canoflag","Remap on annotated junctions");
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
system("rm REMAP.fa; rm REMAP.*.ebwt");
mySystem("$Bin/translateRemapBWT.pl $read_length REMAP.bwt > REMAP.sam");
system("rm REMAP.bwt");

mySystem("cat Gapped.sam_4 REMAP.sam | sort -t '/' -k 1,1n | $Bin/mergeRemapSAM_memfix.pl SJS_canoflag 1 $bwt.fa | sort -t '/' -k 1,1n | $Bin/rmUnPairGapAli_new_19.pl | $Bin/linkPair_Report_memfix_new.pl 0 > final.sam_2","Present sam and junctions");

mySystem("$Bin/presentJunc_new_paired.pl SJS_canoflag  junctions_score final.sam_2 $bwt.fa paired_full.sam"); ##MAY 25
`$Bin/getMorePair.pl > new.sam`;


$now_string = localtime;
print "$now_string:   ";
print "Final Output: Generating bam file\n";
$pm=new Parallel::ForkManager($P);
for ($i=1;$i<=4;$i++){
	my $pid = $pm->start and next;
	if($i == 1){
		mySystem("$Bin/ID2name_pair.pl truesight_name_link FULL.sam > FULL.sam_; mv FULL.sam_ FULL.sam");
	}
	if($i == 2){
		mySystem("$Bin/ID2name_pair.pl truesight_name_link GapAli.sam > GapAli.sam_; mv GapAli.sam_ GapAli.sam");
	}
	if($i == 3){
		mySystem("$Bin/ID2name_pair.pl truesight_name_link EX_FULL > EX_FULL_; mv EX_FULL_ EX_FULL");
	}
	if($i == 4){
		mySystem("$Bin/ID2name_pair.pl truesight_name_link new.sam > new.sam_; mv new.sam_ new.sam");
	}
	$pm->finish;
}
$pm->wait_all_children;


if($report_read_name != 0){
	`cat head FULL.sam GapAli.sam EX_FULL new.sam | samtools view -Sb - | samtools sort - alignment`;
}
else{
	`cat FULL.sam GapAli.sam EX_FULL new.sam | $Bin/trimReadName.pl head | samtools view -Sb - | samtools sort - alignment`;
}
if($clean == 0){
	`rm -r temp_data`;
	system("rm FULL.sam multi* solid* non* temp* REMAP* SJS* train* N new* Gapped* final* *.log k mmlog initial_train_sets.csv junctions_score head paired_full.sam EX_FULL truesight_name_link chr_num");
}
$NOW = time -$NOW;
printf("\n\nTotal running time: %02d:%02d:%02d\n\n", int($NOW / 3600), int(($NOW % 3600) / 60),int($NOW % 60));


sub mySystem{
	my $mySystemCommand = $_[0];
	if(defined $_[1]){
		if($_[1] =~ /^0$/){
			system( $mySystemCommand );
			return;
		}
		$now_string = localtime;
		print "$now_string:   ";
		print $_[1],"\n";
		print RUNLOG "$now_string:   ";
		print RUNLOG $_[1],"\n";
	}

	my $returnCode = system( $mySystemCommand );
	if ( $returnCode != 0 ) {
		$now_string = localtime;
		print RUNLOG "$now_string:	Failed executing [$mySystemCommand]\n";
		die "$now_string:	Failed executing [$mySystemCommand]\n";
	}
}
