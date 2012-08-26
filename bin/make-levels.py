#!/usr/bin/env python

import yaml
import sys
import json

#levels = yaml.load_all(open('content/levels.yaml'))
levels = yaml.load_all(sys.stdin)

print 'levels = [];'

types = {
    'p': 'pawn',
    'b': 'bishop',
    'r': 'rook',
    'n': 'knight',
    'k': 'king',
    'q': 'queen',
}

for number, data in enumerate(levels, 1):

    print 'levels[%d] = function(board) {' % number

    board = data['board']
    rows = board.split(' ')
    assert len(rows) == 8
    assert all(len(row) == 8 for row in rows)
    rows.reverse()
    for r in rows:
        print '// ' + r

    for r in range(8):
        for c in range(8):
            p = rows[r][c]
            if p == '.':
                continue
            type = types[p.lower()]
            team = 'Piece.WHITE' if p.islower() else 'Piece.BLACK'
            print 'board.addPiece(new Piece({type: %r, team: %s}), board.getSquare(%d, %d));' % (
                type, team, r, c
            )

    print 'return %s;' % json.dumps({
        'description': data['description']
    })
    print '}'
