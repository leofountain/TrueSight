#!/usr/bin/perl
$FLAG = shift@ARGV;

#open($in,"<",shift@ARGV);# link both gapped ends
@reserve = ();
%all=();
%read=();
$temp_name="";
while(<STDIN>){
	chomp;
	@m=split(/\t/);
	$line = $_;
	my $name = substr $m[0],0,-2;
	if($name ne $temp_name){
		$temp_name = $name;
		for(my $i=0; $i<scalar @reserve; $i++){
			my @m=split(/\t/,$reserve[$i]);
			my $chr = $m[2];
			my @s=split(/=/,$m[$#m-$FLAG]);
			my @c = split(/:/,$m[$#m -1 + $FLAG]);
			my @ali = split(/M|N/,$m[5]);
			my $end = $m[3];
			for my $t (0 .. $#ali){
				$end += $ali[$t];
			}
			if($max_l{$m[0]}{$chr}{$m[3]}==$c[2] && $max_r{$m[0]}{$chr}{$end}==$c[2]){
				handle($i);		
			}
		}

		foreach my $chr (keys %all){
			foreach my $pos (keys %{$all{$chr}}){
				print join("\n",@{$all{$chr}{$pos}}),"\n";
			}
		}
		action();
		%flag=();
		%read=();
		%fullhash = ();
		%all=();
		%max_l = ();
		%max_r = ();
		@reserve = ();
	}
	push @reserve,$line;
	my @m=split(/\t/, $line);

	my $chr = $m[2];
	my @ali = split(/M|N/,$m[5]);
	my $end = $m[3];
	for $t (0 .. $#ali){
		$end += $ali[$t];
	}
	my @c = split(/:/,$m[$#m -1 + $FLAG]);
	if($max_l{$m[0]}{$chr}{$m[3]} ne ""){
		if($max_l{$m[0]}{$chr}{$m[3]} < $c[2]){
			$max_l{$m[0]}{$chr}{$m[3]}=$c[2];
		}
	}
	else{
		$max_l{$m[0]}{$chr}{$m[3]}=$c[2];
	}
	if($max_r{$m[0]}{$chr}{$end} ne ""){
		if($max_r{$m[0]}{$chr}{$end} < $c[2]){
			$max_r{$m[0]}{$chr}{$end}=$c[2];
		}
	}
	else{
		$max_r{$m[0]}{$chr}{$end}=$c[2];
	}

}
sub handle{
	my $i = @_[0];
	my @m=split(/\t/,$reserve[$i]);
	my @s=split(/=/,$m[$#m-$FLAG]);
	if($s[1] eq "NULL"){
		my $name = substr $m[0],0,-2;
		my $side = substr $m[0],-1;
		my @ali = split(/M|N/,$m[5]);
		my $end = $m[3];
		for $t (0 .. $#ali){
			$end += $ali[$t];
		}
		my @temp = ();
		push @temp,$m[2],$m[3],$end,$m[1], [@m];# chr      p
		push @{$read{$name}{$side}}, [@temp];
	}
	else{
		if($fullhash{$m[0]}{$m[2]}{$s[1]} eq ""){
			$fullhash{$m[0]}{$m[2]}{$s[1]} = $m[3];
			@{$all{$m[2]}{$s[1]}}=();
			push @{$all{$m[2]}{$s[1]}}, $reserve[$i];
		}
		else{
			if(abs($m[3] - $s[1]) < abs($fullhash{$m[0]}{$m[2]}{$s[1]} - $s[1])){
				$fullhash{$m[0]}{$m[2]}{$s[1]} = $m[3];
				@{$all{$m[2]}{$s[1]}}=();
				push @{$all{$m[2]}{$s[1]}}, $reserve[$i];
				next;
			}
			if(abs($m[3] - $s[1]) == abs($fullhash{$m[0]}{$m[2]}{$s[1]} - $s[1])){
				push @{$all{$m[2]}{$s[1]}}, $reserve[$i];
			}
		}

	}
}



for(my $i=0; $i<scalar @reserve; $i++){
	my @m=split(/\t/,$reserve[$i]);
	my $chr = $m[2];
	my @s=split(/=/,$m[$#m-$FLAG]);
	my @c = split(/:/,$m[$#m -1 + $FLAG]);
	my @ali = split(/M|N/,$m[5]);
	my $end = $m[3];
	for my $t (0 .. $#ali){
		$end += $ali[$t];
	}
	if($max_l{$m[0]}{$chr}{$m[3]}==$c[2] && $max_r{$m[0]}{$chr}{$end}==$c[2]){
		handle($i);
	}
}

foreach my $chr (keys %all){
	foreach my $pos (keys %{$all{$chr}}){
		print join("\n",@{$all{$chr}{$pos}}),"\n";
	}
}
action();


sub action{
	foreach my $name (keys %read){
		my $flag = 0;
		my $flag_=0;
		my %local = ();
		for (my $i = 0; $i < scalar @{$read{$name}{1}}; $i++){
			my $temp = -1;
			for (my $j = 0; $j < scalar @{$read{$name}{2}}; $j++){
				$flag_ = 1;
				if($read{$name}{2}[$j][0] eq $read{$name}{1}[$i][0] && $read{$name}{2}[$j][3] + $read{$name}{1}[$i][3] == 16){
					if($read{$name}{1}[$i][3] == 0 && $read{$name}{1}[$i][1] - $read{$name}{2}[$j][1] < 200 && $read{$name}{2}[$j][1] - $read{$name}{1}[$i][2] < 20000){
						if($temp == -1){
							$temp = $j;
						}
						else{
							if($read{$name}{2}[$j][1] - $read{$name}{1}[$i][2] < $read{$name}{2}[$temp][1] - $read{$name}{1}[$i][2]){
								$temp = $j;
							}
						}
					}
					if($read{$name}{1}[$i][3] == 16 && $read{$name}{1}[$i][1] - $read{$name}{2}[$j][1] > -200 && $read{$name}{1}[$i][1] - $read{$name}{2}[$j][2] < 20000){
						if($temp == -1){
							$temp = $j;
						}
						else{              
							if($read{$name}{1}[$i][1] - $read{$name}{2}[$j][2] < $read{$name}{1}[$i][1] - $read{$name}{2}[$temp][2]){
								$temp = $j;
							}
						}
					}
				}

			}
			if($temp != -1){
				if( $local{$temp} ne ""){
					if($read{$name}{1}[$i][3] == 0){
						if($read{$name}{1}[$local{$temp}][1] < $read{$name}{1}[$i][1]){
							$local{$temp} = $i;
						}
					}
					else{
						if($read{$name}{1}[$local{$temp}][1] > $read{$name}{1}[$i][1]){
							$local{$temp} = $i;
						}

					}
				}
				else{
					$local{$temp} = $i;
				}
			}
		}
		foreach my $temp (keys %local){
			my $i = $local{$temp};
			$flag = 1;
			my $t = scalar @{$read{$name}{1}[$i][4]};
			$read{$name}{1}[$i][4][$t-2 + 1 - $FLAG] = "pos=".$read{$name}{2}[$temp][1];
			$read{$name}{2}[$temp][4][$t-2 + 1 - $FLAG] = "pos=".$read{$name}{1}[$i][1];
			if($read{$name}{1}[$i][3] == 0){
				print join("\t",@{$read{$name}{1}[$i][4]}),"\n",join("\t",@{$read{$name}{2}[$temp][4]}),"\n";
			}
			else{
				print join("\t",@{$read{$name}{2}[$temp][4]}),"\n",join("\t",@{$read{$name}{1}[$i][4]}),"\n";
			}
		}		
		if($flag == 0 && $flag_ == 0){
			if(scalar @{$read{$name}{1}} < 10){
				for ($i = 0; $i < scalar @{$read{$name}{1}}; $i++){#only retain most significant 
					print join("\t",@{$read{$name}{1}[$i][4]}),"\n";
				}
			}
			if(scalar @{$read{$name}{2}} < 10){
				for ($i = 0; $i < scalar @{$read{$name}{2}}; $i++){
					print join("\t",@{$read{$name}{2}[$i][4]}),"\n";
				}
			}
		}
	}

}

