class PrototypeProperty extends AbstractProperty
  constructor: (@Class, @property, @getter, @setter, @options) ->
    super
    @prototype      = @Class.prototype
    @target         = @prototype
    @metadata       = @Class.reopenObject(METADATA)
    @initializerKey = "property-accessors:events:#{@property}"

  build: ->
    @defineGetter()
    @defineSetter()
    @defineProperty()
    @defineCallback()

  defineCallback: ->
    @Class.deleteInitializer(@initializerKey)

    if @getter and @options.memo && @options.dependencies?.length > 0
      eval """
        function fn() {
          this.on("#{@toEvents(@options.dependencies)}", function() {
            this["_#{@property}"] = null;
            this["#{@property}"];
          });
        }
           """
      @Class.initializer(@initializerKey, fn)
