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

my $issue = $client->get_issue('TESTING-39' );
cmp_ok($issue->{fields}{priority}{name}, 'eq', 'Minor', 'get_issue');

my $create_meta = $client->get_issue_createmeta();
my( $test_proj ) = grep { $_->{key} eq 'TESTING' } @{ $create_meta->{projects} };
cmp_ok( $test_proj->{name} , 'eq' , 'TESTING' , 'get_issue_createmeta' );

my $trans = $client->get_issue_transitions( 'TESTING-39' );
my( $stop_trans ) = grep { $_->{id} == 5 } @{ $trans->{transitions} };
cmp_ok( $stop_trans->{name} , 'eq' , 'Ready For Review', 'get_issue_transitions');

my $votes = $client->get_issue_votes( 'TESTING-39' );
cmp_ok($votes->{votes}, '==', 0, 'get_issue_votes');

cmp_ok(
  $client->vote_for_issue( 'TESTING-39')->code,
  'eq', 204, 'vote_for_issue'
);

cmp_ok(
  $client->unvote_for_issue( 'TESTING-39')->code,
  'eq', 204, 'unvote_for_issue'
);

my $watchers = $client->get_issue_watchers( 'TESTING-39' );
cmp_ok($watchers->{watchCount}, '==', 0, 'get_issue_watchers');

cmp_ok(
  $client->watch_issue({ id => 'TESTING-39', username => 'john.anderson' })->code,
  '==', 204, 'watch_issue'
);

$watchers = $client->get_issue_watchers( 'TESTING-39' );
cmp_ok($watchers->{watchCount}, '==', 1, 'get_issue_watchers');

cmp_ok(
  $client->unwatch_issue({ id => 'TESTING-39', username => 'john.anderson' })->code,
  '==', 204, 'unwatch_issue'
);

$watchers = $client->get_issue_watchers( 'TESTING-39' );
cmp_ok($watchers->{watchCount}, '==', 0, 'get_issue_watchers');

cmp_ok(
  $client->watch_issue( 'TESTING-39' )->code,
  '==', 204, 'watch_issue'
);

$watchers = $client->get_issue_watchers( 'TESTING-39' );
cmp_ok($watchers->{watchCount}, '==', 1, 'get_issue_watchers');

cmp_ok(
  $client->unwatch_issue( 'TESTING-39' )->code,
  '==', 204, 'unwatch_issue'
);

$watchers = $client->get_issue_watchers( 'TESTING-39' );
cmp_ok($watchers->{watchCount}, '==', 0, 'get_issue_watchers');

my $types = $client->get_issue_link_types();
foreach ( @{ $types->{issueLinkTypes} } ) {
  ok( defined $_->{id}   , 'link type has id' );
  ok( defined $_->{name} , 'link type has name' );
}

# get issues, verify no links & bail if there are
{
  my $in_issue = $client->get_issue( 'TESTING-99' );
  is( $in_issue->{key} , 'TESTING-99' , 'got -99' )
    or BAIL_OUT( 'Unable to get TESTING-99' );
  is( scalar @{ $in_issue->{fields}{issuelinks} } , 0 , 'no links' )
    or BAIL_OUT( 'TESTING-99 has a link' );

  my $out_issue = $client->get_issue( 'TESTING-100' );
  is( $out_issue->{key} , 'TESTING-100' , 'got -100' )
    or BAIL_OUT( 'Unable to get TESTING-100' );
  is( scalar @{ $in_issue->{fields}{issuelinks} } , 0 , 'no links' )
    or BAIL_OUT( 'TESTING-100 has a link' );
}

my $success = $client->link_issues(
  type         => { name => 'Duplicate' } ,
  inwardIssue  => { key  => 'TESTING-99' } ,
  outwardIssue => { key  => 'TESTING-100' } ,
);
ok( $success , 'created link' );

my $issue_id;
# reget issues, verify link
{
  my $in_issue = $client->get_issue( 'TESTING-99' ) ;
  is( scalar @{ $in_issue->{fields}{issuelinks} } , 1 , '1 link' );
  is( $in_issue->{fields}{issuelinks}[0]{outwardIssue}{key} ,
      'TESTING-100' , 'correct link' );

  my $out_issue = $client->get_issue( 'TESTING-100' ) ;
  is( scalar @{ $out_issue->{fields}{issuelinks} } , 1 , '1 link' );
  is( $out_issue->{fields}{issuelinks}[0]{inwardIssue}{key} ,
      'TESTING-99' , 'correct link' );

  $issue_id = $in_issue->{fields}{issuelinks}[0]{id};
}

# delete link
{
  my $success = $client->delete_issue_link( $issue_id );
  ok( $success , 'deleted link' );
}

# reget issues, verify no links
{
  my $in_issue = $client->get_issue( 'TESTING-99' );
  is( scalar @{ $in_issue->{fields}{issuelinks} } , 0 , 'no links' );

  my $out_issue = $client->get_issue( 'TESTING-100' );
  is( scalar @{ $in_issue->{fields}{issuelinks} } , 0 , 'no links' );
}



done_testing;
