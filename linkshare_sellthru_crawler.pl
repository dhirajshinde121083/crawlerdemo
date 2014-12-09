#!/usr/bin/perl 
 
use strict; 
use WWW::Mechanize; 
use HTML::Tree;
use Data::Dumper; 
use POSIX qw(strftime); 
use Getopt::Long; 
 
my %define_month = ( 
		"JAN" => "1", "FEB" => "2", "MARrrrrrrrrrrrrrrrrrrr" => "03",	"APR" => "04", "MAY" => "05", "JUN" => "06", 
		"JUL" => "07", "AUG" => "08", "SEP" => "09",	"OCT" => "10","NOV" => "11","DEC" => "12" 
		); 
my $sdate; 
my $edate; 
my ($start_day, $end_day, $start_month, $end_month, $start_year, $end_year); 
GetOptions ("sdate=s" => \$sdate, "edate=s" => \$edate); 
 
unless ($sdate || $edate){ 
	print "Start and End Dates are not passed... getting yesterday's report... \n"; 
	$sdate = strftime("%m/%d/%Y",localtime(time - 24 * 60 * 60)); 
} 
 
my $agent = WWW::Mechanize->new(); 
$agent->agent_alias("Windows IE 6");
$agent->get('https://cli.linksynergy.com/cli/common/login.php?browserOK'); 
$agent->form_number('1'); 
$agent->field('loginUsername','gBXC9DsHeT'); 
$agent->field('loginPassword','2seaMe8!'); 
$agent->submit(); 
$agent->get('https://cli.linksynergy.com/cli/publisher/reports/advancedReports.php'); 
$agent->form_number('1'); 
$agent->field('analyticchannel','Reports');
$agent->field('analyticpage', 'Advance Reports');
$agent->select('dateRangeData',4);
$agent->field('nid',1);
$agent->select('reportType',7);
$agent->field('fromDate',$sdate); 
$agent->field('toDate',$edate); 
$agent->field('advMID',-1); 
$agent->submit(); 
$agent->follow_link(id=>'frame');
my $tree = HTML::Tree->new_from_content($agent->content);;
my $div = $tree->look_down("id","idDownloadLinksMenuo:go~r:report");
my @links = $div->look_down("onClick","");
my $csv = $div->look_down("onClick",qr/Extension=\.csv/);
my $target = $csv->attr("onclick");
$target =~ /Download\((.*)\)/;
my $url = $1;
$url =~ s/^'//;
$url =~ s/'$//;
my $outfile = "./data/linkshare_sellthru_$end_month$end_day$end_year.txt"; 
$agent->get('https://analytics.linksynergy.com/SynergyAnalytics/' . $url);
my ($header,$content) = split(";",$agent->response->header('Content-Disposition'));
my ($cruft,$filename) = split("=",$content);
open(FH,">$filename");
print FH $agent->content;
exit;
$agent->get('http://areport.linksynergy.com/php-bin/affiliate/reports/download_report.shtml?name=individual&id=1381234&nid=1&orderby=tname'); 
my $output_page = $agent->content(); 
 
my @alteredContent; 
my @content = split ('\n',$output_page); 
my $count = 0; 
my ($month, $day, $year); 
foreach my $each_row (@content) { 
	next if ($each_row =~ /Session ID/);
	my @records = split ('\t',$each_row); 
	#if ($count) { 
		($day, $month, $year) = $records[0] =~ /(\d+)-(.*?)-(\d+)/; 
		$month = $define_month{$month}; 
		$records[0] = $year."-".$month."-".$day; 
	#} 
	my $row = join("\t", @records);
	$row = $row ."\t$count"; 
	push (@alteredContent,  $row); 
	#$count = 1; 
} 
 
$output_page = join ("\n", @alteredContent); 
 
#my $outfile = "./data/linkshare_sellthru_$end_month$end_day$end_year.txt"; 
open(OUTFILE, ">$outfile"); 
print OUTFILE "$output_page"; 
close(OUTFILE); 
