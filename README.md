
CRAIGSLIST SEARCH TOOLS

./craigslist-for-sale.pl 
  - <--search 'whatever'>     - Search for something for sale
  - Other options as above, except no sqft



* The apartment tool is not being worked on, so enjoy.  New work is going into 'craigslist-for-sale'

./craigslist-apartment.pl 
  - [--sqft=<min sq ft>]      - Show apartments with this much or more space
  - [--pricemin=dollars]      - Only show ones that cost at least this much
  - [--pricemax=dollars]      - Only show ones that cost no more than this much
  - [--regex=search]          - Filter, perl regex
  - [--newer-than=minutes]    - Show ones listed at least this recently
  - [--format=<html|plain>]   - Output format, plain for email, html for web

Want to send email results?  Use the included make_mime_mail tool.

./make_mime_mail.pl <subject> <to> <from>
  - Send email to someone as a HTML mail.

Example:
* ./craigslist-for-sale.pl --search whatever | ./make_mime_mail.pl 'Your Search' youremail youremail

Based on the car search code by http://jeremy.zawodny.com/blog/archives/001440.html

Lots of added features by Gabriel Cain. 
