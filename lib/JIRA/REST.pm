package JIRA::REST;
use Moose;
# ABSTRACT: Alternative Jira REST client

use Carp;
use Data::Printer;
use File::ShareDir    qw/ dist_file /;
use HTTP::Request;
use JSON;
use LWP::UserAgent;
use Try::Tiny;

=head1 DESCRIPTION

JIRA::REST is a wrapper for the L<JIRA REST
API|http://docs.atlassian.com/jira/REST/latest/>.  It is a thin wrapper,
returning the decoded version of the JSON without any munging or mangling.

JIRA::REST is *heavily* based upon L<JIRA::Client::REST>. The primary
difference is that the latter library uses L<Net::HTTP::Spore>, and this
library just uses L<LWP> directly. Additionally, this library has more
flexible and (IMO) more sane method signatures. Finally, this library also
currently implements more of the JIRA REST API than L<JIRA::Client::REST>

=head1 SYNOPSIS

    use JIRA::REST;

    my $client = JIRA::REST->new(
        username => 'username',
        password => 'password',
        base_url => 'http://jira.mycompany.com',
    );
    my $issue = $client->get_issue( 'TICKET-12' );
    print $issue->{fields}{priority}{value}{name}."\n";

=cut

=attr api_prefix

Set/Get the initial part of the URL for the JIRA instance

Example: '/rest/api/latest/'

Default: '/rest/api/latest/'

=cut

has api_prefix => (
  is      => 'rw' ,
  isa     => 'Str' ,
  lazy    => 1 ,
  default => '/rest/api/latest/' ,
);

=attr base_url

Set/Get the base host part of the URL for the JIRA instance.

Example: 'https://jira.yourcompany.com'

No default; required attribute.

=cut

has base_url => (
  is       => 'rw',
  isa      => 'Str',
  required => 1
);

=attr debug

Debug flag. Makes the copious outputs.

=cut

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

=attr username

Set/Get the username to use when connecting to JIRA.

=cut

has username => (
  is       => 'rw',
  isa      => 'Str',
  required => 1
);

# internal attributes

has '_ua' => (
  is      => 'ro' ,
  isa     => 'LWP::UserAgent' ,
  lazy    => 1 ,
  default => sub { LWP::UserAgent->new() },
  handles => [ qw/ request / ] ,
);

=method create_issue( %args )

Create an issue with the provided arguments. Returns the issue ID for the
newly generated issue or throws an exception.

Example:

    my $new_issue_id = $client->create_issue(
      fields => {
        assignee    => { name => 'jira.username' } ,
        project     => { key => 'PROJECTKEY' } ,
        summary     => 'short summary' ,
        description => 'long description' ,
        issuetype   => { name => 'Type' } ,
      },
    );

=cut

sub create_issue {
  my $self = shift;

  my %args = _expand_args( \@_ );

  my $response = $self->_send_request(
    method => 'POST' ,
    url    => _build_url( "issue" ) ,
    data   => \%args ,
  );

  if ( $response->is_success and $response->message eq 'Created' ) {
    my $data = decode_json( $response->content );

    return $data->{key} if $data->{key};

    # FIXME exceptions...
    print STDERR
      "ERROR: Got 'created' message for issue creation but did not get key for new issue!\n";
    print STDERR p $data;
    print STDERR "\n";
    die;
  }

  # FIXME exceptions
  print STDERR "Request failed.";
  print STDERR p $response;
  die;
}

=method get_issue( %args )

Get the issue with the supplied id.  Returns a HashRef of data.

=cut

sub get_issue {
  my $self = shift;

  my %args = _expand_args( \@_ , [ 'id' ] );
  my $id   = delete $args{id};

  my $response = $self->_send_request(
    method => 'GET' ,
    url    => _build_url( "issue/$id" , %args ),
  );

  return decode_json( $response->content );
}

=method get_issue_createmeta( %args )

Get the meta data (required and optional fields, etc.) for creating issues.

=cut

sub get_issue_createmeta {
  my $self = shift;

  my %args = @_ ? _expand_args( \@_ ) : ();

  my $response = $self->_send_request(
    method => 'GET' ,
    url    => _build_url( 'issue/createmeta' , %args ),
  );

  return decode_json( $response->content );
}

=method get_issue_transitions( %args )

Get the transitions possible for this issue by the current user.

=cut

sub get_issue_transitions {
  my $self = shift;

  my %args = _expand_args( \@_ , [ 'id' ]);
  my $id   = delete $args{id};

  my $response = $self->_send_request(
    method => 'GET' ,
    url    => _build_url( "issue/$id/transitions" , %args ),
  );

  return decode_json( $response->content );
}

=method get_issue_votes( %args )

Get voters on the issue.

=cut

sub get_issue_votes {
  my $self = shift;

  my %args = _expand_args( \@_ , [ 'id' ]);
  my $id   = delete $args{id};

  my $response = $self->_send_request(
    method => 'GET' ,
    url    => _build_url( "issue/$id/votes", %args ),
  );

  return decode_json( $response->content );
}

=method get_issue_watchers( %args )

Get watchers on the issue.

=cut

sub get_issue_watchers {
  my $self = shift;

  my %args = _expand_args( \@_ , [ 'id' ]);
  my $id   = delete $args{id};

  my $response = $self->_send_request(
    method => 'GET' ,
    url    => _build_url( "issue/$id/watchers" , %args ),
  );

  return decode_json( $response->content );
}

