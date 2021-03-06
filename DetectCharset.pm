package DetectCharset;

use strict;
use warnings;

use utf8;

use lib qw(../Botox);
use Botox qw(new);
use Encode qw(decode);
use Fcntl qw(:DEFAULT :flock);
use Carp;

our $VERSION = 0.7.4;

=for nb
Два необязательных параметра, можно использовать для настройки точности определения
и глубины поиска по файлам

@param {scalar} min_file_size
@param {scalar} min_diff

=cut

# переменные экземпляра
our $object_prototype = { min_diff => 1.5 , min_file_size => 2_000_000 };

# приватные переменные
my $do_detect;
my $pair_size = 2;
my @charset = qw(UTF-8 CP1251 KOI8-R ISO-8859-5 CP866);

# Таблица соответствий для поиска русского языка
my %sym_table;

my $symb_filename = 'Russian.cp'; # имя файла таблицы символов

croak "$! $symb_filename" unless (-f $symb_filename);
open (my $fh, "<:utf8", $symb_filename) or croak "$! $symb_filename";
while (<$fh>) {
	$sym_table{$1} = $2 if /(\w+)\s(\d+)/;
}
close $fh;


sub detect_text {

	my ( $self, $text ) = @_ ;

	$text =~ tr/\r\n//;

	my @res;
	my $all_res = &$do_detect($text);

	@res[0..1] = sort { $all_res->{$b} <=> $all_res->{$a} }
						grep $all_res->{$_}, keys %{$all_res};

=for nb

Возвращаем -1 если даже первый меньше единицы - вариант когда распозновать нечего
возвращаем 0 в случае если распознование неуверенное - лидер не выше второго в 1.5 раза

возвращаем имя кодировки если мы смогли понять что это такое в скалярном контексте или массив на два элемента - имя кодировки и баллы в списковом

=cut

	return unless defined wantarray; # don't bother doing more
	return -1 if( !defined $res[0] || $all_res->{$res[0]} < 1 );
	if( !defined $res[1] || $all_res->{$res[0]} > $all_res->{$res[1]}*$self->min_diff ){
		return wantarray ? ( $res[0], $all_res->{$res[0]} ) : $res[0] }

	return 0;
}

sub detect_file {

	my ( $self, $filename )  = @_ ;
	my ($ret, %rezalt);

	croak "$! $filename" unless ( -f $filename );
	open ( my $fh, "<", $filename ) or croak "$! $filename";
	flock($fh, 1) or croak "$! $filename";
	while ( <$fh> ) {

		my ( $kode, $ball ) = $self->detect_text( $_ );
		
		$kode =~ /^[a-z]/i ? ( $rezalt{$kode} += $ball ) : next ;

	  if ( keys %rezalt == 1 && $rezalt{$kode} > $self->min_file_size  )
		{
			close $fh;
			return $kode;
		}

		if ( keys %rezalt > 1 ) {
			my ( $leader, $second ) = sort { $rezalt{$b} <=> $rezalt{$a} }
                keys %rezalt;
			if ( $rezalt{$leader} > $rezalt{$second}*$self->min_diff ){
				$ret = $leader;
			}
			$ret = 0;
		}
	}

	close $fh;
	return defined $ret ? $ret : -1;

}

$do_detect = sub {
	my ( $result, $text ) = ( undef, @_ );
		foreach my $char (@charset) {
			my $mark;
			my $string = decode( $char, $text );
			for my $chank ( split ( /\W+/ , $string ) ){
			
				next if ( length( $chank ) < 2 );
				
				for ( my ($i, $len) = ( 0, length($chank)-$pair_size ); $i <= $len; $i++ ){
					$mark += $sym_table{substr ($chank, $i, $pair_size)} || 0;
				}

			}
		$result->{$char} = $mark ;
		}
	return $result;
};


1;

__END__

=encoding utf-8


=pod


=head1 NAME

DetectCharset - auto detector for Russion text.

=head1 VERSION

B<$VERSION 0.7.4>

=head1 SYNOPSIS

DetectCharset - auto detector for Russion text in UTF-8 CP1251 KOI8-R ISO-8859-5 CP866 encoding

	use DetectCharset;
	my $obj = new DetectCharset;
	# in $unknown_text we are have somthing in Russin 
	my $rez = $obj->detect_text($unknown_text);
	# more sophisticated with $files as full filepath
	my $rez2 = $obj->detect_file($files);

=head1 DESCRIPTION

Модуль призван обеспечить облегчение вычисления кодировки текста или файла

Используется следующим образом:

	use DetectCharset;
	my $obj = new DetectCharset;
	...
	# in $unknown_text we are have somthing in Russin 
	my $rez = $obj->detect_text($unknown_text);
	...
	# more sophisticated with $files as full filepath
	my $rez2 = $obj->detect_file($files);
	
При создании объекта возможно присваить 2 свойства 

	min_file_size {def 2_000_000} - для настройки минимальной глубины прохода по файлу значение задается в B<баллах>, используейте более 2_000_000 в случае возникновения ошибок при распозновании или менее, если файл невелик.
	min_diff {def 1.5} - для настройки минимальной разницы в баллах между разными интерпретациями кодировок, используйте более 1.5 в случае нечеткого распознования или менее 1.5 в случае нулевого возврата
	
Реализовано 2 метода:

1.) detect_text - для работы с текстами

	my $rez = $obj->detect_text($unknown_text);

Можно использовать в списковом контексте, в этом случае второе значение - набранные баллы. Реализовано в основном для использования в обработке файлов


2.) detect_file - для работы с файлами

	my $rez2 = $obj->detect_file($files);
	
Этот метод предпочтительнее при работе с файлами, т.к. теоретически не будет просматривать ВЕСЬ файл.

Оба метода возвращают в скалярном значении имя кодировки из набора 

	UTF-8 CP1251 KOI8-R ISO-8859-5 CP866
	
для дальнейшего использования с Encode::from_to() или иными целями

или

-1 - в случае невозможности опознать кодировку - например нет русских слов в тексте

 0 - в случае невозможности опознать кодировку, однако в тексте есть русские слова или что-то их напоминающее

=head1 AUTOR	

Meettya <L<meettya@gmail.com>>

=head1 BUGS


=head1 SEE ALSO

Lingua::DetectCharset

=head1 COPYRIGHT

B<Moscow>, snow 2009

=cut