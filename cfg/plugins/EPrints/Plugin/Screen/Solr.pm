package EPrints::Plugin::Screen::Solr;

use EPrints::Plugin::Screen;

@ISA = ( 'EPrints::Plugin::Screen' );

use strict;

sub new
{
	my( $class, %params ) = @_;

	my $self = $class->SUPER::new( %params );

	$self->{actions} = [ qw/ ping / ];

	$self->{appears} = [
		{
			place => 'key_tools',
			position => 250,
		},			
	];

	return $self;
}

sub render
{
	my( $self ) = @_;

	my $session = $self->{session};

	my $frag = $session->make_doc_fragment;

	my $div = $session->make_element( 'div', style => 'text-align: center;' );
	$frag->appendChild( $div );

	my %buttons = (
		'ping' => $self->phrase( 'ping' ),
	);

	my $form = $session->render_input_form(
		buttons => \%buttons,
		hidden_fields => {
			screen => $self->{processor}->{screenid},
		},
	);

	$div->appendChild( $form );

	return $frag;
}

sub allow_ping
{
	my( $self ) = @_;

	my $current_user = $self->{session}->current_user;

	return 0 unless( defined $current_user );

	return $current_user->get_type eq 'admin';
}

sub action_ping
{
	my( $self ) = @_;

	my $solr = new EPrints::Plugin::Solr( session => $self->{session} );

	if( $solr->ping )
	{
		$self->{processor}->add_message( 'message', 
			$self->html_phrase( 'site_responded', url =>	$self->{session}->make_text( $solr->url ) ) );
	}
	else
	{
		$self->{processor}->add_message( 'error',
			$self->html_phrase( 'site_no_response', url => $self->{session}->make_text( $solr->url ) ) );
	}		
}
1;
