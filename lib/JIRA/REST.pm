package JIRA::REST;
use Moose;
# ABSTRACT: Alternative Jira REST client

use File::ShareDir    qw/ dist_file /;
use Net::HTTP::Spore;
use Try::Tiny;

=head1 DESCRIPTION

JIRA::REST is a wrapper for the L<JIRA REST
API|http://docs.atlassian.com/jira/REST/latest/>.  It is a thin wrapper,
returning the decoded version of the JSON without any munging or mangling.

JIRA::REST is *heavily* based upon L<JIRA::Client::REST>. The primary
difference is that the latter library uses a positional argument convention in
method calls, where as this libraries uses a named argument convention. This
library also currently implements more of the JIRA REST API.

=head1 SYNOPSIS

    use JIRA::REST;

    my $client = JIRA::REST->new(
        username => 'username',
        password => 'password',
        base_url => 'http://jira.mycompany.com',
    );
    my $issue = $client->get_issue( id => 'TICKET-12');
    print $issue->{fields}{priority}{value}{name}."\n";

=cut

has 'spore_file' => (
  is => 'ro' ,
  isa => 'Str' ,
  default => sub {
    my $file;
    try { $file = dist_file( 'JIRA-REST' , 'jira.json' ) }
    catch {
      ## grumble grumble File::Share doesn't play well with dzil...yet.
      if ( $ENV{HARNESS_ACTIVE} and -e 'share/jira.json' ) {
        $file = 'share/jira.json'
      }
      else { die "Can't find SPORE definition file"; }
    };

    return $file;
  } ,
);

has '_client' => (
  is      => 'rw',
  lazy    => 1,
  handles => [ qw/
                   create_issue
                   get_issue
                   get_issue_createmeta
                   get_issue_transitions
                   get_issue_votes
                   get_issue_watchers
                   get_project
                   get_project_versions
                   get_version
                   unvote_for_issue
                   unwatch_issue
                   vote_for_issue
                   watch_issue
                 /],
  default => sub {
    my $self = shift;

    my $client = Net::HTTP::Spore->new_from_spec(
      $self->spore_file ,
      base_url => $self->base_url,
      trace    => $self->debug,
    );
    $client->enable('Format::JSON');
    $client->enable('Auth::Basic', username => $self->username, password => $self->password);
    return $client;
  }
);

has debug => (
  is      => 'rw',
  isa     => 'Bool',
  default => 0,
);

=attr password

Set/Get the password to use when connecting to JIRA.

=cut

has password => (
  is       => 'rw',
  isa      => 'Str',
  required => 1
);

=attr base_url

Set/Get the URL for the JIRA instance.

=cut

has base_url => (
  is       => 'rw',
  isa      => 'Str',
  required => 1
);

=attr username

Set/Get the username to use when connecting to JIRA.

=cut

has username => (
  is       => 'rw',
  isa      => 'Str',
  required => 1
);

=method get_issue( %args )

Get the issue with the supplied id.  Returns a HashRef of data.

=method get_issue_createmeta( %args )

Get the meta data (required and optional fields, etc.) for creating issues.

=method get_issue_transitions( %args )

Get the transitions possible for this issue by the current user.

=method get_issue_votes( %args )

Get voters on the issue.

=cut

=method get_issue_watchers( %args )

Get watchers on the issue.

=method get_project( %args )

Get the project for the specifed key.

=method get_project_versions( %args )

Get the versions for the project with the specified key.

=method get_version( %args )

Get the version with the specified id.

=method unvote_for_issue( %args )

Remove your vote from an issue.

=method unwatch_issue( %args )

Remove a watcher from an issue.

=method vote_for_issue( %args )

Cast your vote in favor of an issue.

=method watch_issue( %args )

Watch an issue. (Or have someone else watch it.)

=cut

__PACKAGE__->meta->make_immutable;

1;
