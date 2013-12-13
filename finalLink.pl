#!/usr/bin/perl
#
#
#discard gapped read if gapped alignment is inconsistent with full length alignment


$READ_LENGTH = shift@ARGV;

while(<STDIN>){
	chomp;
	$line = $_;
	@m = split(/\t/);

	$name = substr $m[0],0,-2;
	if($name_temp ne $name){
		$temp = $name_temp;
		$name_temp = $name;
		do_gap();
		%fullread=();
	}
	@m = split(/\t/, $line);

	$side = substr $m[0],-1; 
	$name = substr $m[0],0,-2;
#	print $name,"\t",$m[1],"\n";
		@temp = ();
		push @temp,$m[2],$m[3],$m[1],$line;# chr	pos	ori
		push @{$fullread{$side}}, [@temp];

}
do_gap();
sub do_gap{
	my $side = 1;
	if(scalar @{$fullread{$side}} == 0){
		for($i = 0; $i < scalar @{$fullread{3-$side}}; $i++){
			my @ld = split(/\t/,$fullread{3-$side}[$i][3]);
			if($ld[1] == 0){
				$ld[1] = 137;
			}
			else{
				$ld[1] = 153;
			}
			print join("\t",@ld),"\n";
		}
		return;

	}

	for(my $t = 0; $t < scalar @{$fullread{$side}}; $t++){
		my $ori = $fullread{$side}[$t][2];
		my $chr = $fullread{$side}[$t][0];
		my $pos = $fullread{$side}[$t][1];
		my $temp = -1; 
		$flag = 0 ;
		for($i = 0; $i < scalar @{$fullread{3-$side}}; $i++){
			$flag = 1;
			if($fullread{3-$side}[$i][2] == 16-$ori && $fullread{3-$side}[$i][0] eq $chr){
				if($ori == 0){
					if($pos < $fullread{3-$side}[$i][1] && $fullread{3-$side}[$i][1] - $pos < 20000){
						if($temp == -1){
							$id = $i;
							$temp = $fullread{3-$side}[$i][1];
						}
						else{
							if($fullread{3-$side}[$i][1] - $pos < $temp -$pos){
								$id = $i;
								$temp = $fullread{3-$side}[$i][1];
							}
						}
					}
				}
				if($ori == 16){
					if($pos > $fullread{3-$side}[$i][1] && $pos - $fullread{3-$side}[$i][1] < 20000){
						if($temp == -1){
							$id = $i;
							$temp = $fullread{3-$side}[$i][1];
						}
						else{
							if($pos - $fullread{3-$side}[$i][1]< $pos - $temp){
								$id = $i;
								$temp = $fullread{3-$side}[$i][1];
							}
						}

					}
				}
			}
		}
		#print "cc\t",$id,"\n";
		if($flag == 1 && $temp != -1){
			my @lo = split(/\t/,$fullread{$side}[$t][3]);
			my @ld = split(/\t/,$fullread{3-$side}[$id][3]);
			$lo[6] = "=";
			$ld[6] = "=";
			$lo[7] = $fullread{3-$side}[$id][1];
			$ld[7] = $pos;
			my $gap = abs($lo[7] - $pos) + $READ_LENGTH;
			if($lo[1] == 0){
				$lo[1] = 99;
				$ld[1] = 147;
				$lo[8] = $gap;
				$ld[8] = -$gap;
				print join("\t",@lo),"\n",join("\t",@ld),"\n";
			}
			else{
				$lo[1] = 83;
				$ld[1] = 163;
				$lo[8] = -$gap;
				$ld[8] = $gap;
				#$#lo = 10;
				#$#ld = 10;

				print join("\t",@ld),"\n",join("\t",@lo),"\n";
			}
		}
		if($flag == 0){
			my @lo = split(/\t/,$fullread{$side}[$t][3]);
			if($lo[1] == 0){
				$lo[1] = 73;
			}
			else{
				$lo[1] = 89;
			}
			print join("\t",@lo),"\n";
		}
		if($flag == 1 && $temp == -1){
		}
	}

}