=method get_project( %args )

Get the project for the specifed key.

=cut

sub get_project {
  my $self = shift;

  my %args = _expand_args( \@_ , [ 'key' ]);
  my $key  = delete $args{key};

  my $response = $self->_send_request(
    method => 'GET' ,
    url    => _build_url( "project/$key" , %args ),
  );

  return decode_json( $response->content );
}

=method get_project_versions( %args )

Get the versions for the project with the specified key.

=cut

sub get_project_versions {
  my $self = shift;

  my %args = _expand_args( \@_ , [ 'key' ]);
  my $key  = delete $args{key};

  my $response = $self->_send_request(
    method => 'GET' ,
    url    => _build_url( "project/$key/versions" , %args ),
  );

  return decode_json( $response->content );
}

=method get_version( %args )

Get the version with the specified id.

=cut

sub get_version {
  my $self = shift;

  my %args = _expand_args( \@_ , [ 'id' ]);
  my $id   = delete $args{id};

  my $response = $self->_send_request(
    method => 'GET' ,
    url    => _build_url( "version/$id" , %args ),
  );

  return decode_json( $response->content );
}

=method post_comment( %args )

Post a comment on an issue

=cut

sub post_comment {
  my $self = shift;

  my %args = _expand_args( \@_ , [ 'id' ]);
  my $id   = delete $args{id};

  my $response = $self->_send_request(
    method => 'POST' ,
    url    => _build_url( "issue/$id/comment" ),
    data   => \%args ,
  );

  return $response->is_success;

}

=method search( %args )

Search for issues

=cut

sub search {
  my $self = shift;

  my %args = _expand_args( \@_ , [ 'jql' ]);

  my $response = $self->_send_request(
    method => 'POST' ,
    url    => _build_url( "search" ),
    data   => \%args ,
  );

  my $results = decode_json( $response->content );

  return @{ $results->{issues} };

}

=method unvote_for_issue( %args )

Remove your vote from an issue.

=cut

sub unvote_for_issue {
  my $self = shift;

  my %args = _expand_args( \@_ , [ 'id' ]);
  my $id   = delete $args{id};

  return $self->_send_request(
    method => 'DELETE' ,
    url    => _build_url( "issue/$id/votes" , %args ),
  );
}

=method unwatch_issue( %args )

Remove a watcher from an issue.

=cut

sub unwatch_issue {
  my $self = shift;

  my %args;
  if ( ref $_[0] eq 'HASH' ) {
    %args = %{ $_[0] };
  }
  else { %args = _expand_args( \@_ , [ 'id' ]) }

  my $id   = delete $args{id};
  my $user = delete $args{username} // $self->username;

  return $self->_send_request(
    method => 'DELETE' ,
    url    => _build_url( "issue/$id/watchers?username=$user" , %args ),
  );
}

=method vote_for_issue( %args )

Cast your vote in favor of an issue.

=cut

sub vote_for_issue {
  my $self = shift;

  my %args = _expand_args( \@_ , [ 'id' ]);
  my $id   = delete $args{id};

  return $self->_send_request(
    method => 'POST' ,
    url    => _build_url( "issue/$id/votes" , %args ),
  );
}

=method watch_issue( %args )

Watch an issue. (Or have someone else watch it.)

=cut

sub watch_issue {
  my $self = shift;

  my %args;
  if ( ref $_[0] eq 'HASH' ) {
    %args = %{ $_[0] };
  }
  else { %args = _expand_args( \@_ , [ 'id' ]); }

  my $id   = delete $args{id};
  my $user = delete $args{username} // $self->username;

  return $self->_send_request(
    method => 'POST' ,
    url    => _build_url( "issue/$id/watchers?$user" ),
  );
}

sub _build_url {
  my( $url , %args ) = @_;

  my $query_string;
  if ( %args ) {
    $query_string = join '&' , map { sprintf '%s=%s' , $_ , $args{$_} } keys %args;
  }

  $url .= '?' . $query_string if $query_string;

  return $url;
}

sub _send_request  {
  my( $self , %args ) = @_;

  my $url = join '' , $self->base_url , $self->api_prefix , $args{url};

  my $req = HTTP::Request->new( $args{method} , $url );
  $req->authorization_basic( $self->username , $self->password );
  $req->content_type( 'application/json' );

  if( $args{data} ) {
    my $json = encode_json $args{data};
    $req->content( $json );
  }

  ### FIXME check error and do ... something? on failed request.
  return $self->request( $req );
}


sub _expand_args {
  my( $arg_list_ref , $param_ref ) = @_;

  ### FIXME allow multiple params?
  if ( $param_ref and @$param_ref
       and scalar @$arg_list_ref == 1 and ref $arg_list_ref->[0] ne 'HASH' ) {
      return ( $param_ref->[0] => $arg_list_ref->[0] );
  }
  elsif ( ref $arg_list_ref->[0] eq 'HASH' ) {
    return %{ $arg_list_ref->[0] };
  }
  elsif ( @$arg_list_ref and scalar @$arg_list_ref %2 == 0 ) {
    return @$arg_list_ref;
  }
  else { croak "Inappropriate arguments" }
}

__PACKAGE__->meta->make_immutable;

1;
