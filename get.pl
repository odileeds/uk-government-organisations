#!/usr/bin/perl

use JSON::XS;
use Data::Dumper;

$url = "https://www.gov.uk/government/organisations";
$file = "gov.uk_government_organisations.html";
$cfile = "gov.uk_government_organisations.csv";
$cfile2 = "gov.uk_government_organisations-augmented.csv";
$cfile3 = "gov.uk_api_organisations-augmented.csv";
$tfile2 = "gov.uk_government_organisations-augmented.tsv";
$tfile3 = "gov.uk_api_organisations-augmented.tsv";
$ufile = "gov.uk_government_organisations-replacement-urls.csv";
$jfile = "gov.uk_api_organisations.json";
$apiurl = "https://gov.uk/api/organisations";
if(!-e $file || (time() - (stat $file)[9] >= 86400/2)){
	print "Getting $url...\n";
	`wget -q --no-check-certificate -O $file "$url"`;
}

@results = getAPIresults();


%urls;
open(FILE,$ufile);
@lines = <FILE>;
close(FILE);
foreach $line (@lines){
	$line =~ s/[\n\r]//g;
	($url1,$url2) = split(/\,/,$line);
	$urls{$url1} = $url2;
}


open(FILE,$file);
@lines = <FILE>;
close(FILE);
$content = join("",@lines);
$content =~ s/[\n\r]/ /g;
$content =~ s/ {2,}/ /g;

%orgs;
$csv = "ID,Name,GOVUK URL,URL\n";
while($content =~ s/<li class="organisations-list__item"(.*?)<\/li//){
	$li = $1;
	$id = "";
	$name = "";
	$href = "";
	$sep = 0;
	$url = "";
	if($li =~ /^ id="([^\"]+)"/){
		$id = $1;
	}
	if($li =~ /<a class="govuk-link organisation-list__item-title" href="([^\"]+)">([^\<]+)<\/a>/){
		$name = $2;
		$href = "https://gov.uk".$1;
		$url = $href;
	}
	if(!$name && $li =~ /<span class="gem-c-organisation-logo__name">([^\<]+)<\/span>/){
		$name = $1;
	}
	if(!$href && $li =~ /<a class="gem-c-organisation[^\"]*" href="([^\"]+)">/){
		$href = "https://gov.uk".$1;
		$url = $href;
	}
	if($li =~ /separate website/){
		$sep = 1;
		if(!$urls{$url}){
			print "Get $name website ($sep) $href\n";
			$html = `wget -q --no-check-certificate -O- "$href"`;
			$html =~ s/[\n\r]/ /g;
			$html =~ s/ {2,}//g;
			if($html =~ /<a href="([^\"]+)">separate website<\/a>/){
				$urls{$href} = $1;
				$url = $1;
				saveURLLookup();
			}
		}else{
			$url = $urls{$href};
		}
	}
	$ohref = $href;
	$ohref =~ s/https:\/\/gov.uk/https:\/\/www.gov.uk/;
	#$orgs{$ohref} = {'id'=>$id,'name'=>$name,'url'=>($url||$href),'href'=>$href};
	$orgs{$href} = {'id'=>$id,'name'=>$name,'url'=>($url||$href),'href'=>$href};
	$csv .= "$id,\"$name\",$href,$url\n";
}


open(FILE,">",$cfile);
print FILE $csv;
close(FILE);

%apilookup;
for($r = 0; $r < @results; $r++){
	#print "$r - $results[$r]{'web_url'}\n";
	$results[$r]{'web_url'} =~ s/www.gov.uk/gov.uk/;
	$apilookup{$results[$r]{'web_url'}} = $results[$r];
}

