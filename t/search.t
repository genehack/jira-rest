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
    debug    => $ENV{JIRA_REST_DEBUG},
);

{
  my @issues = $client->search( 'project = TESTING' );

  is( scalar @issues , 50 , 'get 50 without limit' );
  foreach ( @issues ) {
    my $issue = $_->{key} // 'no key';
    is( $_->{fields}{project}{name} , 'TESTING' , "$issue in TESTING" ) ;
  }
}

{
  my @issues = $client->search({
    jql        => 'project = TESTING' ,
    maxResults => 2 ,
  });

  is( scalar @issues , 2 , 'get 2 because of limit' );
  foreach ( @issues ) {
    my $issue = $_->{key} // 'no key';
    is( $_->{fields}{project}{name} , 'TESTING' , "$issue in TESTING" ) ;
  }

}

done_testing;
