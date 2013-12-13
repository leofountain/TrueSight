#!/usr/bin/perl
#
open(I,"<",shift@ARGV);
while(<I>){
	chomp;
	if($_ eq ">"){
		print ">\n";
		$TEMP = <I>;
		print $TEMP;
		my @SEQ = ();
		my %LOCAL = ();
		my %check = ();
		while(<I>){
			chomp;
			if($_ eq ">"){
				last;
			}
			@m = split(/\s+/);
			if(exists $check{$_}){
				next;
			}
			push @{$LOCAL{$m[0]}}, $m[3];
			push @SEQ, $_;
			$check{$_} = 1;
			
		}
		my %BLACK;
		foreach $key (keys %LOCAL){
			if(scalar @{$LOCAL{$key}} > 1){
				my @l = sort {$a <=> $b} @{$LOCAL{$key}};
				if($l[0] < 50000){
					for $i (0 .. $#l){
						if($l[$i] > 50000){
							$BLACK{$key}{$l[$i]} = 1;
						}
					}
				}
				else{
					for $i (1 .. $#l){
						$BLACK{$key}{$l[$i]} = 1;
					}
				}
			}
		}
		for $i (0 .. $#SEQ){
			@m = split(/\s+/, $SEQ[$i]);
			if($BLACK{$m[0]}{$m[3]} == 1){
				next;
			}
			print $SEQ[$i],"\n";
		}
		print ">\n";
	}
}
