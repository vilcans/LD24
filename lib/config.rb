environment = ENV['NANOC_ENV']

production = (environment == 'production')
$minify_js = production
$concat_js = $minify_js || production
