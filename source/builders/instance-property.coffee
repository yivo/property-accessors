class InstanceProperty extends AbstractProperty
  constructor: (@object, @property, @getter, @setter, @options) ->
    super
    @target      = @object
    @callbackKey = "#{@property}Callback"

  configureDependencies: ->
    if @target[@callbackKey]
      @object.off(null, @target[@callbackKey])
      delete @target[@callbackKey]

    if @getter and not @options.silent and @options.dependencies?.length > 0
      evaluate """ function fn() {
                 this["__#{@property}"] = null;
                 this["#{@property}"];
               }
           """
      @target[@callbackKey] = fn
      @object.on(dependenciesToEvents(@options.dependencies), fn)
