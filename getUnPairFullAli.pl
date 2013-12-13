#!/usr/bin/perl
#
#
open($in,"<",shift@ARGV);#temp.un.fq
$c = 0;
open($O,">","temp_file.sam");
while(<$in>){
	$c++;
	if($c == 4){
		$c=0;
		next;
	}
	if($c==1){
		chomp;
		$name = substr $_,1,-2;
		#	print $name,"\n";
		$name_hash{$name}=1;
	}
}
open($in,"<",shift@ARGV);#full length 

while(<$in>){
	chomp;
	@m = split(/\t/);
	$name = substr $m[0],0,-2;
	if($name_hash{$name} == 1){
		print $O $_,"\ttag\n";
	}
	else{
		print $_,"\n";
	}

}



