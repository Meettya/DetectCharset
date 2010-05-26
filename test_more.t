#!/opt/local/bin/perl -w

#use 5.12.0; # to enable all feature && strict pragma
use strict;

use Encode qw(encode decode);

use Test::More tests => 8; # 4 codetest

use_ok( 'DetectCharset', qw(detect_text detect_file) );
can_ok( 'DetectCharset', qw(detect_text detect_file) );


my $test_text = 'Съешь еще этих мягких французских булок, да выпей чаю.'; 

my %rec_ok = map { $_, encode ( $_, decode("UTF-8", $test_text) ) } 
						qw(UTF-8 CP1251 KOI8-R ISO-8859-5 CP866);


my $ch_d = new DetectCharset;

print $ch_d->min_diff."\n";

$ch_d->min_diff(4);

$ch_d->set_min_diff(3);

print $ch_d->min_diff."\n";


print $ch_d->min_file_size."\n";

$ch_d->min_file_size(4_000_000);

print $ch_d->min_file_size."\n";

print $ch_d->max;
 

print "\nTest encoding recognition:\n";
ok ( $ch_d->detect_text($rec_ok{$_}) eq $_ , "$_ recognized" ) for keys %rec_ok;
print "\nTest file encoding recognition:\n";
ok ( $ch_d->detect_file('DetectCharset.pm') eq 'UTF-8', "detect_file work" );

my $test_param = 1;
TODO: {
        local $TODO = "module not finished" if $test_param == 1;

}
