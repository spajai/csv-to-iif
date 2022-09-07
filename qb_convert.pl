#!/usr/local/bin/perl

use strict;
use warnings;
use Date::Format;
use Text::CSV::Encoded;
use Text::ParseWords;

#####

my $filename = $ARGV[0] || "sample-data.csv";

my @records;
open ( my $file, "<", $filename ) or die "Can't open file $filename: $!";
while ( my $line = <$file> ) {
        #remove leading and trailing whitespace
        chomp $line;
        #remove the trailing newline
        $line =~ s/\r//g;
        my @fields = parse_line(q{,}, 0, $line);
        foreach my $field (@fields) {
                $field=~ s/^\s+|\s+$//g;
        }
        push( @records, \@fields );
}
close $file;

#####

my $timestamp = time2str( "%A %m %B %Y %r ", time() );

local $\ = "\n";
open ( $file, ">", "qbiifout.iif" ) or die "Can't open output file: $!";
my $csv = Text::CSV::Encoded->new ({ encoding_in  => "utf-8", encoding_out => "utf-8", quote_space => 0,quote_char  => undef });

my @fields = qw/!DATE !AMOUNT !STAR !BLANK !LINEITEM/;
printf $file "!ACCNT\tNAME\tACCNTTYPE\tDESC\n";
printf $file "ACCNT\tChargeback\tEXP\tWF CASH ACCOUNT DEBIT OFFSET\n";
printf $file "ACCNT\tSubscription and POD Revenue CC\tINC\tWF CASH ACCOUNT CREDIT OFFSET\n";
printf $file "\n";
printf $file "!TRNS\tTRNSID\tTRNSTYPE\tDATE\tACCNT\tNAME\tAMOUNT\tDOCNUM\tCLEAR\n";
printf $file "!SPL\tSPLID\tTRNSTYPE\tDATE\tACCNT\tNAME\tAMOUNT\tDOCNUM\tCLEAR\n";
printf $file "!ENDTRNS\n";

foreach my $item ( @records ) {
        my %line;
        $line{'!DATE'}     = $item->[0];
        if(length($line{'!DATE'}) == 0) {
                $line{'!DATE'} = "";
        }

        $line{'!AMOUNT'}   = $item->[1];
        if(length($line{'!AMOUNT'}) == 1) {
                $line{'!AMOUNT'} = "0";
        }

        $line{'!LINEITEM'} = $item->[4];
        if(length($line{'!LINEITEM'}) == 1) {
                $line{'!LINEITEM'} = "0";
        }

        my $oppo           = -1 * $item->[1]; #will prevent -0.00

        if ( $item->[1] > 0 ) {
                $csv->print( $file,  [ "TRNS\t\tDEPOSIT\t$line{'!DATE'}\tMAIN CHECKING\t$line{'!LINEITEM'}\t$line{'!AMOUNT'}\tY" ]  );
                $csv->print( $file,  [ "SPL\t\tDEPOSIT\t$line{'!DATE'}\tSubscription and POD Revenue CC\t\t$oppo\tY" ]  );
                $csv->print( $file,  [ "ENDTRNS D" ] );
        } else   {
                $csv->print( $file,  [ "TRNS\t\tCHECK\t$line{'!DATE'}\tMAIN CHECKING\t$line{'!LINEITEM'}\t$line{'!AMOUNT'}\tY" ]  );
                $csv->print( $file,  [ "SPL\t\tCHECK\t$line{'!DATE'}\tChargeback\t\t$oppo\tY" ]  );
                $csv->print( $file,  [ "ENDTRNS C" ] );
        }
}

close $file;