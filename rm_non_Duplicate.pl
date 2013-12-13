#!/usr/bin/perl
#
#
#
$file = shift@ARGV;
open($in,"<",$file);#non_solid

while(<$in>){
	@m=split(/\t/);
	if($m[6] == 2){
		$hash{$m[0]}=1;
	}
}


open($in,"<",$file);#non_solid

while(<$in>){
	@m=split(/\t/);
	if($hash{$m[0]}==1 && $m[6] == 0){
		next;
	}       
	print;
}


