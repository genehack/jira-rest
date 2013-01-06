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

my $issue_id = $client->create_issue(
  fields => {
    assignee    => { name => $ENV{JIRA_REST_USER} },
    project     => { key => 'TESTING' } ,
    summary     => 'genehack test' ,
    description => 'this is never gonna work' ,
    issuetype   => { name => 'Bug' } ,
  },
);

like( $issue_id , qr/TESTING-\d+/ , 'expected return' );

my $issue = $client->get_issue( $issue_id );
is( $issue->{fields}{assignee}{name} , $ENV{JIRA_REST_USER} , 'expected user' );

done_testing;
