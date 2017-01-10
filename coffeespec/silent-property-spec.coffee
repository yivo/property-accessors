describe 'Silent property', ->
  class Base
    @include PropertyAccessors
    @include PublisherSubscriber
    
  it "doesn't emit events", ->
    class Foo extends Base
      @property 'bar', silent: yes
      
    foo    = new Foo()
    events = 0
    foo.on 'change:bar', -> ++events
    
    foo.bar
    foo.bar = 'baz'
    expect(events).toBe(0)

    foo.bar = 'qux'
    expect(events).toBe(0)
