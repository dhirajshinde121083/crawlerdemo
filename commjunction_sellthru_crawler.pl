#!/usr/bin/perl 
 
use strict; 
use WWW::Mechanize; 
use Data::Dumper; 
use POSIX qw(strftime); 
use Getopt::Long; 
 
#these are the copies from brandifyyyyy
my $sdate; 
my $edate; 
my ($start_day, $end_day, $start_month, $end_month, $start_year, $end_year); 
GetOptions ("sdate=s" => \$sdate, "edate=s" => \$edate); 
my $status = 1; 
 
unless ($sdate || $edate){ 
	my $date = strftime("%Y,%m",localtime()); 
	my ($year,$month) = split (",",$date); 
	$start_day = 1;
	$month--; 
	my %define_end_day = ( 
			"1" => "31", "2" => "28", "3" => "31", 	"4" => "30", "5" => "31", "6" => "30", 
			"7" => "31", "8" => "31", "9" => "30",	"10" => "31","11" => "30","12" => "31" 
			); 
	if ($month == 0) { 
		$start_year =  $end_year = $year - 1; 
		$start_month = $end_month = 11; 
		$end_day = $define_end_day{$start_month+1}; 
	} 
	else{ 
		$start_year = $end_year = $year; 
		$start_month = $end_month = $month; 
		$end_day = $define_end_day{$start_month}; 
		$end_day = 29 if ($start_year % 4 == 0 && $start_month == 1); 
	} 
	$status = 0; 
	print "Start and End Dates are not passed... getting last month's report... $start_year-$start_month-01  $end_year-$end_month-$end_day \n";
} 
else{ 
	($start_year, $start_month, $start_day) = split ("-",$sdate); 
	($end_year, $end_month, $end_day) = split ("-",$edate); 
#	$start_month--; 
#	$end_month--; 
	$status = 1; 
} 

my $agent = WWW::Mechanize->new(); 
$agent->get("https://www.cj.com"); 
$agent->form_number('1'); 
#$agent->form_name('loginForm'); 
$agent->field('uname','jscarbrough@where2getit.com'); 
$agent->field('pw','2seaMe!'); 
$agent->submit(); 

#Comm junction is dumb they use month-1 to represent the month in thier forms
my $url_start_month = $start_month -1;
my $url_end_month =  $end_month - 1;

my $prefix_action_url = "https://members.cj.com";
my $report_url = "https://members.cj.com/member/1519833/publisher/report/transaction.do?";
$report_url .= "startday=$start_day&startmonth=$url_start_month&startyear=$start_year&endday=$end_day&endmonth=$url_end_month&endyear=$end_year&";
$report_url .= "what=commDetail&filterby=-1&sortKey=advertiser&sortOrder=ASC&period=range&recsPerPage=25&startRow=";

die $report_url;
my $start_page = 0;


$agent->get($report_url.$start_page);
my $output_page = $agent->content(); 
$output_page =~ s/\n//g;
my ($temp_content,@page_numbers);
($temp_content) = $output_page =~ /<select name\=\"startRow\"(.*?)<\/select>/i;
$temp_content =~ s/\n//g;
(@page_numbers) = $temp_content =~ /<option value=\"(.*?)\">/ig;
shift @page_numbers;
my $file_content = '';

#"Original ID\tStatus\tAction Type\tEvent Date\tAmount\tTotal Order Discount\tCommission\tTotal Corrected\tID\tSale Amount\tOrder Discount\tCommission\tPosting Date\tDescription\tSKU\tAmount\tItem Discount\tQuantity\tPosting Date\n";
$file_content .= &extractInfo($output_page);

foreach my $next_page (@page_numbers) {
	$agent->get($report_url.$next_page);
	my $output_page = $agent->content();
	$file_content .= &extractInfo($output_page);
}

my $outfile = "./data/commjunction_sellthru_$end_month$end_day$end_year.txt"; 
open (OUTFILE, ">$outfile"); 
print OUTFILE $file_content;
close (OUTFILE);

