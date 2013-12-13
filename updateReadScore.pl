#!/usr/bin/perl
#
#
#
#
open($in,"<",shift@ARGV);#score
while(<$in>){
	chomp;
	@m = split(/\t/);
	$t = "$m[0]:$m[1]:$m[2]";
	$score{$t} = $m[$#m];
}


open($in,"<",shift@ARGV);#sam
while(<$in>){
	chomp;
	@m = split(/\t/);
	@k = split(/M|N/,$m[5]);
	$s = $m[3];## need change after gapped reconpile
	$S = 1;
	for $i (1 .. ($#k)/2){
		$s+=$k[$i*2-2];
		$e = $s + $k[$i*2-1];
		$t = "$m[2]:$s:$e";
		$S *= $score{$t};
		$s+=$k[$i*2-1];
	}
	print $_,"\tAS:f:",$S,"\n";

}																																																						
