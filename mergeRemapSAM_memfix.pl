#!/usr/bin/perl
#
#
#
#
#SJS reMap.sam Gap.sam
use List::Util qw(first max maxstr min minstr reduce shuffle sum);

open($in,"<",shift@ARGV);#junc// SJS

while(<$in>){
	chomp;
	my @m = split(/\t/);
	$cano{$m[0]}{$m[1]}{$m[2]} = $m[3];
}
#$G = shift@ARGV;
#$S = shift@ARGV;
$pair = shift@ARGV||1;
#if($pair == 1){system("cat $G $S | sort -t '/' -k 1,1 > newtemp");}
#else{system("cat $G $S | sort -k 1,1 > newtemp");}

open($in,"<",shift@ARGV);#REF MAY 25
$CHR_TEMP = "";
while(<$in>){
	chomp;
	if(substr($_,0,1) eq ">"){
		if($CHR_TEMP ne ""){
			$REF{$chr} = $CHR_TEMP;
			$CHR_TEMP = "";
		}
		@c = split(/\s+/,$_); #in case of blank in chr line;
		$chr = substr($c[0],1);
		next;
	}
	$CHR_TEMP .= $_;
}
if($CHR_TEMP ne ""){
	$REF{$chr} = $CHR_TEMP;
	$CHR_TEMP = "";
}
open(OO,">head");
foreach my $chr (keys %REF){
	print OO '@SQ',"\t","SN:$chr\tLN:",length($REF{$chr}),"\n";
}

