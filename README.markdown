This is a template for a generic web site.

The code is Initializr's version of Bootstrap,
but it uses nanoc for building.

# Set up environment

    gem install nanoc coffee-script uglifier kramdown mime-types therubyracer rack

    apt-get install libyaml-dev
    pip install pyyaml

Do we also need adsf?

# Install new version of the Initializr code

    curl -o initializr.zip 'http://www.initializr.com/builder?mode=less&boot-hero&html5shiv&jquerymin&h5bp-chromeframe&h5bp-analytics&h5bp-iecond&h5bp-favicon&izr-emptyscript&boot-css&boot-scripts'
    unzip initializr.zip -d content
    initializr-cleanup

    cp content/index.html layouts/default.html

Replace most content of the main container div in layouts/default.html with yield:

    <div class="container">
      <%= yield %>
      <hr>

Replace the head in layouts/default.html with:

    <head>
      <meta charset="utf-8">
      <meta http-equiv="X-UA-Compatible" content="IE=edge,chrome=1">

      <title><%= @item[:title] or @site.config[:title] %></title>

      <% if @item[:description] %>
        <meta name="description" content="<%= @item[:description] %>">
      <% end %>
      <% if @site.config[:author] %>
        <meta name="author" content="<%= @site.config[:author] %>">
      <% end %>

      <meta name="viewport" content="width=device-width">

      <link rel="stylesheet" href="/style.css">

      <!--[if lt IE 9]>
      <script src="//html5shiv.googlecode.com/svn/trunk/html5.js"></script>
      <script>window.html5 || document.write('<script src="js/libs/html5.js"><\/script>')</script>
      <![endif]-->
    </head>

Add if statement and use config for Analytics:

    <% if @site.config[:analytics_account] %>
      <script>
        var _gaq=[['_setAccount','<%= @site.config[:analytics_account] %>'],['_trackPageview']];
        (function(d,t){var g=d.createElement(t),s=d.getElementsByTagName(t)[0];
        g.src=('https:'==location.protocol?'//ssl':'//www')+'.google-analytics.com/ga.js';
        s.parentNode.insertBefore(g,s)}(document,'script'));
      </script>
    <% end %>


Remove unneeded files:

    rm content/js/libs/less-1.3.0.min.js

# Install new version of Jasmine

Extract the files to content/test/
Rename jasmine.js to jasmine-core.js
Rename SpecRunner.html to test.html, move up and edit
