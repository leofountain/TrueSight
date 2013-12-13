#!/usr/bin/perl
#
use POSIX;
use FindBin qw($Bin);
use Parallel::ForkManager;


$name = "temp";
$file_name = "$name.un";
$segment_length = shift@ARGV;
$P = shift@ARGV;
$bwt = shift@ARGV;
$IF_PAIR = shift@ARGV;

if(-d "temp_data"){
	system("rm -r temp_data; mkdir temp_data");
}
else{
	mkdir("temp_data");
}

$T=0;

$partition = int(200000000/100);  
@temp = ();
$N=0;
$T=0;
if($IF_PAIR == 1){
	open($in,"<$name.un.fq");
	while(<$in>){
		push @temp,$_;
		$N++;
		if($N == $partition*4){
			$T++;
			open($out,">","temp_data/$file_name.$T.fq");
			print $out @temp;
			@temp = ();
			$N = 0;
		}
	}
}
if($IF_PAIR == 2){
	open($in,"<temp1.un.fq");
	open($ALL_UNMAP,">temp.un.fq");
	while(<$in>){
		chomp;
		if ( /^\s*$/ ) {
			next;
		}
		print $ALL_UNMAP $_,"\n";
		push @temp,"$_\n";
		$N++;
		if($N == $partition*4){
			$T++;
			open($out,">","temp_data/$file_name.$T.fq");
			print $out @temp;
			@temp = ();
			$N = 0;
		}
	}
	open($in,"<temp2.un.fq");
	while(<$in>){
		chomp;
		if ( /^\s*$/ ) {
			next;
		}
		print $ALL_UNMAP $_,"\n";
		push @temp,"$_\n";
		$N++;
		if($N == $partition*4){
			$T++;
			open($out,">","temp_data/$file_name.$T.fq");
			print $out @temp;
			@temp = ();             
			$N = 0;                                         
		}
	}
}
if(scalar @temp > int($partition*2/3)*4){
	$T++;
	open($out,">","temp_data/$file_name.$T.fq");
	print $out @temp;
	@temp = ();
}
else{
	if($T == 0){
		$T++;
		open($out,">","temp_data/$file_name.$T.fq");
	}
	print $out @temp;
	@temp = ();
}






open(F,"<chr_num");
$CHR_NUM=<F>;
chomp($CHR_NUM);
if($CHR_NUM > 100){
	$multi_chr_flag = 1;
}
else{
	$multi_chr_flag = 0;
}

%all_chr=();

#$multi_chr_flag = 1; ####### Feb 25
@register_file=();

$pm=new Parallel::ForkManager($P);
for (my $i=1;$i<=$T;$i++){
	my $pid = $pm->start and next;
	$name = "temp_data/$file_name.$i.fq";
	$name_sp = "temp_data/$file_name.$i.fq_sp";
	system("$Bin/Gap_splitReads $name $segment_length > $name_sp");
	$pm->finish;
}
$pm->wait_all_children;



#my $pm = new Parallel::ForkManager(1);
$i = 1;
$name = "temp_data/$file_name.$i.fq";
$name_sp = "temp_data/$file_name.$i.fq_sp";
system("$Bin/bowtie --suppress 6 --quiet -k 50 -v 2 -p $P $bwt  $name_sp  $name_sp.bwt; rm $name_sp");

for($i = 2; $i<=$T; $i++){
	my $pm = new Parallel::ForkManager(2);
	for($jj = 0; $jj <=1 ; $jj++){
		my $pid = $pm->start and next;
		if($jj == 0){
			my $name = "temp_data/$file_name.$i.fq";
			my $name_sp = "temp_data/$file_name.$i.fq_sp";
			system("$Bin/bowtie --suppress 6 --quiet -k 50 -v 2 -p $P $bwt  $name_sp  $name_sp.bwt; rm $name_sp");
		}
		if($jj == 1){
			my $I = $i-1;
			my $name_sp_2 = "temp_data/$file_name.$I.fq_sp";
			my $name_2 = "temp_data/$file_name.$I.fq";

			if($multi_chr_flag == 0){
				dist_by_chr ("$name_sp_2.bwt",$name_2);
			}
		}
		$pm->finish;
	}
	$pm->wait_all_children;
}
$i = $T;
my $name = "temp_data/$file_name.$i.fq";
my $name_sp = "temp_data/$file_name.$i.fq_sp";
if($multi_chr_flag == 0){
	dist_by_chr ("$name_sp.bwt",$name);
}
#$pm->wait_all_children;

