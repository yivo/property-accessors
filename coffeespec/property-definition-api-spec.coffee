describe 'Property definition API', ->
  
  class Base
    @include PropertyAccessors
    @include PublisherSubscriber
    
  it 'works fine when multiple properties defined in one call with options', ->
    class Foo extends Base
      expect(=> @property 'bar', 'baz', readonly: true).not.toThrow()
      
    foo = new Foo()
    expect(-> foo.bar = 'qux').toThrow()
