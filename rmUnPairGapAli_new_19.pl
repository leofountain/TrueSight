#!/usr/bin/perl
#
#
#discard gapped read if gapped alignment is inconsistent with full length alignment

#$solid = shift@ARGV;
#$length = shift@ARGV;
#system("cat $solid temp_file.sam | sort -t '/' -k 1,1 > temp_file.sam.sorted");

#open ($in,"<temp_file.sam.sorted");
#open($out,">discard_gap");
open($out_full,">paired_full.sam");
#open(O,">O");
$length = 0;
$name_temp = "";
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
		@all=();
	}
	@m = split(/\t/, $line);

	$side = substr $m[0],-1; 
	$name = substr $m[0],0,-2;
	@ali = split(/M|N/,$m[5]);
	if($m[$#m] eq "tag"){
		@temp = ();
		push @temp,$m[2],$m[3],$m[1], $line;# chr	pos	ori
		push @{$fullread{$name}{$side}}, [@temp];
	}
	else{
		push @all,$line;
	}

}
do_gap();




sub do_gap{
	my @LL=();
	my $CC=();
	for $ii (0 .. $#all){
		my @m = split(/\t/,$all[$ii]);

		my $name = substr $m[0],0,-2;
		$side = substr $m[0],-1;
		my @ali = split(/M|N/,$m[5]);
		$end = $m[3];
		$temp = -1;
		$flag = 0;
		my $best_i = 0;
		for $t (0 .. $#ali){
			$end += $ali[$t];
		}
		for($i = 0; $i < scalar @{$fullread{$name}{3-$side}}; $i++){
			$flag = 1;
			if($fullread{$name}{3-$side}[$i][2] == 16-$m[1] && $fullread{$name}{3-$side}[$i][0] eq $m[2]){
				if($m[1] == 0){
					if($m[3] < $fullread{$name}{3-$side}[$i][1] && $fullread{$name}{3-$side}[$i][1] - $end < 100000){
						if($temp == -1){
							$temp = $fullread{$name}{3-$side}[$i][1];
							$best_i = $fullread{$name}{3-$side}[$i][3];
						}
						else{
							if($fullread{$name}{3-$side}[$i][1] - $end < $temp -$end){
								$temp = $fullread{$name}{3-$side}[$i][1];
								$best_i = $fullread{$name}{3-$side}[$i][3];
							}
						}
					}
				}
				if($m[1] == 16){
					if($m[3] > $fullread{$name}{3-$side}[$i][1] && $m[3] - $fullread{$name}{3-$side}[$i][1] < 100000){
						if($temp == -1){
							$temp = $fullread{$name}{3-$side}[$i][1];
							$best_i = $fullread{$name}{3-$side}[$i][3];
						}
						else{
							if($m[3] - $fullread{$name}{3-$side}[$i][1]< $m[3] - $temp){
								$temp = $fullread{$name}{3-$side}[$i][1];
								$best_i = $fullread{$name}{3-$side}[$i][3];
							}
						}

					}
				}
			}
		}
		if($flag == 1 && $temp != -1){
			my $e = $length + $temp;
			my @t = split(/\s+/,$best_i);
			my $flag_t = substr($t[0],-1,1);
			$t[6]="=";
			$t[7]=$m[3];
			my $sum = 0;
			if($t[1] == 0){
				$sum+=2;
			}
			else{
				$sum+=1;
			}
			if($flag_t == 1){
				$sum += 4;
			}
			else{
				$sum += 8;
			}
			$t[1] = 16*$sum+3;

			if($temp > $m[3]){
				$t[8] = $m[3] - $e;
			}
			else{
				$t[8] = $end - $temp;
			}
			print $all[$ii],"\t","pos:full:$t[8]=$temp\n";
			#print O $all[$ii],"\t","pos:full:$t[8]=$temp\n";

			$#t = 13;
			print $out_full join("\t",@t),"\n";

				

		}
		if($flag == 0){
			print $all[$ii],"\t","pos=NULL\n";
			#print O $all[$ii],"\t","pos=NULL\n";
		}
		if($flag == 1 && $temp == -1){
			#print $out $all[$ii],"\n";
		}
	}

}




