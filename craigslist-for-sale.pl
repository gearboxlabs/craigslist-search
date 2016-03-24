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

### TODO:  Support a backend to keep track of ads we've seen already

########################################################################
### CONFIGURATION OPTIONS ###
########################################################################

# Add Craigslist RSS search feeds here:
#
# Supports multiple feed URLs.  Each will be parsed and returned; can be done
# to support multiple geographical areas.  Make sure to have query=_SEARCH_ to
# enable proper substitution within search process.
#
my @feeds = (
    "http://seattle.craigslist.org/search/sss?query=_SEARCH_&srchType=A&format=rss"
);

########################################################################
### Initializations
########################################################################

# TODO: Set HTML Headers/Footers.
my $HTML_HEADER = q||;
my $HTML_FOOTER = q||;

# timestamp information
my $dtnow = DateTime->now( time_zone => 'America/Los_Angeles' );

# Plain text message structure.
my $message;

# default to plain text (could be 'html', too)
my $format = 'plain';

# debugging off by default.
my $debug = 0;

#
my $count = 0;

# TODO: move style into a stylesheet to include
my $style = qq|
<style>
p, body, div, td {
 font-size: 9pt;
 }
</style>

|;

########################################################################
### subs
########################################################################

sub help {
  my $extra = shift @_;
  print << "END";
$extra

$0 <--search thing> [--pricemin=dollars] [--pricemax=dollars] [--regex=search] \\
  [--newer-than=minutes] [--format=<html|plain>]

END
  exit;
}

sub debug {
  if( $debug ) {
    printf "[DEBUG] %s\n", (join ' ',@_);
  }
}

sub format_msg {
  my $msg_plain = shift;
  my $msg_html = shift;


  if( $format eq 'plain' ) {
    print "$msg_plain\n";
  }
  else {
    $message .= $msg_html;
  }
}


########################################################################
### parse options & act on them as needed
########################################################################

my %o;
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

# Slurp options out of hash.
my ($pricemin,$pricemax,$regex,$newerthan,$search) = @o{'pricemin','pricemax','regex','newer-than','search'};
my $escsearch = uri_escape( $search );

# Invoke help if: asked
help() if( $o{help} );

if( defined $o{format} && $o{format} eq 'html' ) {
  $format = $o{format};
}

# Set debug mode?
if( defined $o{debug} && $o{debug} ) { $debug = 1; }

# Set formatting junk.
format_msg('', "<h1>Craigslist search for '$search'!</h1>");

########################################################################
### Parse feeds
#
# For each feed in the list, fetch it, and grab all the individual items
# and parse them for whatever we're looking for in our filter set.
#
########################################################################

foreach my $feed (@feeds) {
    $feed =~ s/_SEARCH_/$escsearch/g;
    debug("Searching $feed");
    my $xml = get($feed);

    if( ! $xml ) {
      format_msg(" *** FAILED TO FETCH $feed ! ***", "<h1> Failed to fetch $feed! </h1>");
      next;
    }

    debug("Parsing results");
    my $ref = XMLin($xml);
    my $items = $ref->{item};

    if( ! $items ) {
      format_msg('No items!','<h2> No items! </h2>');
      next;
    }

    if ($o{'reallydebug'} ) {
      print "$xml";
      print Data::Dumper->Dump([$items]);
      exit;
    }

    format_msg("Feed URL: $feed","<h2> Feed URL: <a href='$feed'>$feed</a></h2>\n");
    format_msg('',"<table>\n");

    my %Item;
    for my $item (@$items) {
      my $title = $item->{title};
      my $url = $item->{link};
      my $dcdate = $item->{'dc:date'};

      debug($dcdate);
      $dcdate =~ /(\d\d\d\d)-(\d\d)-(\d\d)T(\d\d):(\d\d):/;
      my $dc = DateTime->new( year => $1, month => $2, day => $3, hour => $4, minute => $5, second => 0, time_zone => 'America/Los_Angeles' );
      my $d = $dtnow->subtract_datetime( $dc );

      $Item{ $dcdate }->{title} = $title;
      $Item{ $dcdate }->{url} = $url;
      $Item{ $dcdate }->{date} = $dcdate;
      $Item{ $dcdate }->{age} = $d->delta_minutes;
    }

    my $s = 0;
    # parse each item, sorted by age.
    for my $item (map { $Item{$_}; } sort { $Item{$a}->{age} <=> $Item{$b}->{age} } keys %Item) {
        my $title = $item->{title};
        my $url = $item->{url};
        my $dcdate = $item->{'date'};
        $s = 0;

        # Default to show responses
        my $showthisone = 1;

        debug($title);

        $title =~ /(\d+)(sq)*ft/;
        $s = (defined $1 ? $1 : 0 );

        # Check if the place is cheap/expensive enough
        my $amount;
        $title =~ /(\$|\&\#x0024\;)(\d+)/;
        $amount = (defined $2?$2:0);

        # Exclude: under min price
        if( defined $pricemin && $amount < $pricemin ) {
          $showthisone = 0;
        }

        # Exclude: over max price
        if( defined $pricemax && $amount > $pricemax ) {
          $showthisone = 0;
        }

        #  Exclude: If we're searching on regex AND we don't match it, THEN don't show it.
        if( $regex ) {
          if( $title !~ /$regex/ ) {
            $showthisone = 0;
          }
        }
        my $age_minutes = $item->{age};

        # Exclude if too old
        if( defined $newerthan && $newerthan > 1 ) {
          debug("age: $age_minutes, sought: $newerthan");

          if( $age_minutes > $newerthan ) {
            $showthisone = 0;
          }
        }

        # Finally, render the ones that pass the filters.
        if( $showthisone ) {
          $count ++;
          format_msg("$title (age: $age_minutes)\n  $url\n\n",
            qq|<tr>
            <td><a href="$url">click</a></td><td>$title</td>
            <td>\$$amount</td><td>Age: $age_minutes minutes</td>
            </tr>\n|
          );
        }
    }
    # don't suck feeds too quickly
    #sleep 2;
  format_msg('',"</table>\n");

  # If we found none, say so.
  unless ($count > 0) {
    format_msg('',"<h2> No results found!</h2>\n");
  }
}

# Render HTML
if( $format eq 'html' ) {
  print $message;
}

exit 0;

__END__

