# describe 'Piece', ->
#   piece = null
#   beforeEach ->
#     piece = new Piece

describe 'Square', ->
  ROW = 2
  COLUMN = 3
  square = null
  beforeEach ->
    square = new Square(ROW, COLUMN)

  it 'should have a row', ->
    expect(square.row).toEqual ROW
  it 'should have a column', ->
    expect(square.column).toEqual COLUMN
  it 'should have a location', ->
    expect(square.location).toEqual
      x: COLUMN - 4 + .5
      y: ROW - 4 + .5

describe 'Board', ->
  board = null
  beforeEach ->
    board = new Board

  it 'starts with no pieces', ->
    expect(board.getPieces()).toEqual []

  it 'has squares', ->
    square = board.getSquare(0, 0)
    expect(square).toBeDefined()
    expect(square).not.toBeNull()

  it 'disallows access to squares outside board', ->
    expect(-> board.getSquare(8, 0)).toThrow()
    expect(-> board.getSquare(0, 8)).toThrow()

  describe 'with a piece', ->
    piece = square = null
    ROW = 1
    COLUMN = 2
    SPEED = .25

    beforeEach ->
      piece = new Piece(type='pawn', speed=SPEED)
      square = board.getSquare(ROW, COLUMN)
      board.addPiece piece, square

    it 'can get the pieces', ->
      expect(board.getPieces()).toEqual [piece]

    it 'sets the location of the piece', ->
      loc = piece.getLocation()
      expect(loc).toEqual square.location

    it 'can move the piece', ->
      toSquare = board.getSquare(3, 2)  # moving two rows down
      # Two rows should take 8 seconds as speed .25
      piece.move toSquare
      board.animate 4  # get half way there
      loc = piece.getLocation()
      expect(loc).toEqual piece.interpolate(square.location, toSquare.location, .5)

    it 'can calculate valid moves', ->
      moves = piece.getValidMoves(board)
      expect(moves).toEqual [
        board.getSquare(2, 2),
      ]
