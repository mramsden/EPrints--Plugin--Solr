if ( EPrints::Utils::require_if_exists("Apache::Solr") ) {

    # Usually http://localhost:8080/solr/
    $c->{solr_url} = 'http://localhost:8080/solr';

    # Leave blank for single core
    $c->{solr_core} = '';

    $c->{solr_index_fields} = [ 'title', ];
}    # End of require_if_exists

