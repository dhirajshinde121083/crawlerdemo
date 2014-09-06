#!/usr/bin/perl
use strict;
use warnings;
use JSON;
use WWW::Mechanize;
use Data::Dumper;
use POSIX qw(strftime);
use Getopt::Long;

my $apikey =
"1698ab951b76153b6b3ddc26fa4b00280a4823dbc3ca62b6ca78bcbc42e6a4b7";

my $url =
"http://api.pepperjamnetwork.com/20120402/"."publisher/report/sku-details?apiKey=$apikey&format=json&startDate=2013-12-01&endDate=2013-12-31&website=all";

my $agent = WWW::Mechanize->new();
my $response = $agent->get($url);
print Dumper from_json($response->decoded_content());
