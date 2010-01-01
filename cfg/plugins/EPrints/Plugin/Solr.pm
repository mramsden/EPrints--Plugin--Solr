package EPrints::Plugin::Solr;

use strict;
use warnings;

our @ISA = ( 'EPrints::Plugin' );

our $VERSION = '0.1';

sub new
{
	my( $class, %params ) = @_;

	my $self = $class->SUPER::new( %params );

	EPrints::abort( 'The Solr plugin requires that the \'session\' parameter be defined.\n' ) unless defined( $self->{session} );

	$self->url( 
		$self->{session}->get_repository->get_conf( 'solr_url' ) ) unless( defined $self->{solr_url} );
	
	return $self;
}

sub url
{
	my( $self, $url ) = @_;

	$self->{solr_url} = $url if( defined $url );

	return $self->{solr_url};
}

sub ping
{
	my( $self ) = @_;

	my $ping_url = $self->{solr_url}.'/admin/ping';
	my $response = $self->_query_server( $ping_url );
	my $ping_result = 0;	

	return 0 unless( defined $response );
	
	foreach my $element ( $response->getChildNodes )
	{
		next unless( $element->nodeName eq 'str' );

		foreach my $attribute ( $element->attributes )
		{
			next unless( $attribute->nodeName eq 'name' );

			last unless( $attribute->nodeValue eq 'status' );
			
			if( $element->textContent eq 'OK' )
			{
				$ping_result = 1;
			}

			last;
		} 
	}	

	return $ping_result;
}

sub add_to_index
{
	my( $self, $eprint ) = @_;

	my $ds = $eprint->get_dataset;

	my $xml = $self->{session}->xml;
	
	my $add = $xml->create_element( 'add' );
	my $doc = $xml->create_element( 'doc' );

	my @solr_index_fields = @{$self->{session}->get_repository->get_conf( 'solr_index_fields' )};
	foreach my $solr_index_field ( @solr_index_fields )
	{
		my $value = $eprint->get_value( $solr_index_field );
		if( defined $value )
		{
			if( $ds->get_field( $solr_index_field )->get_property( 'multiple' ) )
			{
				foreach( @{$value} )
				{
					$doc->appendChild( $self->_create_solr_document_field( $solr_index_field, $_ ) );	
				}
			}
			else
			{
				$doc->appendChild( $self->_create_solr_document_field( $solr_index_field, $value ) );
			}
		}
	}

	$add->appendChild( $doc );

	$self->_send_solr_operation( $add );
}

sub _create_solr_document_field
{
	my( $self, $name, $value ) = @_;

	my $xml = $self->{session}->xml;

	my $solr_xml_field = $xml->create_element( 'field', name => $name );
	$solr_xml_field->appendChild( $xml->create_text_node( $value ) );

	return $solr_xml_field;
}

sub _send_solr_operation
{
	my( $self, $op ) = @_;

	my $doc = $self->{session}->xml->create_document_fragment;
	$doc->appendChild( $op );

	print STDERR EPrints::XML::to_string( $doc )."\n";
	
	my $browser = new LWP::UserAgent;
	$browser->agent( __PACKAGE__."/$VERSION" );
	
}

sub _query_server
{
	my( $self, $url ) = @_;

	my $browser = new LWP::UserAgent;
	$browser->agent( __PACKAGE__."/$VERSION" );
	my $server_response = $browser->get( $url );

	print STDERR $server_response->code."\n";	
	return unless( $server_response->code eq 200 );
	
	my $xml = $self->{session}->xml;
	my $doc = $xml->parse_string( $server_response->content );
	my $response = ($doc->getElementsByTagName( 'response' ))[0];

	unless( defined ( $response ) )
	{
		print STDERR 'The Solr plugin did not recieve a valid response from the server. Is Solr running at '.$self->{solr_url}.'?';
		EPrints::XML::dispose( $doc );
	}

	return $response;	
}

package EPrints::DataObj::EPrint;

no warnings;

sub commit
{
	my( $self, $force ) = @_;

	my $success = $self->SUPER::commit( $force );
	if( $success )
	{
		my $solr = new EPrints::Plugin::Solr( session => $self->{session} );
		$solr->add_to_index( $self );
	}

	return $success;
}
1;
