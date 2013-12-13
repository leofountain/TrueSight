#!/usr/bin/perl
#
open(I,"<",shift@ARGV);
$POSITIVE = shift @ARGV;
$ratio = shift @ARGV;
while(<I>){
	chomp;
	@m = split(/\s+|,/);
	if($m[$#m] == 1){
		print $_,"\n";
	}
	else{
		$M++;
		if($M>$ratio*$POSITIVE){
			next;
		}
		print $_,"\n";
	}
}
#print $N,"\t",$M,"\n";
