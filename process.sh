#!/bin/sh
date -R
RUNDIRDATA=/home/dhiraj/Webcrawler

cd ${RUNDIRDATA}
rm -f *.txt

./pepperjam_sellthru_crawler.pl -sdate='2013-11-01' -edate='2013-11-31'

iconv -c -f LATIN1 -t UTF-8 ${RUNDIRDATA}/*.txt > ${RUNDIRDATA}/pepperjam.conv

echo "----Truncating tables----"
psql -U etailer1 -d events -c"truncate table pepperjam_sellthru" -h 127.0.0.1 -W

echo "----Copying data----"
psql -U etailer1 -d events -c"\\copy pepperjam_sellthru from pepperjam.conv" -h 127.0.0.1 -W

#rm -f pepperjam.conv

echo "----Counts----"
psql -U etailer1 -d events -c"select count(*) as total from pepperjam_sellthru" -h 127.0.0.1 -W 
date -R



