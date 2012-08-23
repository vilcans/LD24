describe 'Example', ->
  example = null
  beforeEach ->
    example = new Example

  it 'should return hello', ->
    expect(example.hello()).toEqual 'Hello world!'
