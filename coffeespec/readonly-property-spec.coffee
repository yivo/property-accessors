describe 'Readonly property', ->

  class Base
    @include PropertyAccessors
    @include PublisherSubscriber
  
  it "doesn't throw on get", ->
    class Foo extends Base
      @property 'bar', readonly: true
    
    foo = new Foo()
    expect(-> foo.bar).not.toThrow()

  it 'throws on set', ->
    class Foo extends Base
      @property 'bar', readonly: true

    foo = new Foo()
    expect(-> foo.bar = 'baz').toThrow()
