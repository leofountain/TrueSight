#!/usr/bin/perl 
#
#
#got junctions from temp SAM and present formal SAM
#
#presentJunc_new_paired.pl SJS_canoflag  junctions_score final.sam_2 paired_full.sam"
#
#
#
#
open($in,"<",shift @ARGV); #cano flag

while(<$in>){
	chomp;
	@m = split(/\s+/);
	$t = "$m[0]:$m[1]:$m[2]";
	$cano{$t} = $m[3];
	if($m[3] == 0){
		$N_non++;
	}
	if($m[4] < 0.6){
		$N_low++;
	}

	$N_all++;
}



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

$gap = shift @ARGV;
open($in,"<",$gap);

while(<$in>){
	$lll = $_;
	@m = split(/\t/);
	if($m[$#m] eq "pos=NULL"){
		my @tt = split(/:/,$m[$#m-1]);
		if($tt[2] < 0.1){
			next;
		}
	}
	@k = split(/M|N/,$m[5]);
	$s = $m[3];## need change after gapped reconpile
	for $i (1 .. ($#k)/2){
		$s+=$k[$i*2-2];
		$e = $s + $k[$i*2-1];
		$t = "$m[2]:$s:$e";
		$hash{$t}++;
		$s+=$k[$i*2-1];
	}
}

foreach $key (keys %hash){
	@s = split(/:/,$key);
	push @{$junc_ori{$s[0]}},[$s[1]-1,$s[2]];
}

$chr = "";
$CHR_TEMP = "";
open($in,"<",shift@ARGV);#REF MAY 25
while(<$in>){
	chomp;
	if(substr($_,0,1) eq ">"){
		if($CHR_TEMP ne ""){
			$hash_ori{$chr} = $CHR_TEMP;
			$CHR_TEMP = "";
		}
		Jingyi();
		@c = split(/\s+/,$_); #in case of blank in chr line;
		$chr = substr($c[0],1);
		next;
	}
	$CHR_TEMP .= $_;
}
if($CHR_TEMP ne ""){
	$hash_ori{$chr} = $CHR_TEMP;
	$CHR_TEMP = "";
}
Jingyi();


sub Jingyi{
	my $temp = $chr;
	if($temp ne ""){
		for($i = 0; $i < scalar @{$junc_ori{$temp}}; $i++){
			$f = substr($hash_ori{$temp}, $junc_ori{$temp}[$i][0], 2);
			$e = substr($hash_ori{$temp}, $junc_ori{$temp}[$i][1]-3 , 2);
			$f =~ tr/a-z/A-Z/;
			$e =~ tr/a-z/A-Z/;
			if($f eq "GT" && $e eq "AG" || $f eq "GC" && $e eq "AG" || $f eq "AT"&& $e eq "AC"){
				$flag = "+";
			}
			elsif($f eq "CT" && $e eq "AC" || $f eq "CT"&& $e eq "GC" || $f eq "GT"&& $e eq "AT"){
				$flag = "-";
			}
			else{$flag = "+";}## how to label non-canonical
			my $start = $junc_ori{$temp}[$i][0]+1;
			my $kk = "$temp:$start:$junc_ori{$temp}[$i][1]";
			$ORI{$kk} = $flag;

		}
		delete $hash_ori{$temp};
	}
}






foreach $key (keys %hash){
	@j = split(/:/,$key);
	if($j[2]-$j[1]>8000 && $ref{$key} < 0.2){
		$black{$key}=1;
	}
	if($N_non/$N_all > 0.35){
		if($cano{$key} == 0 && $ref{$key} < 0.7){##########remove all non-canonical with score < 0.7
			$black{$key}=1;
		}
		if($cano{$key} == 0 && $ref{$key} < 0.99 && $hash{$key} < 10){
			$black{$key}=1;
		}
		if($cano{$key} == 2 && $hash{$key} < 5){
			$black{$key}=1;
		}

	}
	if($N_low/$N_all > 0.69 && $N_all > 280000){
		if($ref{$key} < 0.6){
			$black{$key}=1;
		}
	}
	if($N_all > 500000 && $ref{$key} < 0.05){
		$black{$key}=1;
	}

	if($cano{$key} != 1){

		$non_ca{$j[0]}{$j[1]}{$j[2]} = $ref{$key};
		$junc_semi{$j[0]}{$j[1]}=1;
		$junc_semi{$j[0]}{$j[2]}=1;
		if($ref{$key} > 0.8){
			$high{$j[0]}{$j[1]}=1;
			$high{$j[0]}{$j[2]}=1;
		}
	}
	else{
		if($ref{$key} < 0.2){
			$low{$j[0]}{$j[1]}{$j[2]} = $ref{$key};
		}
		$junc{$j[0]}{$j[1]}=1;
		$junc{$j[0]}{$j[2]}=1;
	}
}

foreach $chr (keys %non_ca){
	foreach $b (keys %{$non_ca{$chr}}){
		foreach $e (keys %{$non_ca{$chr}{$b}}){
			$flag = 0;
			for $i ($b-5 .. $b+5){
				$t = "$chr:$b:$e";
				if($junc{$chr}{$i} == 1 && $ref{$t} > 0.2){
					if($b == $i && $ref{$t} > 0.5){last;
					}
					$black{$t}=1;
					$flag = 1;
					last;
				}
			}
			if($flag == 1){
				last;
			}
			for $i ($e-5 .. $e+5){
				$t = "$chr:$b:$e";
				if($junc{$chr}{$i} == 1 && $ref{$t} > 0.2){
					if($e == $i && $ref{$t} > 0.5){last;}
					$black{$t}=1;
					last;
				}
			}
		}
	}
}

foreach $chr (keys %low){
	foreach $b (keys %{$low{$chr}}){
		foreach $e (keys %{$low{$chr}{$b}}){
			$flag = 0;
			for $i ($b-5 .. $b+5){
				$t = "$chr:$b:$e";
				if($high{$chr}{$i} == 1 && $black{$t} != 1){
					if($b == $i && $ref{$t} > 0.5){last;}
					$black{$t}=1;
					$flag = 1;
					last;
				}
			}
			if($flag == 1){
				last;
			}
			for $i ($e-5 .. $e+5){
				$t = "$chr:$b:$e";
				if($high{$chr}{$i} == 1 && $black{$t} != 1){
					if($e == $i && $ref{$t} > 0.5){last;}
					$black{$t}=1;
					last;
				}
			}
		}
	}
}
open($in,"<",$gap);
open($o1,">GapAli.sam");
open($o2,">GapAli.junc");
$name_temp = "";
@all = ();
while(<$in>){
	chomp;
	$lll = $_;
	@m = split(/\t/);
	$name = substr($m[0],0,-2);
	if($m[$#m] eq "pos=NULL"){
		my @tt = split(/:/,$m[$#m-1]);
		if($tt[2] < 0.1){
			next;
		}
	}
	if($name ne $name_temp){
		action();
		@all = ();
		$name_temp = $name;
	}
	push @all, $lll;
}
action();

sub action{
	%flag=();
	%F=();

	my %local_ori = ();
	for($i=0; $i<scalar @all;$i++){
		my @m = split(/\t/,$all[$i]);
		my @k = split(/M|N/,$m[5]);
		$s = $m[3];
		for $ii (1 .. ($#k)/2){                  
			$s+=$k[$ii*2-2];                                         
			$e = $s + $k[$ii*2-1];                                                   
			$t = "$m[2]:$s:$e";
			$local_ori{$i} = $ORI{$t}; 

			if($black{$t} == 1){
				$flag{$i} = 1;
				@p = split(/=/,$m[$#m]);
				$F{$m[2]}{$p[1]}=1;
				last;
			}
			$s+=$k[$ii*2-1];                                                   

		}

	}
	for($i=0; $i<scalar @all;$i++){
		my @m = split(/\t/,$all[$i]);
		if($flag{$i} == 1){
			next;
		}
		elsif($F{$m[2]}{$m[3]} == 1){
			$m[$#m] = "pos=NULL";
			$all[$i] = join("\t",@m);
		}
		my @posi = split(/=|:/,$m[$#m]);
		$NAME_HASH{substr($m[0],0,-2)}{$posi[2]} = 1;
		if(exists $local_ori{$i}){
			if($local_ori{$i} eq ""){
				$local_ori{$i} = "+";
			}
			print $o1 SAM_FLAG($all[$i]),"\tXS:A:$local_ori{$i}\n";
		}
		else{
			print $o1 SAM_FLAG($all[$i]),"\tXS:A:+\n";
		}
	}
}

foreach $key (keys %FINAL_HASH){
	if($black{$key} == 1 || (!exists $hash{$key})){
		next;
	}
	if($ALL_MIS{$key} > 1 && $FINAL_HASH{$key} <= 1){
		next;
	}
	@j = split(/:/,$key);
	print $o2 "$j[0]\t$j[1]\t$j[2]\t$cano{$key}\t$FINAL_HASH{$key}\t$ref{$key}\n";

}


open(FULL,"<",shift@ARGV);## MAY
open(F,">FULL.sam");
while(<FULL>){
	my @m = split(/\s+/);
	if($NAME_HASH{substr($m[0],0,-2)}{$m[8]} == 1){
		print F $_;
	}
}




sub SAM_FLAG{
	my $SUM = 1;
	my $SUM_2 = 0;
	my $L = @_[0];
	my @m = split(/\s+/,$L);
	my @k = split(/M|N/,$m[5]);
	my $s = $m[3];## need change after gapped reconpile
	for $i (1 .. ($#k)/2){
		$s+=$k[$i*2-2];
		$e = $s + $k[$i*2-1];
		$t = "$m[2]:$s:$e";
		$FINAL_HASH{$t}++;
		if(exists $ALL_MIS{$t}){
			if($ALL_MIS{$t} > $m[4]){
				$ALL_MIS{$t} = $m[4];
			}
		}
		else{
			$ALL_MIS{$t} = $m[4];
		}
		$s+=$k[$i*2-1];
	}
	$m[4] = 255;

	my @pos = split(/=/,$m[$#m]);
	my $flag = substr($m[0],-1,1);
	if($flag == 1){
		$SUM_2 += 4;
	}
	else{
		$SUM_2 += 8;
	}
	if($m[1] == 0){
		if($pos[1] eq "NULL"){
			$SUM += 8;
		}
		else{
			$SUM += 2;
			$SUM_2 += 2;
		}
	}
	else{
		if($pos[1] eq "NULL"){
			$SUM += 8;
		}
		else{
			$SUM += 2;
			$SUM_2 += 1;
		}
	}
	if($pos[1] eq "NULL"){
		$m[6] = "*\t0\t0";
	}
	else{
		my @k = split(/:/,$pos[0]);
		my $p = int(-($k[2]));
		$m[6] = "=\t$pos[1]\t$p";
	}
	$m[1] = $SUM_2*16 + $SUM;
	#$m[$#m]="";
	$#m = $#m - 1;
	return join("\t",@m);


}	




