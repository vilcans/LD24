
class @Piece
  # speed: units per second
  constructor: ({type, team, speed, onMoveFinished, onNewSquare}) ->
    @type = type ? 'pawn'
    @speed = speed ? 1
    @team = team ? Piece.BLACK
    @onMoveFinished = onMoveFinished ? (piece) ->
    @onNewSquare = onNewSquare ? (piece, oldSquare, newSquare) ->
    @toSquare = null
    @onSquare = null

    # Total number of seconds the current movement takes
    @moveTime = 0

    # Number of seconds into current movement
    @moveProgress = 0

  interpolate: (a, b, factor) ->
    # The length of the ease in/out depends on the total movement length.
    # May need changing.
    t = Math.sin(factor * factor * Math.PI / 2)
    return interpolate(a, b, t)

  getLocation: ->
    if not @square
      throw 'Cannot get position of piece without square'
    if @isMoving()
      factor = @moveProgress / @moveTime
      return @interpolate(@square.location, @toSquare.location, factor)
    else
      @square.location

  setSquare: (board, square) ->
    @board = board
    @onSquare = @square = square
    @toSquare = null

  getCurrentSquare: ->
    if @isMoving()
      factor = @moveProgress / @moveTime
      rowcol = @interpolate(
        {x: @square.column, y: @square.row},
        {x: @toSquare.column, y: @toSquare.row},
        factor
      )
      return @board.getSquare(
        Math.floor(rowcol.y + .5), Math.floor(rowcol.x + .5)
      )
    else
      @square

  move: (toSquare) ->
    if @isMoving()
      throw 'already moving'
    length = distance(toSquare.location, @square.location)
    @moveTime = length / @speed
    @moveProgress = 0
    @onSquare = @square
    @toSquare = toSquare

  isMoving: ->
    return not not @toSquare

  animate: (deltaSeconds) ->
    if not @isMoving()
      return
    @moveProgress += deltaSeconds
    if @moveProgress >= @moveTime
      @square = @toSquare
      @toSquare = null
      @onMoveFinished this
    else
      oldSquare = @onSquare
      newSquare = @getCurrentSquare()
      if newSquare != oldSquare
        @onSquare = newSquare
        #console.log "#{this.toString()} moved from #{oldSquare.toString()} to #{newSquare.toString()}"
        @onNewSquare this, oldSquare, newSquare

  toString: ->
    return "#{@team}_#{@type}"

  getValidMoves: (board) ->
    moves = []

    f = validMovesFunctions[@type]
    if not f
      throw "No move function: #{@type}"
    f(moves, this, @square, board)
    return moves

validMovesFunctions =
  pawn: (moves, piece, square, board) ->
    if piece.team == Piece.WHITE
      board.appendSquaresInDirection moves, square, 1, 0, 1
    else
      board.appendSquaresInDirection moves, square, -1, 0, 1

  rook: (moves, piece, square, board) ->
    board.appendSquaresInDirection moves, square, 1, 0
    board.appendSquaresInDirection moves, square, -1, 0
    board.appendSquaresInDirection moves, square, 0, 1
    board.appendSquaresInDirection moves, square, 0, -1

  bishop: (moves, piece, square, board) ->
    board.appendSquaresInDirection moves, square, 1, 1
    board.appendSquaresInDirection moves, square, 1, -1
    board.appendSquaresInDirection moves, square, -1, 1
    board.appendSquaresInDirection moves, square, -1, -1

  king: (moves, piece, square, board) ->
    board.appendSquaresInDirection moves, square, -1, -1, 1
    board.appendSquaresInDirection moves, square, -1, 0, 1
    board.appendSquaresInDirection moves, square, -1, 1, 1
    board.appendSquaresInDirection moves, square, 0, -1, 1
    board.appendSquaresInDirection moves, square, 0, 0, 1
    board.appendSquaresInDirection moves, square, 0, 1, 1
    board.appendSquaresInDirection moves, square, 1, -1, 1
    board.appendSquaresInDirection moves, square, 1, 0, 1
    board.appendSquaresInDirection moves, square, 1, 1, 1

  knight: (moves, piece, square, board) ->
    board.appendSquaresInDirection moves, square, 2, 1, 1
    board.appendSquaresInDirection moves, square, 2, -1, 1
    board.appendSquaresInDirection moves, square, -2, 1, 1
    board.appendSquaresInDirection moves, square, -2, -1, 1
    board.appendSquaresInDirection moves, square, 1, 2, 1
    board.appendSquaresInDirection moves, square, 1, -2, 1
    board.appendSquaresInDirection moves, square, -1, 2, 1
    board.appendSquaresInDirection moves, square, -1, -2, 1

  queen: (moves, piece, square, board) ->
    validMovesFunctions.rook moves, piece, square, board
    validMovesFunctions.bishop moves, piece, square, board

Piece.BLACK = 'black'
Piece.WHITE = 'white'

class @Square
  constructor: (@row, @column) ->
    # Location in world coordinates
    @location =
      x: @column - 4 + .5
      y: @row - 4 + .5

  toString: ->
    "row #{@row} column #{@column}"

class @Board

  constructor: ->
    @pieces = []
    @squares = []
    for row in [0...8]
      columnSquares = []
      @squares.push columnSquares
      for column in [0...8]
        columnSquares.push new Square(row, column)

  addPiece: (piece, square) ->
    piece.square = square
    piece.board = this
    @pieces.push piece

  removePiece: (pieceToRemove) ->
    for i, p of @pieces
      if p == pieceToRemove
        @pieces.splice i, 1
        return
    throw "Piece not found to remove: #{pieceToRemove}"

  getPieces: ->
    return @pieces

  getPiecesForTeam: (team) ->
    p for p in @pieces when p.team == team

  getSquareOrNull: (row, column) ->
    row = @squares[row]
    if not row
      return null
    sq = row[column]
    if not sq
      return null
    return sq

  getSquare: (row, column) ->
    sq = @getSquareOrNull(row, column)
    if not sq
      throw "No square at row '#{row}', column '#{column}'"
    return sq

  animate: (deltaSeconds) ->
    piecesCopy = @pieces.slice()
    for piece in piecesCopy
      piece.animate deltaSeconds

  # startingSquare will not be included in results
  appendSquaresInDirection: (targetArray, startingSquare, rowDirection, columnDirection, max=1e6) ->
    row = startingSquare.row
    col = startingSquare.column
    while max > 0
      row += rowDirection
      col += columnDirection
      sq = @getSquareOrNull(row, col)
      return if not sq
      targetArray.push sq
      --max
