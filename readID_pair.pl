#!/usr/bin/perl
#
$FASTQ_LIST = shift@ARGV;
$F = shift@ARGV;
$Original_F  = $F;
@LIST = split(/,/,$FASTQ_LIST);
my $N=0;
open (O,">truesight_pair_temp.$F.fastq");
#open (O1,">truesight_pair_temp.2.fastq");
while(@LIST){
	$FILE = shift@LIST;
	open(I,"<",$FILE);
	$TEST_LINE = <I>;
	my @m = split(/\s+/,$TEST_LINE);
	if(substr($m[0],-2,1) eq "/" && (substr($m[0],-1,1) eq "1" || substr($m[0],-1,1) eq "2")){
		$FLAG = 1;
		$F = substr($m[0],-1,1);
	}
	else{
		$FLAG = 0;
	}
	close(I);
	my $p=0;
	open(I,"<",$FILE);
	while(<I>){
		$p++;
		if($p%4 == 1){
			$ID = "";
			chomp($_);
			@m = split(/\s+/,$_);
			#$ID = sprintf("%x", $N);
			$ID = $N;
			if($Original_F == 1){
				if($FLAG == 1){
					print $ID,"\t",substr($m[0],1,-2),"\n";
				}
				else{
					print $ID,"\t",substr($m[0],1),"\n";
				}
			}
			print O "@",$ID,"/$F\n";
			$N++;
		}
		else{
			print O $_;
		}
	}
}
