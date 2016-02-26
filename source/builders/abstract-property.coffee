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
        computer = @getter
        call     = if typeof @getter is 'string'
                     """ this["#{@getter}"]() """
                   else
                     """ computer.call(this) """
        eval """ function fn() {
                   if (null == this["_#{@property}"]) { this["_#{@property}"] = #{call}; }
                   return this["_#{@property}"];
                 }
             """
        fn
      else
        if typeof @getter is 'string'
          eval """ function fn() { return this["#{@getter}"](); } """
          fn
        else
          @getter
    else
      eval """ function fn() { return this["_#{@property}"]; } """
      fn

  publicSetter: ->
    if @options.readonly
      eval """ function fn() { throw new ReadonlyPropertyError(this, "#{@property}"); } """
      fn
    else if @setter
      if typeof @setter is 'string'
        eval """ function fn(value) { this["#{@setter}"](value); } """
        fn
      else
        @setter
    else
      eval """ function fn(value) { this["_#{@property}"] = value; } """
      fn

  shadowGetter: ->
    eval """ function fn() { return this["__#{@property}"]; } """
    fn

  shadowSetter: ->
    equal = comparator
    eval """ function fn(x1) {
               var x0 = this["__#{@property}"];
               if (!equal(x1, x0)) {
                 this["__#{@property}"] = x1;
                 this.notify("change:#{@property}", this, x1, x0);
               }
             }
         """
    fn
