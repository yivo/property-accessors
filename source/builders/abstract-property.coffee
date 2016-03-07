class AbstractProperty

  {defineProperty} = Object
  {hasOwnProperty} = Object.prototype

  define: ->
    defineProperty @target, @property,
      get:          @publicGetter()
      set:          @publicSetter()
      enumerable:   yes
      configurable: yes

    if @options.silent
      defineProperty @target, "_#{@property}",
        writable:     yes
        enumerable:   no
        configurable: yes
    else
      defineProperty @target, "_#{@property}",
        get:          @shadowGetter()
        set:          @shadowSetter()
        enumerable:   no
        configurable: yes

      unless hasOwnProperty.call(@target, "__#{@property}")
        defineProperty @target, "__#{@property}",
          enumerable:   no
          writable:     yes
          configurable: no
    @configureDependencies?()
    this

  publicGetter: ->
    if @getter
      if @options.memo
        if typeof @getter is 'string'
          evaluate """ function fn() {
                         if (null == this["_#{@property}"]) { this["_#{@property}"] = this["#{@getter}"](); }
                         return this["_#{@property}"];
                       }
                   """
          fn
        else
          do (computer = @getter, property = @property) ->
            ->
              this["_#{property}"] ?= computer.call(this)
              this["_#{property}"]
      else
        if typeof @getter is 'string'
          evaluate """ function fn() { return this["#{@getter}"](); } """
          fn
        else
          @getter
    else
      evaluate """ function fn() { return this["_#{@property}"]; } """
      fn

  publicSetter: ->
    if @options.readonly
      do (property = @property, Error = ReadonlyPropertyError) ->
        -> throw new Error(this, property)
    else if @setter
      if typeof @setter is 'string'
        evaluate """ function fn(value) { this["#{@setter}"](value); } """
        fn
      else
        @setter
    else
      evaluate """ function fn(value) { this["_#{@property}"] = value; } """
      fn

  shadowGetter: ->
    evaluate """ function fn() { return this["__#{@property}"]; } """
    fn

  shadowSetter: ->
    do (equal = comparator, property = @property) ->
      (x1) ->
        x0 = this["__#{property}"]
        if not equal(x1, x0)
          this["__#{property}"] = x1
          @notify("change:#{property}", this, x1, x0)
        return