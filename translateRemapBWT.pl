#!/usr/bin/perl
#
#
$length = shift@ARGV;

open($in,"<",shift@ARGV);
while(<$in>){
	@m = split(/\s+/);
	@k = split(/:/,$m[2]);
	$chr = $k[0];
	$L = 0;
	$flag1 = 0;
	$CIGAR="";
	for($i = 1; $i <= ($#k-1)/2; $i++){
		$temp = $L;
		$L += $k[$i*2] - $k[$i*2-1];
		if($m[3] < $L && $flag1 == 0){
			$pos = $m[3] - $temp + $k[$i*2-1];
			$CIGAR=($L - $m[3])."M".($k[$i*2+1] - $k[$i*2])."N";
			$flag1 = 1;
			next;
		
		}
		if($m[3] + $length > $L && $flag1 == 1){
			$CIGAR.=($k[$i*2] - $k[$i*2-1])."M".($k[$i*2+1] - $k[$i*2])."N";
		}
		if($m[3] + $length <= $L && $flag1 == 1){
			
			$CIGAR.=($m[3]+$length-$temp)."M";
			last;
		}
	}
#	$hash{$m[0]}{$chr}{$pos}

	print $m[0],"\t", $m[1],"\t",$chr,"\t",$pos,"\t",$CIGAR, "\t",$k[$#k],"\t",$m[4],"\t",$m[5],"\ttag","\n";
}




