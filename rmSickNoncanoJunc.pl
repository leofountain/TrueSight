#!/usr/bin/perl
#
#
open($in,"<",shift@ARGV);
while(<$in>){
	chomp;
	#$hash{$_} = 1;
	@m = split(/\s+/);
	if($m[3] == 1){
		if($m[2] - $m[1]>8000 && $m[4] < 0.1){
			next;
		}
		$cano{$m[0]}{$m[1]}=1;
		$cano{$m[0]}{$m[2]}=1;
	}
	if($m[3] == 2){
		if($m[2] - $m[1]>8000 && $m[4] < 0.3){
			next;
		}
		$semicano{$m[0]}{$m[1]}=1;
		$semicano{$m[0]}{$m[2]}=1;
	}
	if($m[3] == 0){
		if($m[2] - $m[1]>8000 && $m[4] < 0.3){
			next;
		}
		$noncano{$m[0]}{$m[1]}=1;
		$noncano{$m[0]}{$m[2]}=1;
	}
	$hash{$_} = 1;
}

foreach $chr (keys %cano){
	foreach $point (keys %{$cano{$chr}}){
		for($i = -5; $i <= 5; $i++){
			if($i == 0){
				next;
			}
			if($semicano{$chr}{$point + $i} == 1){
				delete $semicano{$chr}{$point + $i};
			}
			if($noncano{$chr}{$point + $i} == 1){
				delete $noncano{$chr}{$point + $i};
			}
		}
	}
	foreach $point (keys %{$semicano{$chr}}){
		for($i = -5; $i <= 5; $i++){
			if($i == 0){
				next;
			}
			if($noncano{$chr}{$point + $i} == 1){
				delete $noncano{$chr}{$point + $i};
			}
		}
	}
}

foreach $key (keys %hash){
	@m = split(/\s+/,$key);
	if($m[3] == 2 && ($semicano{$m[0]}{$m[1]} != 1 || $semicano{$m[0]}{$m[2]} != 1) || $m[3] == 0 && ($noncano{$m[0]}{$m[1]} != 1 || $noncano{$m[0]}{$m[2]} != 1)){next;}
	print $key,"\n";
}




