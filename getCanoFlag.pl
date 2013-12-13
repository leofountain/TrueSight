#!/usr/bin/perl
#
#
#
open($in,"<",shift@ARGV);#SJS
while(<$in>){
	chomp;
	@m = split(/\s+/);
	push @{$junc{$m[0]}},[$m[1],$m[2],$m[3],$m[4]];
}

$chr = "";
open($in,"<",shift@ARGV);#SJS
while(<$in>){
	chomp;
	if(substr($_,0,1) eq ">"){
		$temp = $chr;
		if($temp ne ""){
			for($i = 0; $i < scalar @{$junc{$temp}}; $i++){
				$f = substr($CHR_SEQ, $junc{$temp}[$i][0]-1, 2);
				$e = substr($CHR_SEQ, $junc{$temp}[$i][1]-3 , 2);
				$f =~ tr/a-z/A-Z/;
				$e =~ tr/a-z/A-Z/;


				if($f eq "GT" && $e eq "AG" || $f eq "CT" && $e eq "AC"){
					$flag = 1;
				}
				elsif(($f eq "GC" && $e eq "AG") || ($f eq "CT"&& $e eq "GC") || ($f eq "AT"&& $e eq "AC") || ($f eq "GT"&& $e eq "AT")){
					$flag = 2;
				}
				else{$flag = 0;}
				$junc{$temp}[$i][2] = $flag;
				print $temp,"\t", join("\t",@{$junc{$temp}[$i]}),"\n";

			}
		}
		$CHR_SEQ = "";
		@c = split(/\s+/,$_); #in case of blank in chr line;
		$chr = substr($c[0],1);
		next;
	}
	$CHR_SEQ .= $_;
}
$temp = $chr;
for($i = 0; $i < scalar @{$junc{$temp}}; $i++){
	$f = substr($CHR_SEQ, $junc{$temp}[$i][0]-1, 2);
	$e = substr($CHR_SEQ, $junc{$temp}[$i][1]-3 , 2);
	$f =~ tr/a-z/A-Z/;
	$e =~ tr/a-z/A-Z/;
	if($f eq "GT" && $e eq "AG" || $f eq "CT" && $e eq "AC"){
		$flag = 1;
	}
	elsif(($f eq "GC" && $e eq "AG") || ($f eq "CT"&& $e eq "GC") || ($f eq "AT"&& $e eq "AC") || ($f eq "GT"&& $e eq "AT")){
		$flag = 2;
	}
	else{$flag = 0;}
	$junc{$temp}[$i][2] = $flag;
	print $temp,"\t",join("\t",@{$junc{$temp}[$i]}),"\n";
	#print $f,"\t",$e,"\n";
}
