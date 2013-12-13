#!/usr/bin/perl
#
#
#discard gapped read if gapped alignment is inconsistent with full length alignment

#$solid = shift@ARGV;

#system("cat $solid temp_file.sam | sort -t '/' -k 1,1 > temp_file.sam.sorted");

#open ($in,"<temp_file.sam.sorted");
#open($out,">discard_gap");

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
		push @temp,$m[2],$m[3],$m[1];# chr	pos	ori
		push @{$fullread{$name}{$side}}, [@temp];
	}
	else{
		push @all,$line;
	}

}
do_gap();




sub do_gap{
	for $ii (0 .. $#all){
		my @m = split(/\t/,$all[$ii]);

		my $name = substr $m[0],0,-2;
		$side = substr $m[0],-1;
		my @ali = split(/M|N/,$m[5]);
		$end = $m[3];
		$temp = -1;
		$flag = 0;
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
						}
						else{
							if($fullread{$name}{3-$side}[$i][1] - $end < $temp -$end){
								$temp = $fullread{$name}{3-$side}[$i][1];
							}
						}
					}
				}
				if($m[1] == 16){
					if($m[3] > $fullread{$name}{3-$side}[$i][1] && $m[3] - $fullread{$name}{3-$side}[$i][1] < 100000){
						if($temp == -1){
							$temp = $fullread{$name}{3-$side}[$i][1];
						}
						else{
							if($m[3] - $fullread{$name}{3-$side}[$i][1]< $m[3] - $temp){
								$temp = $fullread{$name}{3-$side}[$i][1];
							}
						}

					}
				}
			}
		}
		if($flag == 1 && $temp != -1){
			print $all[$ii],"\t","pos=$temp\n";
		}
		if($flag == 0){
			print $all[$ii],"\t","pos=NULL\n";
		}
	}

}




