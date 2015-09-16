#!/usr/bin/perl -w
#
# craigslist carfinder
# based on: http://jeremy.zawodny.com/blog/archives/001440.html

use strict;
use XML::Simple;
use LWP::Simple;
use Data::Dumper;
use DateTime;
#use CGI qw/:standard/;
#use CGI::Pretty;
use URI::Escape;

use Getopt::Long;

my $style = qq|
<style>
p, body, div, td {
 font-size: 9pt;
 }
</style>

|;
my %o;

my $format = 'plain';

GetOptions( \%o,
  'search=s',
  'pricemin=i',
  'pricemax=i',
  'newer-than=i',
  'regex=s',
  'format=s',
  'help',
  'debug',
  'reallydebug'
);

if( $o{help} ) {
  print << "END";
$0 <--search thing> [--pricemin=dollars] [--pricemax=dollars] [--regex=search] [--newer-than=minutes] [--format=<html|plain>]

END
  exit;
} 

if( defined $o{format} && $o{format} eq 'html' ) {
  $format = $o{format};
}


my $debug = 0;
my ($pricemin,$pricemax,$regex,$newerthan,$search) = @o{'pricemin','pricemax','regex','newer-than','search'};

if( defined $o{debug} && $o{debug} ) { $debug = 1; }

$search = uri_escape( $search );


# Add Craigslist RSS search feeds here:
my @feeds = ( 
  #"http://seattle.craigslist.org/search/sss?query=$search&srchType=A&format=rss",
    "http://seattle.craigslist.org/search/sss?query=$search&srchType=A&format=rss",
);

sub debug {
  if( $debug ) {
    printf "[DEBUG] %s\n", (join ' ',@_);
  }
}

# Now!
my $dtnow = DateTime->now( time_zone => 'America/Los_Angeles' );

my $message;

if( $format eq 'html' ) {
  $message .= $style;
  $message .= "<h1>Craigslist search for '$search'!</h1>";


}

my $count = 0;

for my $feed (@feeds)
{
    debug "Searching $feed";
    my $xml = get($feed);
    debug "Parsing results";
    my $ref = XMLin($xml);
    my $items = $ref->{item};

    if ($o{'reallydebug'} )
    {
        print "$xml";
        print Data::Dumper->Dump([$items]);
        exit;
    }

    if( $format eq 'plain' ) {
      print "Feed URL: $feed\n";
    }
    if( $format eq 'html' ) {
      $message .= "<h2> Feed URL: <a href='$feed'>$feed</a></h2>\n";
      $message .= "<table>\n";
    }

    my %Item;
    for my $item (@$items) {
        my $title = $item->{title};
        my $url = $item->{link};
        my $dcdate = $item->{'dc:date'};

        debug $dcdate;
        $dcdate =~ /(\d\d\d\d)-(\d\d)-(\d\d)T(\d\d):(\d\d):/;
        my $dc = DateTime->new( year => $1, month => $2, day => $3, hour => $4, minute => $5, second => 0, time_zone => 'America/Los_Angeles' );
        my $d = $dtnow->subtract_datetime( $dc );

        $Item{ $dcdate }->{title} = $title;
        $Item{ $dcdate }->{url} = $url;
        $Item{ $dcdate }->{date} = $dcdate;
        $Item{ $dcdate }->{age} = $d->delta_minutes; 
    }



    my $s = 0;
    for my $item (map { $Item{$_}; } sort { $Item{$a}->{age} <=> $Item{$b}->{age} } keys %Item) {
        my $title = $item->{title};
        my $url = $item->{url};
        my $dcdate = $item->{'date'};
        $s = 0;

        # Default to show responses
        my $showthisone = 1;

        debug $title;

        $title =~ /(\d+)(sq)*ft/;
        $s = (defined $1 ? $1 : 0 );

        # Check if the place is cheap/expensive enough
        my $amount;
        $title =~ /\$(\d+)/;
        $amount = (defined $1?$1:0);

        if( defined $pricemin && $amount < $pricemin ) {
          $showthisone = 0;
        }

        if( defined $pricemax && $amount > $pricemax ) {
          $showthisone = 0;
        }

        # If we're searching on regex AND we don't match it, THEN don't show it.
        if( $regex ) {
          if( $title !~ /$regex/ ) {
            $showthisone = 0;
          }
        }
        my $age_minutes = $item->{age};

        if( defined $newerthan && $newerthan > 1 ) {
          debug "age: $age_minutes, sought: $newerthan";

          if( $age_minutes > $newerthan ) {
            $showthisone = 0;
          }
        }

        if( $showthisone ) {
          $count ++;
          if( $format eq 'plain' ) {
            print "$title (age: $age_minutes)\n  $url\n\n";
          }
          if( $format eq 'html' ) {
            $message .= qq|<tr><td><a href="$url">click</a></td><td>$title</td><td>\$$amount</td><td>Age: $age_minutes minutes</tr>\n|;
          }
        }
    }
    # don't suck feeds too quickly
    #sleep 2;
  $message .= "</table>\n";
}



if( $format eq 'html' ) {
  print $message;
}

exit;

__END__

