#!/usr/bin/perl
#
#
#
open($in,"<",shift@ARGV);
open($dup,">duplicate_solid");
open($sig,">solid");

while(<$in>){
	@m = split(/\t/);
	push @{$hash{$m[0]}},$_;
}

foreach $key (keys %hash){
	if(scalar @{$hash{$key}} > 1){
		print $dup @{$hash{$key}};
	}
	else{
		print $sig $hash{$key}[0];
	}
}
