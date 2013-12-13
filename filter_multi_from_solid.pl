#!/usr/bin/perl


open($in,"<",shift@ARGV);
while(<$in>){
	@m = split(/\s+/);
	$name{$m[0]} = 1;
}

open($in,"<",shift@ARGV);
while(<$in>){
	if(/>/){
		$SAM = <$in>;
		@m = split(/\s+/,$SAM);
		if($name{$m[0]} == 1){
			while(<$in>){
				if(/>/){
					last;
				}
			}
		}
		else{
			print ">\n$SAM";
			while(<$in>){
				print;
				if(/>/){
                                        last;
                                }
			}

		
		}
	}
}
