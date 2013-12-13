#!/usr/bin/perl
#
#
#
#
#got junctions from temp SAM and present formal SAM
#
#
#
#

open($in,"<",shift @ARGV); #junction reference

while(<$in>){
	chomp;
	@m = split(/\t/);
	$t = "$m[0]:$m[1]:$m[2]";
	if($ref{$t} eq ""){
		$ref{$t} = $m[$#m];
	}
	else{
		$ref{$t} = $ref{$t} < $m[$#m]? $m[$#m] : $ref{$t};
	}
}


open($in,"<",shift @ARGV);

while(<$in>){
	$lll = $_;
	@m = split(/\t/);
	@k = split(/M|N/,$m[5]);
	$s = $m[3];## need change after gapped reconpile
	if($multi == 0){
		$multi = 1;
	}
	for $i (1 .. ($#k)/2){
		$s+=$k[$i*2-2];
		$e = $s + $k[$i*2-1];
		$t = "$m[2]:$s:$e";
		$hash{$t}[0]++;
		$s+=$k[$i*2-1];
		$cano{$t} = $m[6];
	}
}


foreach $key (keys %hash){
	@j = split(/:/,$key);
	print "$j[0]\t$j[1]\t$j[2]\t$cano{$key}\t$ref{$key}\n";
}
