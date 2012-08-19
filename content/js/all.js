<% for item in @items.select {|i| i.identifier =~ %r{^/coffee/} and i.identifier != '/coffee/main/'} %>
<%= item.compiled_content %>
<% end %>
// MAIN
<% for name in ['/coffee/main/'] %>
<%= @items.find {|i| i.identifier == '/coffee/main/'}.compiled_content %>
<% end %>
