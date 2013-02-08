#!/usr/bin/perl
#

use strict;
use MIME::Lite;

my $subject = shift @ARGV;
my $to = shift @ARGV;
my $from = shift @ARGV;

if( !$subject || !$to || !$from ) {
  die("Usage: $0 <subject> <to> <from>\n");
}

my $body;

while(<>){
  $body .= $_;
}

my $msg = MIME::Lite->new( 
  From => $from,
  To => $to,
  Subject => $subject,
  Type => 'text/html',
  Data => $body
);

$msg->send;


