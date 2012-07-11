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
    debug    => $ENV{JIRA_REST_DEBUG} ,
);

my $issue = $client->get_issue( id => 'TESTING-39');
cmp_ok($issue->body->{fields}{priority}{name}, 'eq', 'Minor', 'get_issue');

my $trans = $client->get_issue_transitions( id => 'TESTING-39');
my( $stop_trans ) = grep { $_->{id} == 761 } @{ $trans->body->{transitions} };
cmp_ok( $stop_trans->{name} , 'eq' , 'Stop Progress', 'get_issue_transitions');

my $votes = $client->get_issue_votes( id => 'TESTING-39');
cmp_ok($votes->body->{votes}, '==', 0, 'get_issue_votes');

cmp_ok(
  $client->vote_for_issue( id => 'TESTING-39')->status,
  'eq', 204, 'vote_for_issue'
);

cmp_ok(
  $client->unvote_for_issue( id => 'TESTING-39')->status,
  'eq', 204, 'unvote_for_issue'
);

my $watchers = $client->get_issue_watchers( id => 'TESTING-39' );
cmp_ok($watchers->body->{watchCount}, '==', 0, 'get_issue_watchers');

cmp_ok(
  $client->watch_issue( id => 'TESTING-1', username => 'cory.watson')->status,
  '==', 204, 'watch_issue'
);

cmp_ok(
  $client->unwatch_issue( id => 'TESTING-1', username => 'cory.watson')->status,
  '==', 204, 'unwatch_issue'
);

done_testing;
