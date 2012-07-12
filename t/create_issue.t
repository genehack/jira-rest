use strict;
use warnings;
use Test::More;
use JIRA::REST;

plan skip_all => 'Set JIRA_REST_URL'
  unless $ENV{JIRA_REST_URL};

my $client = JIRA::REST->new(
    username => $ENV{JIRA_REST_USER},
    password => $ENV{JIRA_REST_PASS},
    base_url => $ENV{JIRA_REST_URL},
    debug    => 1,
);

my $issue = $client->create_issue(
#  content_type => 'application/json' ,
  fields => {
    project => { key => 'TESTING' } ,
    summary => 'genehack test' ,
    description => 'this is never gonna work' ,
    issuetype => { name => 'Bug' } ,
  },
);

use DDP;
p $issue;

done_testing;
