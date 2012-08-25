
class @Piece
  # speed: units per second
  constructor: ({team, speed}) ->
    @speed = speed ? .25
    @team = team ? Piece.BLACK
    @toSquare = null

    # Total number of seconds the current movement takes
    @moveTime = 0

    # Number of seconds into current movement
    @moveProgress = 0

  getLocation: ->
    if not @square
      throw 'Cannot get position of piece without square'
    if @isMoving()
      factor = @moveProgress / @moveTime
      return interpolate(@square.location, @toSquare.location, factor)
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

  getValidMoves: (board) ->
    moves = []
    row = @square.row
    col = @square.column
    loop
      row += 1
      sq = board.getSquareOrNull(row, col)
      break if not sq
      moves.push sq
    return moves

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

  getPieces: ->
    return @pieces

  getPiecesForTeam: (team) ->
    p for p in pieces if p.team == team

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
