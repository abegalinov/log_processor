package LogProcessor;

use strict;
use Moose;
use Apache::Log::Parser;

has 'logfile' =>(
  'is' => 'rw',
  'isa' => 'Str',
  'required' => 1
);

has 'parser', is=>'rw', 'required'=>1;
has 'geoip', is=>'rw', 'required'=>1;
has 'fh', 'is' => 'ro';
has 'countries', 'is' => 'ro';
has 'states', 'is' => 'ro';
has 'countries_pages', 'is' => 'ro';
has 'states_pages', 'is' => 'ro';
has 'ip_cache', 'is' => 'ro';

my @IGNORE_PATH = qw(
  /[a-f0-9]+/css/
  /[a-f0-9]+/images/
  /[a-f0-9]+/js/
  /entry-images/
  /images/
  /user-images/
  /static/
  /robots.txt
  /favicon.ico
  .rss$
  .atom$
);

sub BUILD {
  my $this = shift;
  $this->_initFH();
  $this->_initCache();
}

sub DEMOLISH {
  my $this = shift;
  $this->_cleanCache();
  close($this->{fh});
}

sub _initFH {
  my $this = shift;
  open(my $fh, $this->logfile) || die("Can't open logfile: $!");
  $this->{fh} = $fh;
}

sub _shouldIgnore {
  my ($this, $path) = @_;
  return 1 if grep { $path =~ /$_/ } @IGNORE_PATH;
}

sub _initCache {
    shift->{ip_cache} = {};
}

sub _cleanCache {
    delete shift->{ip_cache};
}

sub process {
  my $this = shift;
  my $fh = $this->fh;

  while(<$fh>) {
    my $log = $this->parser->parse($_);
    next if $this->_shouldIgnore($log->{path});
    $this->_collectStats($log->{rhost}, $log->{path});
  }
}

sub _collectStats {
  my ($this, $ip, $path) = @_;
  my ($country, $state);

  unless($this->ip_cache->{$ip}) {
    my $city = $this->geoip->city( ip => $ip );
    $country = $city->country->name || 'Unknown';
    if($city->country->iso_code && $city->country->iso_code eq 'US') {
      $state = $city->most_specific_subdivision->name || 'Unknown';
    }
    $this->{ip_cache}->{$ip} = { country => $country, state => $state };
  } else {
    ($country, $state) = ($this->ip_cache->{$ip}->{country}, $this->ip_cache->{$ip}->{state});
  }

  $this->{countries}->{$country}++;
  $this->{countries_pages}->{$country}->{$path}++ if $path ne '/';

  if($state) {
    $this->{states}->{$state}++;
    $this->{states_pages}->{$state}->{$path}++ if $path ne '/';
  }
}

sub _sortStats {
  my ($this, $hash) = @_;
  my @keys_sorted = sort { $hash->{$b} <=> $hash->{$a} } keys(%{$hash});
  my @pairs = map { {'title'=>$_, 'count'=>$hash->{$_}} } @keys_sorted;
  return scalar(@pairs) > 10 ? [ @pairs[0..9] ] : \@pairs;
}

sub getStatesStats {
  my $this = shift;
  return $this->_sortStats($this->states);
}

sub getCountriesStats {
  my $this = shift;
  return $this->_sortStats($this->countries);
}

sub getStateTopPage {
  my ($this, $state) = @_;

  my @pages = sort {
    $this->states_pages->{$state}->{$b} <=> $this->states_pages->{$state}->{$a}
  } keys(%{$this->states_pages->{$state}});
  return $pages[0] || '/';
}

sub getCountryTopPage {
  my ($this, $country) = @_;

  my @pages = sort {
    $this->countries_pages->{$country}->{$b} <=> $this->countries_pages->{$country}->{$a}
  } keys(%{$this->countries_pages->{$country}});
  return $pages[0] || '/';
}

1;
