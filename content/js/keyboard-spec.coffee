describe 'keyboard', ->
  beforeEach ->
    @keyboard = new Keyboard

  it 'should report key as up as default', ->
    expect(@keyboard.pressed.left).toBeFalsy()

  it 'should report down key as down', ->
    @keyboard.onKeyDown {keyCode: 65}
    expect(@keyboard.pressed.left).toBeTruthy()

  it 'should report released key as up', ->
    @keyboard.onKeyDown {keyCode: 65}
    @keyboard.onKeyUp {keyCode: 65}
    expect(@keyboard.pressed.left).toBeFalsy()

  it 'should report dropped key as up', ->
    @keyboard.onKeyDown {keyCode: 65}
    @keyboard.drop 'left'
    expect(@keyboard.pressed.left).toBeFalsy()

  it 'should report dropped key as up even after new keydown', ->
    @keyboard.onKeyDown {keyCode: 65}
    @keyboard.drop 'left'
    @keyboard.onKeyDown {keyCode: 65}
    expect(@keyboard.pressed.left).toBeFalsy()

  it 'should report dropped and re-pressed key as down', ->
    @keyboard.onKeyDown {keyCode: 65}
    @keyboard.drop 'left'
    @keyboard.onKeyUp {keyCode: 65}
    @keyboard.onKeyDown {keyCode: 65}
    expect(@keyboard.pressed.left).toBeTruthy()
