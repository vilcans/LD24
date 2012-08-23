window.Audio =
  play: (name) ->
  	try
  	  tag = document.createElement 'audio'
    	source = document.createElement 'source'
    	source.src = "assets/audio/#{name}.ogg"
    	tag.appendChild source
    	tag.play()
    catch e
      console.log 'play failed:', e