#####################
sub extractInfo()
{
	my ($content) = @_;
	my $fileContent = "";

	my @detail_links;
	(@detail_links) = $content =~ /OpenWindow\(\'(.*?)\'/ig;
	
	foreach my $each_details_link (@detail_links) 
	{
		my ($temp_content, @data_ActionDetail , @data_History, @data_ItemBasedActionHistory);
		$each_details_link =~ s/ispopup\=true\&amp\;//ig;
		$agent->get($prefix_action_url.$each_details_link);
		my $output_page = $agent->content(); 
		$output_page =~ s/\n//g;
		
		(@data_ActionDetail) = $output_page =~ /<td class\=\"complexNoIndentCol\" width=\"75%\">(.*?)<\/td>/ig;
		($temp_content) = $output_page =~ /<div class\=\"title\">History<\/div>(.*?)<\/table>/ig;
		(@data_History) = $temp_content =~ /<td(.*?)<\/td>/ig;
		($temp_content) = $output_page =~ /<div class\=\"title\">Item Based Action History<\/div>(.*?)<\/table>/ig;
		(@data_ItemBasedActionHistory) = $temp_content =~ /<td(.*?)<\/td>/ig;
		my $length = $#data_ItemBasedActionHistory;
		if ($length > 0) {
			foreach (@data_ActionDetail){
				$_ =~ s/\s\s+//g;
					if ($_ =~ m/[0-9]{2}-[0-9]{2}-[0-9]{4}/){
						my @date_parts = split('-', $_);
						my ($year, @time) = split(' ', $date_parts[2]);
						$_ = $year .'-'. $date_parts[0] .'-'. $date_parts[1]. " ". join (' ',@time);
					}
					if ($_ =~ m/^\$/){
						$_ =~ s/\$//g;
						$_ =~ s/USD//g;
						 $_ =~ s/,//g;
					}
				$fileContent .= $_."\t";
			}
			for (my $i=0;$i <= 5;$i++){
				$data_History[$i] =~ s/(.*?)>//g;
				$data_History[$i] =~ s/\&nbsp\;//g;
				if ($data_History[$i] =~ m/[0-9]{2}-[0-9]{2}-[0-9]{4}/){
					my @date_parts = split('-', $data_History[$i]);
					my ($year, @time) = split(' ', $date_parts[2]);
					$data_History[$i] = $year .'-'. $date_parts[0] .'-'. $date_parts[1]. " ". join (' ',@time);
				}
				if ($data_History[$i] =~ m/^\$/){
                                        $data_History[$i] =~ s/\$//g;
                                        $data_History[$i] =~ s/USD//g;
					$data_History[$i] =~ s/,//g;
                                }
				$fileContent .= $data_History[$i]."\t";
			}
			for (my $i=0;$i <= 4;$i++){
				$data_ItemBasedActionHistory[$i] =~ s/(.*?)>//g;
				$data_ItemBasedActionHistory[$i] =~ s/\&nbsp\;//g;
				if ($data_ItemBasedActionHistory[$i] =~ m/[0-9]{2}-[0-9]{2}-[0-9]{4}/){
					my @date_parts = split('-', $data_ItemBasedActionHistory[$i]);
					my ($year, @time) = split(' ', $date_parts[2]);
					$data_ItemBasedActionHistory[$i] = $year .'-'. $date_parts[0] .'-'. $date_parts[1] . " ". join (' ',@time);
				}
				if ($data_ItemBasedActionHistory[$i] =~ m/^\$/){
                                       	$data_ItemBasedActionHistory[$i] =~ s/\$//g;
                                       	$data_ItemBasedActionHistory[$i] =~ s/USD//g;
					$data_ItemBasedActionHistory[$i] =~ s/,//g;
                                }
				$fileContent .= $data_ItemBasedActionHistory[$i]."\t";
			}
			chop($fileContent);
			$fileContent .= "\n";
		}
	}
	$fileContent =~ s/\&nbsp;//g;
	return ( $fileContent );
}
