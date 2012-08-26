
class @Piece
  # speed: units per second
  constructor: ({type, team, speed, onMoveFinished}) ->
    @type = type ? 'pawn'
    @speed = speed ? .25
    @team = team ? Piece.BLACK
    @onMoveFinished = onMoveFinished ? (piece) ->
    @toSquare = null

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

  move: (toSquare) ->
    if @isMoving()
      throw 'already moving'
    length = distance(toSquare.location, @square.location)
    @moveTime = length / @speed
    @moveProgress = 0
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

  getValidMoves: (board) ->
    moves = []
    validMovesFunctions[@type](moves, @square, board)
    return moves

validMovesFunctions =
  pawn: (moves, square, board) ->
    board.appendSquaresInDirection moves, square, 1, 0, 1

  rook: (moves, square, board) ->
    board.appendSquaresInDirection moves, square, 1, 0
    board.appendSquaresInDirection moves, square, -1, 0
    board.appendSquaresInDirection moves, square, 0, 1
    board.appendSquaresInDirection moves, square, 0, -1

  bishop: (moves, square, board) ->
    board.appendSquaresInDirection moves, square, 1, 1
    board.appendSquaresInDirection moves, square, 1, -1
    board.appendSquaresInDirection moves, square, -1, 1
    board.appendSquaresInDirection moves, square, -1, -1

  queen: (moves, square, board) ->
    validMovesFunctions.rook moves, square, board
    validMovesFunctions.bishop moves, square, board


Piece.BLACK = 0
Piece.WHITE = 1

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
    for piece in @pieces
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