$csv = "GB-GOR,Name,Type,GOVUK URL,URL,Updated\n";
$tsv = "GB-GOR\tName\tType\tGOVUK URL\tURL\tUpdated\n";
foreach $href (sort(keys(%orgs))){
	if($apilookup{$href}{'details'}{'closed_at'} !~ /[0-9]{4}/){
		$csv .= "$apilookup{$href}{'analytics_identifier'},\"$orgs{$href}{'name'}\",$apilookup{$href}{'format'},$href,$orgs{$href}{'url'},$apilookup{$href}{'updated_at'}\n";
		$tsv .= "$apilookup{$href}{'analytics_identifier'}\t$orgs{$href}{'name'}\t$apilookup{$href}{'format'}\t$href\t$orgs{$href}{'url'}\t$apilookup{$href}{'updated_at'}\n";
	}else{
		print "Bad date for $orgs{$href}{'name'}\n";
	}
}

open(FILE,">",$cfile2);
print FILE $csv;
close(FILE);
open(FILE,">",$tfile2);
print FILE $tsv;
close(FILE);

$n = 0;
$csv = "GB-GOR,Name,Type,GOVUK URL,URL,Updated\n";
$tsv = "GB-GOR\tName\tType\tGOVUK URL\tURL\tUpdated\n";
for($r = 0; $r < @results; $r++){
	if($results[$r]{'details'}{'closed_at'} !~ /[0-9]{4}/){
		$name = $results[$r]{'title'};
		$href = $results[$r]{'web_url'};
		$format = $results[$r]{'format'};
		$url = $href;
		$update = $results[$r]{'updated_at'};
		#print "$href\n";
		if($orgs{$href}{'url'} && $orgs{$href}{'url'} ne $href){
			#print "Replacing $href with $orgs{$href}{'url'}\n";
			$url = $orgs{$href}{'url'};
			$name = $orgs{$href}{'name'};
			#$update = "*";
		}
	#	if($format eq "Executive office" || $format eq "Ministerial department" || $format eq "Non-ministerial department" || $format eq "Executive agency" || $format eq "Executive non-departmental public body" || $format eq "Devolved administration" || $format eq "Public corporation"){# || $format eq "Other"){
			$csv .= "$results[$r]{'analytics_identifier'},\"$name\",$format,$href,$url,$update\n";
			$tsv .= "$results[$r]{'analytics_identifier'}\t$name\t$format\t$href\t$url\t$update\n";
	#	}
		$n++;
	}
}

open(FILE,">",$cfile3);
print FILE $csv;
close(FILE);

open(FILE,">",$tfile3);
print FILE $tsv;
close(FILE);

print "Total: $n\n";





################################
#
sub getAPIresults {
	my ($n,$lastpage,$pagefile,@lines,$json_text,$json,$results,@files,$f);

	$lastpage = "";
	$n = 1;
	$json = {'next_page_url'=>$apiurl};
	$results->{'results'} = ();
	
	if(!-e $jfile || (time() - (stat $jfile)[9] >= 86400*30)){

		while($json->{'next_page_url'} && $json->{'next_page_url'} ne $lastpage){

			$pagefile = $jfile.".$n";
			push(@files,$pagefile);
			if(!-e $pagefile || (time() - (stat $pagefile)[9] >= 86400*30)){
				print "Getting $json->{'next_page_url'} ...\n";
				`wget -q --no-check-certificate -O $pagefile "$json->{'next_page_url'}"`;
			}

			$lastpage = $json->{'next_page_url'};

			open(FILE,$pagefile);
			@lines = <FILE>;
			close(FILE);
			
			$json_text = join("",@lines);
			$json = JSON::XS->new->utf8->decode($json_text);

			push(@{$results->{'results'}},@{$json->{'results'}});
		
			$n++;
		}
		$json_text = JSON::XS->new->utf8->pretty->canonical(1)->encode($results);
		open(FILE,">",$jfile);
		print FILE $json_text;
		close(FILE);
	}else{
	
		open(FILE,$jfile);
		@lines = <FILE>;
		close(FILE);
		$results = JSON::XS->new->utf8->decode(join("",@lines));
	}

	for($f = 0; $f < @files; $f++){
		`rm $files[$f]`;
	}
	return @{$results->{'results'}};
}



# Save URL lookup
sub saveURLLookup {
	my $url;
	open(FILE,">",$ufile);
	foreach $url (sort(keys(%urls))){
		print FILE "$url,$urls{$url}\n";
	}
	close(FILE);
	
}