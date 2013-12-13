#!/usr/bin/perl
#
open(I,"<", shift@ARGV);
while(<I>){
	chomp;
	print $_,"\n";
}
while(<STDIN>){
	chomp;
	@m = split(/\s+/);
	$m[0] = substr($m[0],0,-2);
	print join("\t",@m),"\n";
}
