class InstanceProperty extends AbstractProperty
  constructor: (@object, @property, @getter, @setter, @options) ->
    super
    @object[METADATA] ||= {}
    @metadata        = @object[METADATA]
    @target          = @object
    @callbackKey     = "#{@property}Callback"

  build: ->
    @defineGetter()
    @defineSetter()
    @defineProperty()
    @defineCallback()

  defineCallback: ->
    if @metadata[@callbackKey]
      @object.off(null, @metadata[@callbackKey])
      delete @metadata[@callbackKey]

    if @getter and @options.memo && @options.dependencies?.length > 0
      eval """ function fn() {
                 this["_#{@property}"] = null;
                 this["#{@property}"];
               }
           """
      @metadata[@callbackKey] = fn
      @object.on @toEvents(@options.dependencies), fn
