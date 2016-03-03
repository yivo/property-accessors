class PrototypeProperty extends AbstractProperty
  constructor: (@Class, @property, @getter, @setter, @options) ->
    super
    @prototype      = @Class.prototype
    @target         = @prototype
    @initializerKey = "properties:events:#{@property}"

  configureDependencies: ->
    @Class.deleteInitializer(@initializerKey)

    if @getter and not @options.silent and @options.dependencies?.length > 0
      evaluate """
        function fn() {
          this.on("#{dependenciesToEvents(@options.dependencies)}", function() {
            this["__#{@property}"] = null;
            this["#{@property}"];
          });
        }
           """
      @Class.initializer(@initializerKey, fn)
