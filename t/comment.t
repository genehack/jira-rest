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
    summary     => 'genehack comment test' ,
    description => 'chatty cathy' ,
    issuetype   => { name => 'Task' } ,
  },
);

like( $issue_id , qr/TESTING-\d+/ , 'expected return' );

my $success = $client->post_comment(
  id   => $issue_id ,
  body => 'this is a comment' ,
);

is( $success , 1 , 'comment posted' );

done_testing;
