#!/usr/bin/perl 

use strict;
use JSON;
use Config::Tiny;
use WWW::Mechanize;
use Data::Dumper;
use POSIX qw(strftime);
use Getopt::Long;

my $sdate;
my $edate;

GetOptions( "sdate=s" => \$sdate, "edate=s" => \$edate );

unless ( $sdate || $edate ) {
	print "Start and End Dates are not passed.\n";
	exit;
}

my $config               = Config::Tiny->read('/u/conf/apps.conf');
my $apiKey               =
"1698ab951b76153b6b3ddc26fa4b00280a4823dbc3ca62b6ca78bcbc42e6a4b7";
my $transactionReportUrl =
"http://api.pepperjamnetwork.com/20120402/"."publisher/report/sku-details?apiKey=$apiKey&format=json&startDate=2013-12-01&endDate=2013-12-31&website=all";

#$transactionReportUrl =~ s/\$apikey/$apiKey/g;

my $agent    = WWW::Mechanize->new();
my $response = $agent->get($transactionReportUrl);

$response = from_json( $response->decoded_content() );
if ( $response->{meta}->{status}->{message} eq 'OK' ) {
	open( OUTFILE, ">testdata.txt" );
	foreach my $row ( @{ $response->{data} } ) {
		my %eachRow    = %{$row};
		my $eachRecord = join(
			"\t",
			@eachRow{
				qw/transaction_id program_id creative_id order_id
				transaction_type creative_type sale_amount commission date
				status  advertiser_id advertiser_name sid_name sub_type sku
				quantity item_name /
				}
		);
		print "$eachRecord\n";
		print OUTFILE "$eachRecord\n";
	}
	close(OUTFILE);
}
