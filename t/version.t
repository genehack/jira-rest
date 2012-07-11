use strict;
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

my $ver = $client->get_version( id => '10001' );
cmp_ok($ver->body->{name}, 'eq', '0.04', 'version name');

done_testing;
