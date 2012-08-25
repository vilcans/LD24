describe 'math', ->
  a = { x: 10, y: 20 }
  b = { x: 30, y: 90 }

  describe 'distance', ->
    it 'should return square root of dx, dy squared', ->
      dist = distance(a, b)
      expect(dist).toBeCloseTo(Math.sqrt(20 * 20 + 70 * 70), 5)

  describe 'interpolate', ->
    it 'should interpolate between two vectors', ->
      r = interpolate(a, b, .25)
      expect(r.x).toBeCloseTo(a.x * .75 + b.x * .25)
      expect(r.y).toBeCloseTo(a.y * .75 + b.y * .25)
