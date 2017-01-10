describe 'Default property', ->

  class Base
    @include PropertyAccessors
    @include PublisherSubscriber
  
  it 'gets and sets value correctly', ->
    class Foo extends Base
      @property 'bar'
      
    foo = new Foo()
    expect(foo.bar).toBe(undefined)
    foo.bar = 'baz'
    expect(foo.bar).toBe('baz')

  it 'correctly emits events', ->
    class Foo extends Base
      @property 'bar'
    
    foo    = new Foo()
    events = 0
    foo.on 'change:bar', -> ++events

    expect(events).toBe(0)
    
    foo.bar = 'baz'
    expect(events).toBe(1)
    
    foo.bar = 'baz'
    expect(events).toBe(1)
    
    foo.bar = 'qux'
    expect(events).toBe(2)

  it 'emits events when value set to falsy', ->
    class Foo extends Base
      @property 'bar'

    foo    = new Foo()
    events = 0
    foo.on 'change:bar', -> ++events

    foo.bar = 'baz'
    expect(events).toBe(1)
    expect(foo.bar).toBe('baz')
    
    foo.bar = null
    expect(events).toBe(2)
    expect(foo.bar).toBe(null)

  it 'returns old value if property changes during get', ->
    class Foo extends Base
      @property 'bar', -> @_bar ?= 'baz'

    foo = new Foo()
    foo.on 'change:bar', -> foo.bar = 'qux'
    expect(foo.bar).toBe('baz')
