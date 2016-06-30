class PrototypeProperty extends AbstractProperty
  constructor: (@Class, @property, @getter, @setter, @options) ->
    super
    @prototype      = @Class.prototype
    @target         = @prototype
    @initializerKey = "properties:events:#{@property}"

  configureDependencies: ->
    @Class.deleteInitializer?(@initializerKey)

    if @getter and not @options.silent and @options.dependencies?.length > 0
      @Class.initializer @initializerKey,
        do (property = @property, events = dependenciesToEvents(@options.dependencies)) ->
          ->
            @on events, ->
              this["__#{property}"] = null
              this["#{property}"]
              return
            return