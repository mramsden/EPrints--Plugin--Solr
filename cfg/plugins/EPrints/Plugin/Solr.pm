package EPrints::Plugin::Solr;

@ISA = ( 'EPrints::Plugin' );

sub new
{
	my( $class, %params ) = @_;

	my $self = $class::SUPER->new( %params );

	# Load any defaults if required.				
	$self->{solr_url} = 
		$self->{session}->get_repository->get_conf( 'solr_url' ) unless( defined $self->{solr_url} );

	return $self;
}

sub ping
{
	
}
1;
