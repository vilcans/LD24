AI_TICK_RATE = .5
MAX_DELTA_TIME = .1  # not greater than AI_TICK_RATE

floor = Math.floor

class @Game
  constructor: ({
    # Element which will get the game canvas as a child
    parentElement,
    # Element to attach events to
    eventsElement
  }) ->
    @parentElement = parentElement
    @eventsElement = eventsElement

    @dragging = false
    @mouseX = @mouseY = 0

    @graphics = new Graphics(parentElement, document.location.hash == '#stats')
    @keyboard = new Keyboard

    @totalTime = 0

    @board = new Board()
    @board.addPiece new Piece(team: Piece.WHITE, speed: 3), @board.getSquare(0, 0)
    @board.addPiece new Piece(speed: 10), @board.getSquare(0, 1)
    @board.addPiece new Piece(speed: 50), @board.getSquare(7, 7)
    @player = @board.getPieces()[0]

    @cameraAngle = 0

    @selection = {row: null, column: null}

  init: (onFinished) ->
    @graphics.loadAssets =>
      #@map = new Map(@graphics.waterImage)
      onFinished()

  start: ->
    @graphics.createScene()
    @graphics.start()

    for piece in @board.getPieces()
      piece.mesh = @graphics.addPiece(piece)

    $(@graphics.renderer.domElement)
      .mousedown(@onMouseDown)
      .click(@onMouseClick)
    $(document.body).mouseup(@onMouseUp)

    document.addEventListener 'mozvisibilitychange', @handleVisibilityChange, false
    if document.mozVisibilityState and document.mozVisibilityState != 'visible'
      console.log 'Not starting animation because game not visible'
    else
      @startAnimation()

    $(document).keydown(@keyboard.onKeyDown).keyup(@keyboard.onKeyUp)
    $(document).keypress(@onKeypress)

  startAnimation: ->
    if @animating
      console.log 'animation already started!'
    else
      console.log 'starting animation'
      @animating = true
      @lastFrame = Date.now()
      requestAnimationFrame @animationFrame

  stopAnimation: ->
    if not @animating
      console.log 'animation not running'
    else
      @animating = false

  handleVisibilityChange: (e) =>
    if document.mozVisibilityState != 'visible'
      @stopAnimation()
    else
      @startAnimation()

  animationFrame: =>
    if @animating
      requestAnimationFrame @animationFrame
      try
        @animate()
      catch e
        reportError e
        @stopAnimation()

  animate: =>
    now = Date.now() / 1000
    deltaTime = Math.min(MAX_DELTA_TIME, now - @lastFrame)

    @board.animate deltaTime
    @totalTime += deltaTime

    #@graphics.boardMesh.rotation = new THREE.Vector3(@totalTime, @totalTime * .1, @totalTime * .01)
    #@graphics.boardMesh.updateMatrix()

    if (floor(now / AI_TICK_RATE) - floor(@lastFrame / AI_TICK_RATE)) != 0
      #console.log 'Time for an AI tick'
      for piece in @board.getPieces()
        if piece.team == Piece.BLACK and not piece.isMoving()
          moves = piece.getValidMoves(@board)
          if moves.length != 0
            move = moves[floor(Math.random() * moves.length)]
            #console.log "Random move: #{move.toString()}"
            piece.move move

    for piece in @board.getPieces()
      pos = piece.getLocation()
      piece.mesh.position.x = pos.x
      piece.mesh.position.y = pos.y

    @lastFrame = now
    @graphics.setCamera @cameraAngle
    @graphics.render()

  makeMove: (square) ->
    valid = @player.getValidMoves(@board)
    if square not in valid
      throw 'not a valid move'
    @player.move square

  onMouseDown: (event) =>
    @dragging = true
    @mouseX = event.clientX
    @mouseY = event.clientY

    $(@eventsElement).mousemove @onMouseDrag
    event.preventDefault()

  onMouseUp: (event) =>
    @dragging = false
    $(@eventsElement).off 'mousemove', @onMouseDrag

  onMouseDrag: (event) =>
    x = event.clientX
    y = event.clientY

    if @dragging
      dx = x - @mouseX
      dy = y - @mouseY
      @graphics.camera.translateZ dy
      @cameraAngle -= dx * .01

    @mouseX = x
    @mouseY = y

    event.preventDefault()

  onKeypress: (event) =>
    c = event.charCode
    if 97 <= c <= 105
      @selection.column = c - 97
    if 49 <= c <= 56
      @selection.row = c - 49
    if @selection.column != null and @selection.row != null
      square = @board.getSquare(@selection.row, @selection.column)
      @selection = {row: null, column: null}
      @makeMove square
