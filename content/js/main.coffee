$(document).ready ->
  if not Detector.webgl
    Tracking.trackEvent 'webgl', 'nodetect', nonInteraction: true
    $('.loading').hide()
    $('#game').hide()
    Detector.addGetWebGLMessage
      parent: document.getElementById('errors')
  else
    Tracking.trackEvent 'webgl', 'available', nonInteraction: true
    element = document.getElementById('game')
    game = new Game {
      parentElement: element
      eventsElement: document.body
      # gameoverCallback: ->
      #   Tracking.trackEvent 'game', 'over'
      #   $('#gameover').show()
    }
    window.game = game
    game.init ->
      console.log 'Game initialized!'
      #$('.loading').hide()
      #$('.ingame').show()
      Tracking.trackEvent 'game', 'start'
      game.start()

      match = /#(\d+)/.exec(window.location.hash)
      if match
        level = parseInt(match[1])
      else
        level = 1
      game.startLevel level

@reportError = (e) ->
  console.error e
  Tracking.trackEvent 'error', 'exception',
    label: "#{e}"
    nonInteraction: true
  alert "Got error: #{e}"

# Get system time in seconds since the epoch
if Date.now
  @getSystemTime = ->
    Date.now() / 1000
else
  @getSystemTime = ->
    +(new Date) / 1000
