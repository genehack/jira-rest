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

my $proj = $client->get_project( key => 'TESTING' );
cmp_ok($proj->body->{name}, 'eq', 'TESTING', 'project name');

my $vers = $client->get_project_versions( key => 'TESTING' );
ok(scalar(@{ $vers->body }) > 0, 'got versions');

done_testing;
