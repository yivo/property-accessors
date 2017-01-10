describe 'Memoized property', ->
  class Base
    @include PropertyAccessors
    @include PublisherSubscriber
    
  it 'invokes computer only when value is null or undefined', ->
    calls = 0
    class Foo extends Base
      @property 'bar', memo: true, -> ++calls

    foo = new Foo()
    expect(foo.bar).toBe(1)
    expect(foo.bar).toBe(1)
    
    foo.bar = null
    expect(foo.bar).toBe(2)
    expect(foo.bar).toBe(2)

    foo.bar = undefined 
    expect(foo.bar).toBe(3)
    expect(foo.bar).toBe(3)

  it 'correctly emits events', ->
    calls  = 0
    events = 0
    class Foo extends Base
      @property 'bar', memo: true, -> ++calls

    foo = new Foo()
    foo.on 'change:bar', -> ++events

    foo.bar
    foo.bar
    expect(events).toBe(1)
      
    foo.bar = null
    foo.bar = null
    expect(events).toBe(2)

    foo.bar
    foo.bar
    expect(events).toBe(3)

  it 'throws when readonly set to true', ->
    class Foo extends Base
      @property 'bar', memo: true, readonly: true, -> 'baz'
    
    foo = new Foo()
    expect(-> foo.bar = 0).toThrow()

  it 'returns new value if property changes during get', ->
    class Foo extends Base
      @property 'bar', memo: true, -> 'baz'
    
    foo = new Foo()
    foo.on 'change:bar', -> foo.bar = 'qux'
    expect(foo.bar).toBe('qux')
