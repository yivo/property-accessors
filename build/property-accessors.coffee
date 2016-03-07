((factory) ->

  # Browser and WebWorker
  root = if typeof self is 'object' and self?.self is self
    self

  # Server
  else if typeof global is 'object' and global?.global is global
    global

  # AMD
  if typeof define is 'function' and define.amd
    define ['yess', 'lodash', 'exports'], (_) ->
      root.PropertyAccessors = factory(root, Object, Error, eval, _)

  # CommonJS
  else if typeof module is 'object' and module isnt null and
          module.exports? and typeof module.exports is 'object'
    module.exports = factory(root, Object, Error, eval, require('yess'), require('lodash'))

  # Browser and the rest
  else
    root.PropertyAccessors = factory(root, Object, Error, eval, root._)

  # No return value
  return

)((__root__, Object, Error, evaluate, _) ->
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
  
  comparator = do ({wasConstructed, isEqual} = _) ->
    (a, b) ->
      if wasConstructed(a)
        # Custom objects, created with new, compare by strict equality
        a is b
  
      # Other objects compare by value
      else isEqual(a, b)
  
  dependenciesToEvents = (dependencies) ->
    results = []
    for el in dependencies
      results.push "change:#{el}"
    results.join(' ')
  
  identityObject = do ({wasConstructed} = _) ->
    (object) ->
      (if wasConstructed(object)
        object.constructor.name or object
      else
        object).toString()
  
  prefixErrorMessage = (msg) -> "[Properties] #{msg}"
  
  class BaseError extends Error
    constructor: ->
      super(@message)
      Error.captureStackTrace?(this, @name) ? (@stack = new Error().stack)
  
  class ArgumentError extends BaseError
    constructor: (message) ->
      @name    = 'ArgumentError'
      @message = prefixErrorMessage(message)
      super
  
  class InvalidTargetError extends BaseError
    constructor: ->
      @name    = 'InvalidTargetError'
      @message = prefixErrorMessage("Can't define property on null or undefined")
      super
  
  class InvalidPropertyError extends BaseError
    constructor: (property) ->
      @name    = 'InvalidPropertyError'
      @message = prefixErrorMessage("Invalid property name: '#{property}'")
      super
  
  class ReadonlyPropertyError extends BaseError
    constructor: (object, property) ->
      @name    = 'ReadonlyPropertyError'
      @message = prefixErrorMessage("Property #{identityObject(object)}##{property} is readonly")
      super
  
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
  #       @_fullName = fullName
  #     get: -> "#{@firstName} #{@lastName}"
  #     depends: ['firstName', 'lastName']
  
  defineProperty = do ({isFunction, isString, isClass, isObject} = _) ->
    isAccessor = (fn) -> isString(fn) or isFunction(fn)
  
    (object, property, arg1, arg2) ->
  
      throw new InvalidTargetError()           unless object?
      throw new InvalidPropertyError(property) unless isString(property)
  
      memo     = false
      readonly = false
  
      switch arguments.length
        # Signature: 1
        when 2 then break
  
        # Signature: 2, 3, 4, 5, 7
        when 3
          # Signature 4
          if isAccessor(arg1) then get = arg1
  
          # Signature: 2, 3, 5, 7
          else
            if isObject(arg1) then {get, set, memo, readonly, depends, silent} = arg1
            else throw new ArgumentError("Expected object but given #{arg1}")
  
        # Signature: 6
        when 4
          if isObject(arg1) and isAccessor(arg2)
            {memo, readonly, depends, silent} = arg1; get = arg2
          else throw new ArgumentError("Expected object and accessor (function or function name) but given #{arg1} and #{arg2}")
  
        else throw new ArgumentError('Too many arguments given')
  
      get      = null unless isAccessor(get)
      set      = null unless isAccessor(set)
      memo     = !!memo
      readonly = !!readonly
      options  = {memo, readonly, dependencies: depends, silent}
  
      if isClass(object)
        new PrototypeProperty(object, property, get, set, options).define()
      else
        new InstanceProperty(object, property, get, set, options).define()
  
  VERSION: '1.0.6'
  
  define: defineProperty
  
  InstanceMembers: {}
  
  ClassMembers:
  
    property: do ({every, isString} = _) ->
      ->
        args = []
        len  = arguments.length
        idx  = -1
        args.push(arguments[idx]) while ++idx < len
  
        if every(args, (el) -> isString(el))
          defineProperty(this, name) for name in args
        else
          args.unshift(this)
          defineProperty.apply(null, args)
        return
)