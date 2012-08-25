@distance = (a, b) ->
  dx = b.x - a.x
  dy = b.y - a.y
  return Math.sqrt(dx * dx + dy * dy)

@interpolate = (a, b, time) ->
  itime = 1 - time
  return {
    x: a.x * itime + b.x * time
    y: a.y * itime + b.y * time
  }
