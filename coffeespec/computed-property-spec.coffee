describe 'Computed property', ->
  
  class Base
    @include PropertyAccessors
    @include PublisherSubscriber
  
  it 'properly works with default options', ->
    calls = 0
    class Foo extends Base
      @computed 'bar', -> ++calls
    foo = new Foo()
    expect(foo.bar).toBe(1)
    expect(foo.bar).toBe(2)
    expect(-> foo.bar = 0).toThrow()
  
  it 'properly works with default options and getter specified in options', ->
    calls = 0
    class Foo extends Base
      @computed 'bar', get: -> ++calls
    foo = new Foo()
    expect(foo.bar).toBe(1)
    expect(foo.bar).toBe(2)
    expect(-> foo.bar = 0).toThrow()

  it 'properly works with when memo set to true', ->
    calls = 0
    class Foo extends Base
      @computed 'bar', memo: true, -> ++calls
    foo = new Foo()
    expect(foo.bar).toBe(1)
    expect(foo.bar).toBe(1)
    expect(-> foo.bar = 0).toThrow()

  it 'properly works with when memo set to true and getter specified in options', ->
    calls = 0
    class Foo extends Base
      @computed 'bar', memo: true, get: -> ++calls
    foo = new Foo()
    expect(foo.bar).toBe(1)
    expect(foo.bar).toBe(1)
    expect(-> foo.bar = 0).toThrow()

  it 'ignores readonly and silent options', ->
    calls  = 0
    events = 0
    class Foo extends Base
      @computed 'bar', readonly: false, silent: false, -> ++calls
    foo = new Foo()
    foo.on 'change:bar', -> ++events
    expect(foo.bar).toBe(1)
    expect(foo.bar).toBe(2)
    expect(events).toBe(0)
    expect(-> foo.bar = 0).toThrow()

  it 'properly works when defined on instance', ->
    foo   = {}
    calls = 0
    PropertyAccessors.computed(foo, 'bar', -> ++calls)
    expect(foo.bar).toBe(1)
    expect(foo.bar).toBe(2)
    expect(-> foo.bar = 0).toThrow()
    
  it "works fine when it's value is cached", ->
    calls = 0
    class Foo extends Base
      @computed 'bar', ->
        ++calls
        @_bar ?= calls
      
    foo = new Foo()
    expect(foo.bar).toBe(1)
    foo.bar
    foo.bar
    expect(calls).toBe(3)
    expect(foo.bar).toBe(1)