#open($in,"<newtemp");
$name_temp = "";
while(<STDIN>){
	chomp;
	$line = $_;
	my @m = split(/\t/);
	if($name_temp ne $m[0]){
		$temp1 = $m[0];
		action();
		%hash=();

		$name_temp = $temp1;
	}
	my @m = split(/\t/,$line);
	if($m[$#m] eq "tag"){
		do_sam();
	}
	else{
		do_gap();
	}
}
action();





sub do_gap{
	my @m = split(/\t/,$line);
	$key = join(":",$m[2],$m[3],$m[5]);
	@t = split(/:/,$m[$#m]);
	$hash{$m[0]}{$key}[0] = $t[2];
	$hash{$m[0]}{$key}[1] = $m[9];
	$hash{$m[0]}{$key}[2] = $m[10];
	@k = split(/M|N/,$m[5]);
	$cano_flag = 1;
	$s = $m[3];

	for $i (1 .. ($#k)/2){
		$s+=$k[$i*2-2];
		$e = $s + $k[$i*2-1];
		$cano_flag *= $cano{$m[2]}{$s}{$e};
		$s+=$k[$i*2-1];
	}
	$hash{$m[0]}{$key}[3] = $cano_flag;
	$hash{$m[0]}{$key}[4] = $m[1];
}


sub do_sam{
	my @m = split(/\t/, $line);
	$key = join(":",$m[2],$m[3],$m[4]);#chr pos cigar
	if($hash{$m[0]}{$key}[0] eq ""){$hash{$m[0]}{$key}[0] = $m[5];}#score
	else{$hash{$m[0]}{$key}[0] = $hash{$m[0]}{$key}[0] > $m[5] ? $hash{$m[0]}{$key}[0]:$m[5];}
	$hash{$m[0]}{$key}[1] = $m[6];# seq
	$hash{$m[0]}{$key}[2] = $m[7];# qua
	$cano_flag = 1;
	@k = split(/M|N/,$m[4]);
	$s = $m[3];## need change after gapped reconpile
	for $i (1 .. ($#k)/2){
		$s+=$k[$i*2-2];
		$e = $s + $k[$i*2-1];
		$cano_flag *= $cano{$m[2]}{$s}{$e};
		$s+=$k[$i*2-1];
	}
	$hash{$m[0]}{$key}[3] = $cano_flag;# 0 1 2 ..
	if($m[1] eq "+"){$hash{$m[0]}{$key}[4] = 0;}# + -
	else{$hash{$m[0]}{$key}[4] = 16;}

}

sub action{
	foreach $name (keys %hash){
		#print $name,"\n";
#		print scalar keys %{$hash{$name}},"\n";
		if(scalar keys %{$hash{$name}} > 1){
			$flag1 = 0;
			$flag2 = 0;
			$flag0 = 0;
			foreach $key (keys %{$hash{$name}}){
				if($hash{$name}{$key}[3] == 1){
					$flag1 = 1;
				}
				if($hash{$name}{$key}[3] >= 2){
					$flag2 = 1;
				}
				if($hash{$name}{$key}[3] == 0){
					$flag0 = 1;
				}

			}
#			print $flag0,"\t",$flag1,"\t",$flag2,"\n";
			if( ($flag1 == 1 && ($flag2 == 1 || $flag0 == 1))){
				foreach $key (keys %{$hash{$name}}){
					if($hash{$name}{$key}[3] == 0 || $hash{$name}{$key}[3] >= 2){
						delete $hash{$name}{$key};
					}
				}
			}
			if($flag2 == 1 && $flag0 == 1 && $flag1 == 0){
				foreach $key (keys %{$hash{$name}}){
					if($hash{$name}{$key}[3] == 0){
						delete $hash{$name}{$key};
					}
				}
			}
#			print scalar keys %{$hash{$name}},"\n";
			if(scalar keys %{$hash{$name}} != 1){
				@rank = sort {$hash{$name}{$b}[0] <=> $hash{$name}{$a}[0]} keys %{$hash{$name}};
				if($hash{$name}{$rank[0]}[0] < 0.5){
					for($i = 0; $i < scalar @rank; $i++){#                 @{$final{$name}{$rank[$i]}} = @{$hash{$name}{$rank[$i]}}
						delete $hash{$name}{$rank[$i]};
					}
					next;
				}
				$limit = $hash{$name}{$rank[0]}[0] * 0.9;
				#print $limit,"\n";
				my $N = scalar @rank;
				for($i = 1;$i < scalar @rank ; $i++){
					if($hash{$name}{$rank[$i]}[0] < $limit){$N = $i;last;}
				}
				for($i = $N; $i < scalar @rank; $i++){#			@{$final{$name}{$rank[$i]}} = @{$hash{$name}{$rank[$i]}}
					delete $hash{$name}{$rank[$i]};
				}
				if($N > 1){
					my @mis = ();
					for($i = 0; $i < $N; $i++){
						my $mis_number = yayun($rank[$i], $hash{$name}{$rank[$i]}[1]);
						push @mis, $mis_number;  ## key seq
						$ALL_MIS{$name}{$rank[$i]} = $mis_number;

					}
					for($i = 0; $i < $N; $i++){
						if($mis[$i] != min(@mis) && $mis[$i] > 1){
							delete $hash{$name}{$rank[$i]};
						}
					}
				}
				else{
					my $mis_number = yayun($rank[0], $hash{$name}{$rank[0]}[1]);
					$ALL_MIS{$name}{$rank[0]} = $mis_number;
				}

						
			}
		}
#		print scalar keys %{$hash{$name}} ,"\n";
		if(scalar keys %{$hash{$name}} == 1){
			foreach $key (keys %{$hash{$name}}){
				if(($hash{$name}{$key}[3] >= 2 || $hash{$name}{$key}[3] == 0) && $hash{$name}{$key}[0] < 0.4){
					delete $hash{$name}{$key};
					#print "ss\t$key\n";
				}
				else{
					@s = split(/:/, $key);
					@t = split(/M|N/,$s[2]);
					for $i (1 .. ($#t)/2){
						if($t[$i*2-1] > 50000 && $hash{$name}{$key}[0] < 0.4 || $t[$i*2-1] > 8000 && $hash{$name}{$key}[0] < 0.1){
							delete $hash{$name}{$key};
							#print "pp\t$key\n";
							last;
						}
					}
				}
			}
		}
		#print scalar keys %{$hash{$name}} ,"\n";
		foreach $key (keys %{$hash{$name}}){
			@t = split(/:/,$key);
			if(exists $ALL_MIS{$name}{$key}){
				$MM = $ALL_MIS{$name}{$key};
			}
			else{
				$MM = yayun($key, $hash{$name}{$key}[1]);
			}

			print $name,"\t", $hash{$name}{$key}[4],"\t",$t[0],"\t", $t[1], "\t", $MM ,"\t",$t[2], "\t",$hash{$name}{$key}[3],"\t",$hash{$name}{$key}[1],"\t",$hash{$name}{$key}[2], "\tAS:i:", $hash{$name}{$key}[0],"\n";
		}
	}
}

sub yayun{
	my $LINE = @_[0];
	my $seq = @_[1];
	my @t = split(/:/,$LINE);
	my @k = split(/M|N/,$t[2]);
	my $s = $t[1] - 1;
	my $MAP = "";
	for my $i (1 .. ($#k)/2+1){
		$MAP .= substr($REF{$t[0]}, $s, $k[$i*2-2]);
		$s+=$k[$i*2-2];
		$s+=$k[$i*2-1];
	}
	$MAP =~ tr/a-z/A-Z/;
	my $cout = 0;
	for my $i (0 .. length($seq)-1){
		if(substr($seq,$i,1) ne substr($MAP,$i,1)){
			$cout += 1;
		}
	}
	return $cout


}
if($pair == 1){
system("cat temp_file.sam");###MAY 31
}


#open($in,"<",shift@ARGV);#GAP
