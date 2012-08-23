environment = ENV['NANOC_ENV']

production = (environment == 'production')
$minify_js = production
$concat_js = $minify_js || production

module Coffee
  def coffee_re
    %r<^/coffee/(.*)/$>
  end

  def coffee_items()
    main = @items.find { |i| i.identifier == '/coffee/main/' }
    coffee_items = @items.select do |i|
      i.identifier =~ coffee_re and i != main
    end + [main]
    return coffee_items
  end

  def src_js()
    coffee_items.map do |i|
      i.identifier.sub coffee_re, '/js/\1.js'
    end
  end
end

include Coffee
