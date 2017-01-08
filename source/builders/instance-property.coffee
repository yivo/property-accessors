class InstanceProperty extends AbstractProperty
  constructor: (@object, @property, @getter, @setter, @options) ->
    super
    @target = @object

  define: ->
    super
    PA.onInstancePropertyDefined(@target, @property)
    this
