use strict;
use warnings;
use Test::More;
use Test::Exception;
use JIRA::REST;

throws_ok { JIRA::REST::_expand_args }
  qr/Inappropriate arguments/ , 'should die';
throws_ok { JIRA::REST::_expand_args( [] ) }
  qr/Inappropriate arguments/ , 'should die';

is_deeply(
  { JIRA::REST::_expand_args( [ 1 ] , [ 'id' ] ) } ,
  { id => 1 } ,
  'single arg with id argument gets hashed proper'
);

throws_ok { JIRA::REST::_expand_args( [ 1 ] ) }
  qr/Inappropriate arguments/ , 'should die';

is_deeply(
  { JIRA::REST::_expand_args( [ 1 , 2 ] ) } ,
  { 1 => 2 } ,
  'double arg without id argument gets hashed proper'
);

throws_ok { JIRA::REST::_expand_args( [ 1 , 2 ] , [ 'id '] ) }
  qr/Inappropriate arguments/ , 'should die';

is_deeply(
  { JIRA::REST::_expand_args( [{ id => 1 }] ) } ,
  { id => 1 } ,
  'hashref arg without id argument gets hashed proper'
);

is_deeply(
  { JIRA::REST::_expand_args( [{ id => 1 , user => 'foo.bar' }] ) } ,
  { id => 1 , user => 'foo.bar' } ,
  'hashref arg without id argument gets hashed proper'
);

throws_ok { JIRA::REST::_expand_args( [{ id => 2 }] , [ 'id '] ) }
  qr/Inappropriate arguments/ , 'should die';


done_testing;
