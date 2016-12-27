#!/usr/bin/perl

use strict;
use LogProcessor;
use Apache::Log::Parser;
use GeoIP2::Database::Reader;

my ($dbfile, $logfile) = @ARGV;

if (!$dbfile || !$logfile) {
    print "Usage: $0 GeoLite2-City.mmdb access.log\n";
    exit(1);
}

my $reader = GeoIP2::Database::Reader->new(
    file => $dbfile,
    locales => [ 'en' ]
);

my $logProcessor = LogProcessor->new(
  logfile => $logfile,
  parser => Apache::Log::Parser->new( fast => 1 ),
  geoip => $reader
);

$logProcessor->process();

print "Top 10 for visitors:\n";

print "\tCountries:\n";
foreach(@{$logProcessor->getCountriesStats}) {
  print "\t\t".$_->{title}.' - '.$_->{count}."\n";
}
print "\tStates:\n";
foreach(@{$logProcessor->getStatesStats}) {
  print "\t\t".$_->{title}.' - '.$_->{count}."\n";
}

print "Most popular page:\n";

print "\tCountries:\n";
foreach(@{$logProcessor->getCountriesStats}) {
  print "\t\t".$_->{title}.':  '.$logProcessor->getCountryTopPage($_->{title})."\n";
}
print "\tStates:\n";
foreach(@{$logProcessor->getStatesStats}) {
  print "\t\t".$_->{title}.':  '.$logProcessor->getStateTopPage($_->{title})."\n";
}
