#!/usr/bin/perl


open($in,"<",shift@ARGV);
while(<$in>){
	@m = split(/\s+/);
	$name{$m[0]} = 1;
}

#open($in,"<",shift@ARGV);
while(<STDIN>){
        @m = split(/\s+/);
        if($name{$m[0]} == 1){
		next;
	}
	else{
		print ;
	}
}
