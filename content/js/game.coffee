MAX_DELTA_TIME = .1

PIECE_RADIUS = .8
PIECE_RADIUS_SQUARED = PIECE_RADIUS * PIECE_RADIUS

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

    @cameraAngle = 0
    @cameraDistance = 10

    @selection = {row: null, column: null}

  loadLevel: (number) ->
    @board = new Board()

    levels[number](@board)

    @player = @board.getPiecesForTeam(Piece.WHITE)[0]
    @player.onMoveFinished = (piece) =>
      Audio.play 'move-stop'
      @think()

    for piece in @board.getPiecesForTeam(Piece.BLACK)
      piece.onMoveFinished = (piece) =>
        @think()

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
      @lastFrame = getSystemTime()
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
    now = getSystemTime()
    deltaTime = Math.min(MAX_DELTA_TIME, now - @lastFrame)

    @board.animate deltaTime
    @totalTime += deltaTime

    #@graphics.boardMesh.rotation = new THREE.Vector3(@totalTime, @totalTime * .1, @totalTime * .01)
    #@graphics.boardMesh.updateMatrix()

    @checkCollisions()

    for piece in @board.getPieces()
      pos = piece.getLocation()
      piece.mesh.position.x = pos.x
      piece.mesh.position.y = pos.y

    @lastFrame = now
    @graphics.animate deltaTime
    @graphics.setCamera @cameraAngle, @cameraDistance
    @graphics.render()

  think: ->
      playerSquare = @player.square  # what about toSquare? mind reading?
      for piece in @board.getPiecesForTeam(Piece.BLACK)
        if not piece.isMoving()
          moves = piece.getValidMoves(@board)
          for move in moves
            if move == playerSquare
              Audio.play 'move-start'
              piece.move move
              break

  checkCollisions: ->
    pieces = @board.getPieces()
    for a in pieces
      for b in pieces
        if a == b
          continue
        #if not a.isMoving() and not b.isMoving()
        #  continue
        apos = a.getLocation()
        bpos = b.getLocation()
        d = distanceSquared(apos, bpos)
        if d > PIECE_RADIUS_SQUARED
          continue
        @board.removePiece a
        @board.removePiece b
        @graphics.destroyPiece a.mesh
        @graphics.destroyPiece b.mesh

        Audio.play 'destroy'
        # pieces is not valid any more, wait for nest tick to check for more collisions
        return
    return

  makeMove: (square) ->
    valid = @player.getValidMoves(@board)
    if square not in valid
      throw 'not a valid move'
    Audio.play 'move-start'
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
      @cameraDistance += dy
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
