#!/usr/bin/perl
while(@ARGV){

	open($in,"<",shift @ARGV);

	while(<$in>){
		$lll = $_;
		@m = split(/\t/);
		@k = split(/M|N/,$m[5]);
		$s = $m[3];## need change after gapped reconpile
		$err = $m[7];
		$multi = $m[8];
		if($multi == 0){
			$multi = 1;
		}
		for $i (1 .. ($#k)/2){
			$s+=$k[$i*2-2];
			$e = $s + $k[$i*2-1];
			$t = "$m[2]:$s:$e";
			$hash{$t}[0]++;
			@p = split(/:/,$m[12]);
			if($p[2] == 1){
				$hash{$t}[3] = "+";
			}
			else{
				$hash{$t}[3] = "-";
			}
			if($hash{$t}[1] eq ""){$hash{$t}[1] = $k[$i*2-2];}
			else{if($hash{$t}[1] < $k[$i*2-2]){$hash{$t}[1] = $k[$i*2-2];}}
			if($hash{$t}[2] eq ""){$hash{$t}[2] = $k[$i*2];}
			else{if($hash{$t}[2] < $k[$i*2]){$hash{$t}[2] = $k[$i*2];}}
			$s+=$k[$i*2-1];
			$hash{$t}[4] += $multi;
			if($hash{$t}[5] eq ""){
				$hash{$t}[5] = $err;
			}
			elsif($hash{$t}[5] > $err){
				$hash{$t}[5] = $err;
			}
			$hash{$t}[6]{$m[3]}++;
		}
	}
}

foreach $key (keys %hash){
#	print "$key\t$hash{$key}[0]\t$hash{$key}[1]\t$hash{$key}[2]\t$hashjunction{$key}\n";
#	if($hash{$key}[0] > 5){
	@j = split(/:/,$key);
	$m = $hash{$key}[4]/$hash{$key}[0];
#		if($j[1] == )
#		if($hash{$key}[3] eq "+"){
	$total = 0;
	foreach $pos (keys %{$hash{$key}[6]}){
		$total += $hash{$key}[6]{$pos};
	}
	$entropy = 0;
	foreach $pos (keys %{$hash{$key}[6]}){
		$entropy -= log($hash{$key}[6]{$pos}/$total)/log(10);
	}
	print "$j[0]\t$hash{$key}[3]\t$j[1]\t$j[2]\t$hash{$key}[0]\t$hash{$key}[1]\t$hash{$key}[2]\t$entropy\t$m\t$hash{$key}[5]\n";
#		}
#		else{
#			print "$j[0]\t$hash{$key}[3]\t$j[2]\t$j[1]\t$hash{$key}[0]\t$hashjunction{$key}\n";
#		}
#	}
}