if($multi_chr_flag == 1){
	for($i = 1; $i<=$T; $i++){
		push @register_file, "temp_data/$file_name.$i";
		system("mv temp_data/$file_name.$i.fq_sp.bwt temp_data/$file_name.$i.bwt");
	}
	open($out,">temp_data/list");
	print $out join("\n",@register_file);
	exit;
}


$partition_temp = 0;
$partition_temp_id = 1;
#my $pm = new Parallel::ForkManager(1);
foreach my $chr (keys %all_chr){
	#my $pid = $pm->start and next;
	dist_each_chr ($chr);
	#$pm->finish;
}
#$pm->wait_all_children;


if($partition_temp != 0){
	push @register_file, "temp_data/new.$partition_temp_id";
}

open($out,">temp_data/list");
print $out join("\n",@register_file);


sub dist_by_chr{
	my $BWT = @_[0];
	my $FQ = @_[1];
	my %CHR=();
	my %all=();
	my %tag=();
	my %B=();
	my %C=();
	open $in,"<$BWT";
	while(<$in>){
		my @m =split(/\s+/);
		$CHR{substr($m[0],0,-2)}{$m[2]}=1;
		$tag{$m[2]}=1;
	}
	if(scalar keys %tag < 100){# in case of limit file handles 
		foreach my $chr (keys %tag){
			$all_chr{$chr}=1;
			open $B{$chr},">>temp_data/$chr.bwt" or die "Can't open temp_data/$chr.bwt for output\n";
			open $C{$chr},">>temp_data/$chr.fq";
		}

		open $in,"<$BWT";# bwt sp file
		while(<$in>){
			my @m =split(/\s+/);
			my $name = substr($m[0],0,-2);
			print {$B{$m[2]}} $_;

		}
		open $in,"<$FQ"; # fq file
		my @temp=();
		my %L=();
		while(<$in>){
			chomp;
			$L{1}=$_;
			if(length($L{1}) == 0){
				last;##blank line
			}
			push @temp,$L{1};
			for $i (2 .. 4){
				$L{$i} = <$in>;
				chomp($L{$i});
				push @temp,$L{$i};
			}
			chomp($L{1});
			my $name = substr($L{1},1);
			foreach $chr (keys %{$CHR{$name}}){
				print {$C{$chr}} join("\n",@temp),"\n";
			}
			@temp=();
		}
		system("rm $BWT $FQ");
	}
	else{
		$multi_chr_flag = 1;
	}
}

sub dist_each_chr{
	my $chr = @_[0];
	open(my $in, "<temp_data/$chr.fq");
	while(<$in>){};
	if($. > $partition*4){
		open(my $in, "<temp_data/$chr.fq");
		my $T=1;
		my @temp = ();
		my $N = 0;
		my %out_bwt=();
		my %name_hash=();
		open($out,">","temp_data/$chr.$T.fq");
		open($out_bwt{$T},">temp_data/$chr.$T.bwt");
		push @register_file, "temp_data/$chr.$T";
		while(<$in>){
			if($N == $partition*4*3){ 
				$T++;                                   
				open($out,">","temp_data/$chr.$T.fq");
				open($out_bwt{$T},">temp_data/$chr.$T.bwt");
				push @register_file, "temp_data/$chr.$T";
				$N = 0;                                                                                                 
			}
			print $out $_;
			$N++;
			if($N%4 == 1){
				chomp;
				my $name = substr($_,1);
				$name_hash{$name} = $T;
			}
		}
		close $in;
		unlink("temp_data/$chr.fq");
		open(my $in, "<temp_data/$chr.bwt");
		while(<$in>){
			@m = split(/\s+/);
			my $name = substr($m[0],0,-2);
			print {$out_bwt{$name_hash{$name}}} $_;
		}
		unlink("temp_data/$chr.bwt");
	}
	else{
		if($.+ $partition_temp  <= $partition*4){
			system("cat temp_data/$chr.fq >> temp_data/new.$partition_temp_id.fq");
			system("cat temp_data/$chr.bwt >> temp_data/new.$partition_temp_id.bwt");
			$partition_temp += $.;
		}
		else{
			$partition_temp = 0;
			push @register_file, "temp_data/new.$partition_temp_id";
			$partition_temp_id++;
			$partition_temp += $.;
			system("cat temp_data/$chr.fq >> temp_data/new.$partition_temp_id.fq");
			system("cat temp_data/$chr.bwt >> temp_data/new.$partition_temp_id.bwt");
		}
		unlink("temp_data/$chr.fq");
		unlink("temp_data/$chr.bwt");
	}

}





