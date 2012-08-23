describe 'Callbacks', ->
  it 'should call onFinished when all callbacks are finished', ->
    onFinishedCalled = 0
    async = new Callbacks(-> ++onFinishedCalled)
    decorated = async.add(-> 'foo')
    expect(onFinishedCalled).toEqual(0)
    decorated()
    expect(onFinishedCalled).toEqual(1)
