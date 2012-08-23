environment = ENV['NANOC_ENV']

production = (environment == 'production')
$minify_js = production
$concat_js = $minify_js || production

module Coffee
  def coffee_re
    %r<^/coffee/(.*)/$>
  end

  def test_re
    %r<^/coffee/(.*)-spec/$>
  end

  def main_item()
    @items.find { |i| i.identifier == '/coffee/main/' }
  end

  def coffee_items()
    main = main_item
    @items.select do |i|
      i.identifier =~ coffee_re and
      i.identifier !~ test_re and
      i != main
    end
  end

  def test_items()
    @items.select do |i|
      i.identifier =~ test_re
    end
  end

  def src_for_item(item)
    item.identifier.sub coffee_re, '/js/\1.js'
  end

  def script_tag(item)
    src = src_for_item(item)
    "<script src=\"#{src}\"></script>"
  end

  def script_tags(items)
    items.map do |item|
      script_tag item
    end.join ''
  end

end

include Coffee
