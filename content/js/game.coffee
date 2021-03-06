MAX_DELTA_TIME = .1

PIECE_RADIUS = .7
PIECE_RADIUS_SQUARED = PIECE_RADIUS * PIECE_RADIUS

floor = Math.floor

IN_GAME = 1
WON = 2
LOST = 3

dieMessages =
  'pawn': 'Ouch! You got <em>pawn</em>ed!'
  'rook': '<em>Rook</em>ie mistake!'
  'bishop': "For God's sake, <em>bishop</em>!"
  'knight': 'Good night, bad <em>knight</em>!'
  'queen': 'Dancing like a fairy, <em>queen</em>!'
  'king': 'The <em>king</em> is dead! Long live the <em>king</em>!'

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

    @setState IN_GAME

  startLevel: (number) ->
    @state = IN_GAME
    console.log "Loading level #{number}"
    Tracking.trackEvent 'game', 'level', {value: number}
    @level = number
    @board = new Board()

    data = levels[number](@board)

    @player = @board.getPiecesForTeam(Piece.WHITE)[0]
    @player.onMoveFinished = (piece) =>
      Audio.play 'move-stop'
      if piece.square.row == 7 and @player.type == 'pawn'
        $('#description').html("<p>Good job, #{@player.type}!")
        Audio.play 'win'
        Tracking.trackEvent 'game', 'win'
        @setState WON
    @player.onNewSquare = (piece, oldSquare, newSquare) =>
      #console.log 'thinking because of new square'
      @think()

    for piece in @board.getPiecesForTeam(Piece.BLACK)
      piece.onMoveFinished = (piece) =>
        @think()

    for piece in @board.getPieces()
      piece.mesh = @graphics.addPiece(piece)

    $('#description').html(data.description)
    @levelStartTime = getSystemTime()

  init: (onFinished) ->
    @graphics.loadAssets =>
      #@map = new Map(@graphics.waterImage)
      onFinished()

  start: ->
    @graphics.createScene()
    @graphics.start()

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
    @totalTime += deltaTime
    @timeInState = now - @stateStartTime

    #@graphics.boardMesh.rotation = new THREE.Vector3(@totalTime, @totalTime * .1, @totalTime * .01)
    #@graphics.boardMesh.updateMatrix()

    if @state == IN_GAME
      @board.animate deltaTime
      @checkCollisions()

    for piece, i in @board.getPieces()
      pos = piece.getLocation()
      piece.mesh.position.x = pos.x
      piece.mesh.position.y = pos.y
      piece.mesh.position.z = Math.max(0, 10 + i - (now - @levelStartTime) * 10)

    @lastFrame = now

    @graphics.animate deltaTime
    @graphics.setCamera @cameraAngle, @cameraDistance
    @graphics.render()

    if @state == WON and @timeInState >= 2
      @startNextLevel()
    if @state == LOST and @timeInState >= 2
      @restartLevel()

  startNextLevel: ->
    for piece in @board.getPieces().slice()
      if piece.team == Piece.BLACK
        @destroyPiece piece
      else
        @removePiece piece
    if @level == levels.length - 1
      Tracking.trackEvent 'game', 'completed'
      @startLevel 1
    else
      @startLevel (@level + 1)

  restartLevel: ->
    for piece in @board.getPieces().slice()
      @removePiece piece
    @startLevel @level

  setState: (state) ->
    @stateStartTime = getSystemTime()
    @timeInState = 0
    @state = state

  think: ->
      playerSquare = @player.onSquare  # what about toSquare? mind reading?
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
        if a.isMoving() and not b.isMoving()
          @destroyPiece b
        else if not a.isMoving() and b.isMoving()
          @destroyPiece a
        else
          if a.moveProgress < b.moveProgress
            @destroyPiece b
          else
            @destroyPiece a

        Audio.play 'destroy'
        # pieces is not valid any more, wait for nest tick to check for more collisions
        return
    return

  destroyPiece: (piece) ->
    @board.removePiece piece
    @graphics.destroyPiece piece.mesh
    if piece.team == Piece.WHITE
      $('#description').html("<p>#{dieMessages[piece.type]}")
      @setState LOST
    else
      if @state == IN_GAME and piece.type == 'king'
        $('#description').html("<p>Death to that king!")
        @setState WON

  removePiece: (piece) ->
    @board.removePiece piece
    @graphics.removePiece piece.mesh

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
