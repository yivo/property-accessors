class InstanceProperty extends AbstractProperty
  constructor: (@object, @property, @getter, @setter, @options) ->
    super
    @target = @object
