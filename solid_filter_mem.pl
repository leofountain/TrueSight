#!/usr/bin/perl 

#open($in,"<",shift@ARGV);
$name_temp = "";
%hash=();
while(<STDIN>){
	$line = $_;
	@m = split(/\s+/);
	if($m[0] ne $name_temp){
		$temp1 = $m[0];
		action();
		@count = ();
		%hash=();
		$name_temp = $temp1;
	}
	@m = split(/\s+/,$line);
	if($hash{$m[1]}{$m[3]}{$m[5]} eq ""){
		$hash{$m[1]}{$m[3]}{$m[5]} = 1;
		push @count,$line;
	}
}
action();

sub action{
	if ( scalar @count == 1){
		print $count[0];
	}
	else{
		for my $i (0 .. $#count){
			my @m = split(/\s+/, $count[$i]);
			my @k = split(/M|N/,$m[5]);
			my $s = $m[3]-1;
			for $j (1 .. ($#k)/2){
				$s+=$k[$j*2-2];
				$e = $s + $k[$j*2-1];
				$first{$s}{$e} = 1;
				$second{$e}{$s} = 1;
				$junction{$s}{$e}{$i} = 1;
			}
		}
		foreach $f (keys %first){
			if(scalar keys %{$first{$f}} > 0){
				@s = sort {$a <=> $b} keys %{$first{$f}};	
				for $i (1 .. $#s){
					foreach $key (keys %{$junction{$f}{$s[$i]}}){
						$count[$key] = "";
					}
				}

			}
		}
		foreach $e (keys %second){
			if(scalar keys %{$second{$e}} > 0){
				@s = sort {$b <=> $a} keys %{$second{$e}};
				for $i (1 .. $#s){
					foreach $key (keys %{$junction{$s[$i]}{$e}}){
						$count[$key] = "";
					}
				}

			}
		}
		%first=();
		%second=();
		%junction = ();
		for $i (0 .. $#count){
			print $count[$i];
		}

	}

}
