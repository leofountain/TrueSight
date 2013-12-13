#!/usr/bin/perl
#
open(I,"<",shift@ARGV);
open(O,">chr_num");
while(<I>){
	chomp;
	if(substr($_,0,1) eq ">"){
		$N++;
		@m = split(/\s+/);
		if($#m > 0){
			print "Chromosome line should be single string without blank: $_\n";
			die;
		}
	}
}

print O $N;


