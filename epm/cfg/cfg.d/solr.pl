$c->{plugins}{"Screen::Solr"}{params}{disable} = 0;

# If you are running a multicore instance your address will look like:
# http://localhost:8080/solr/core0
$c->{solr_url} = 'http://localhost:8080/solr';

$c->{solr_index_fields} = [
    'title',
];