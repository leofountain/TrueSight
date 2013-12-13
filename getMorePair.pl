#!/usr/bin/perl
#
open(I,"<FULL.sam");
while(<I>){
	@m = split(/\s+/);
	$name = substr $m[0],0,-2;
	$hash{$name} = 1;
}


open(I,"<temp_file.sam");
while(<I>){
	chomp;
	@m = split(/\s+/);
	$name = substr $m[0],0,-2;
	if($hash{$name} != 1){
		$#m = 13;
		$flag = substr $m[0],-1,1;

		if($flag == 1){
			if($m[1] == 0){
				$m[1] = 73;
			}
			else{
				$m[1] = 89;
			}
		}
		else{
			if($m[1] == 0){
				$m[1] = 137;
			}
			else{
				$m[1] = 153;
			}
		}
		print join("\t",@m),"\n";
	}
}

