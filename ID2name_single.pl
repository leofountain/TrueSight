#!/usr/bin/perl
##
$MEM_LIMIT = 10000000;
$ID = 0;
$N = 0;
open(I,"<",shift@ARGV);
$FILE = shift@ARGV;
open(II,"<",$FILE);
while(<I>){
	chomp;
	@m = split(/\s+/);
	push @NAME_ARRAY, $m[$#m];
	$N++;
	if($N % $MEM_LIMIT == 0){
		$ID++;
		Replace_name();
		@NAME_ARRAY = ();
		if($FLAG == 1){
			last;
		}
	}
}
if($N % $MEM_LIMIT != 0 && $FLAG != 1){
	$ID++;
	Replace_name();
}

sub Replace_name{
	my $off_set = $MEM_LIMIT*($ID-1);
	if(scalar @TEMP != 0){
		my $name = $TEMP[0];
		if($name <= $N-1){
			$TEMP[0] = $NAME_ARRAY[$TEMP[0]-$off_set];
			print join("\t",@TEMP),"\n";
			@TEMP = ();
		}
		else{
			return;
		}
	}
	while(<II>){
		chomp;
		my @m = split(/\s+/);
		my $name = $m[0];
		if($name <= $N-1){
			$m[0] = $NAME_ARRAY[$m[0]-$off_set];
			print join("\t",@m),"\n";
		}
		else{
			@TEMP = @m;
			return;
		}
	}
	$FLAG = 1;
}
