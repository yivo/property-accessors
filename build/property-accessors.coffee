((root, factory) ->
  if typeof define is 'function' and define.amd
    define ['lodash', 'yess'], (_) ->
      root.PropertyAccessors = factory(root, _)
  else if typeof module is 'object' && typeof module.exports is 'object'
    module.exports = factory(root, require('lodash'), require('yess'))
  else
    root.PropertyAccessors = factory(root, root._)
  return
)(this, (__root__, _) ->
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
      # if custom getter and no custom getter => setter with exception
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
      @metadata["#{@property}Setter"]  = if @setter
        do (setter = @setter) ->
          (value) -> setter.call(this, value); return
      else fn
  
    defineProperty: ->
      unless @target.hasOwnProperty(@property)
        Object.defineProperty @target, @property,
          get: @metadata["#{@property}Getter"]
          set: @metadata["#{@property}Setter"]
  
    toEvents: (deps) ->
      _.map(deps, (el) -> "change:#{el}").join(' ')
  
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
  
  class Error extends __root__.Error
    constructor: ->
      super(@message)
      Error.captureStackTrace?(this, @name) or (@stack = new Error().stack)
  
  class ArgumentError extends Error
    constructor: ->
      @name    = 'ArgumentError'
      @message = '[PropertyAccessors] Not enough or invalid arguments'
      super
  
  class ReadonlyPropertyError extends Error
  
    {wasConstructed} = _
  
    constructor: (object, property) ->
      obj = if wasConstructed(object)
              object.constructor.name or object
            else
              object
  
      @name    = 'ReadonlyPropertyError'
      @message = "[PropertyAccessors] Property #{obj}##{property} is readonly"
      super
  
  supportsConst = do ->
    try
      eval 'const BLACKHOLE;'
      true
    catch
      false
  
  if supportsConst
    eval """
      const METADATA = '_' + _.generateID();
         """
  else
    eval """
      var METADATA = '_' + _.generateID();
         """
  
  comparator = do ({wasConstructed, isEqual} = _) ->
    (a, b) ->
      if wasConstructed(a)
        # Custom objects, created with new, compare by strict equality
        a is b
  
      # Other objects compare by value
      else isEqual(a, b)
  
  # Signature 1:
  #   property this, 'name'
  #
  # Signature 2:
  #   property this, 'name', set: no
  #
  # Signature 3:
  #   property this, 'name', readonly: yes
  #
  # Signature 4:
  #   property this, 'name', -> 'Tomas'
  #
  # Signature 5:
  #   property this, 'name', get: -> 'Tomas'
  #
  # Signature 6:
  #   property this, 'fullName', depends: ['firstName', 'lastName'], -> "#{@firstName} #{@lastName}"
  #
  # Signature 7:
  #   property this, 'fullName',
  #     set: (fullName) ->
  #       [@firstName, @lastName] = fullName.split(/\s+/)
  #       TODO
  #     get: -> "#{@firstName} #{@lastName}"
  #     depends: ['firstName', 'lastName']
  {isFunction, isClass, isObject} = _
  defineProperty = (object, property, arg1, arg2) ->
    memo     = false
    readonly = false
  
    switch arguments.length
      # Signature: 1
      when 2 then break
  
      # Signature: 2, 3, 4, 5, 7
      when 3
  
        # Signature 4
        if isFunction(arg1)
          get = arg1
  
        # Signature: 2, 3, 5, 7
        else
          if isObject(arg1)
            {get, set, memo, readonly} = arg1
  
          else throw new ArgumentError()
  
      # Signature: 6
      when 4
        if isObject(arg1) and isFunction(arg2)
          get = arg2
          {memo, readonly} = arg1
  
        else throw new ArgumentError()
  
    get      = null unless isFunction(get)
    set      = null unless isFunction(set)
    memo     = !!memo
    readonly = !!readonly
  
    if isClass(object)
      new PrototypeProperty(object, property, get, set, {memo, readonly}).build()
  
    else
      new InstanceProperty(object, property, get, set, {memo, readonly}).build()
  
  property: defineProperty
  
  ArgumentError: ArgumentError
  
  ClassMembers:
  
    property: (property) ->
      args = [this]
      len  = arguments.length
      idx  = -1
      args.push(arguments[idx]) while ++idx < len
      defineProperty.apply(null, args)
  
  InstanceMembers:
  
    _get: (property) -> this["_#{property}"]
    _set: (property, value) -> this[METADATA]["_#{property}Setter"].call(this, value)
  
  
)