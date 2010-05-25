#!/opt/local/bin/perl -w

#use 5.12.0; # to enable all feature && strict pragma
use strict;
use lib qw(../Botox);
use Encode qw(encode decode);

use Test::More tests => 8; # 4 codetest

use_ok( 'DetectCharset', qw(detect_text detect_file) );
can_ok( 'DetectCharset', qw(detect_text detect_file) );


my $test_text = 'Съешь еще этих мягких французских булок, да выпей чаю.'; 

my %rec_ok = map { $_, encode ( $_, decode("UTF-8", $test_text) ) } 
						qw(UTF-8 CP1251 KOI8-R ISO-8859-5 CP866);

my $ch_d = new DetectCharset (qw(min_diff min_file_size));

$ch_d->set_multi( min_diff => 2.5, min_file_size => 4_000_000 );

print "\nTest encoding recognition:\n";
ok ( $ch_d->detect_text($rec_ok{$_}) eq $_ , "$_ recognized" ) for keys %rec_ok;
print "\nTest file encoding recognition:\n";
ok ( $ch_d->detect_file('DetectCharset.pm') eq 'UTF-8', "detect_file work" );

my $test_param = 1;
TODO: {
        local $TODO = "module not finished" if $test_param == 1;

}
