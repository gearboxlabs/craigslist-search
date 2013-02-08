
CRAIGSLIST APARTMENT SEARCH TOOL

./craigslist-apartment.pl 
  - [--sqft=<min sq ft>]      - Show apartments with this much or more space
  - [--pricemin=dollars]      - Only show ones that cost at least this much
  - [--pricemax=dollars]      - Only show ones that cost no more than this much
  - [--regex=search]          - Filter, perl regex
  - [--newer-than=minutes]    - Show ones listed at least this recently
  - [--format=<html|plain>]   - Output format, plain for email, html for web


./make_mime_mail.pl <subject> <to> <from>
  - Send email to someone as a HTML mail.


Based on the car search code by http://jeremy.zawodny.com/blog/archives/001440.html

Lots of added features by Gabriel Cain. 
