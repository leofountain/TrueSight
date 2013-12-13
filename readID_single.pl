#!/usr/bin/perl
#
$FASTQ_LIST = shift@ARGV;
@LIST = split(/,/,$FASTQ_LIST);
my $N=0;
open (O,">truesight_single_temp.fastq");
while(@LIST){
	open(I,"<",shift@LIST);
	my $p=0;
	while(<I>){
		$p++;
		if($p%4 == 1){
			$ID = "";
			chomp($_);
			@m = split(/\s+/,$_);
			#$ID = sprintf("%x", $N);
			$ID = $N;
			print $ID,"\t",substr($m[0],1),"\n";
			print O "@",$ID,"\n";
			$N++;
		}
		else{
			print O $_;
		}
	}
}
