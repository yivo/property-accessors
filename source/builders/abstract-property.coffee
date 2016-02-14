class AbstractProperty

  build: ->

  defineGetter: ->
    if @getter
      if @options.memo
        eval """
          fn = (function(computer) {
                 return function fn() {
                   var val = this["_#{@property}"];
                   if (val == null) {
                     var ref = this["_#{@property}"] = computer.call(this);
                     if (val !== ref) { this.notify("change:#{@property}", this, ref, val); }
                     return ref;
                   } else { return val; }
                 }
               })(this.getter);
             """
      else
        fn = do (computer = @getter) -> -> computer.call(this)
    else
      eval """ fn = function() { return this["_#{@property}"]; } """

    @metadata["#{@property}Getter"] = fn

  defineSetter: ->
    code  = """ function fn(value) {
                  var old = this["_#{@property}"];
            """

    code += """   if (old != null) {
                    throw new ReadonlyPropertyError(this, "#{@property}");
                  }
            """ if @options.readonly

    code += """   if (!comparator(value, old)) {
                    this["_#{@property}"] = value;
                    this.notify("change:#{@property}", this, value, old);
                  }
                }
            """
    eval(code)
    @metadata["_#{@property}Setter"] = fn
    @metadata["#{@property}Setter"]  = @setter or fn

  defineProperty: ->
    unless @target.hasOwnProperty(@property)
      Object.defineProperty @target, @property,
        get: @metadata["#{@property}Getter"]
        set: @metadata["#{@property}Setter"]

  toEvents: (deps) ->
    _.map(deps, (el) -> "change:#{el}").join(' ')
