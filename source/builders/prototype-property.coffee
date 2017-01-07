class PrototypeProperty extends AbstractProperty
  constructor: (@Class, @property, @getter, @setter, @options) ->
    super
    @prototype = @Class.prototype
    @target    = @prototype
