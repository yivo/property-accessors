###!
# property-accessors 1.0.13 | https://github.com/yivo/property-accessors | MIT License
###

((factory) ->

  __root__ = 
    # The root object for Browser or Web Worker
    if typeof self is 'object' and self isnt null and self.self is self
      self

    # The root object for Server-side JavaScript Runtime
    else if typeof global is 'object' and global isnt null and global.global is global
      global

    else
      Function('return this')()

  # Asynchronous Module Definition (AMD)
  if typeof define is 'function' and typeof define.amd is 'object' and define.amd isnt null
    define ['lodash'], (_) ->
      __root__.PropertyAccessors = factory(__root__, Object, Error, TypeError, _)

  # Server-side JavaScript Runtime compatible with CommonJS Module Spec
  else if typeof module is 'object' and module isnt null and typeof module.exports is 'object' and module.exports isnt null
    module.exports = factory(__root__, Object, Error, TypeError, require('lodash'))

  # Browser, Web Worker and the rest
  else
    __root__.PropertyAccessors = factory(__root__, Object, Error, TypeError, _)

  # No return value
  return

)((__root__, Object, Error, TypeError, _) ->
  class AbstractProperty
  
    nativeDefineProperty = Object.defineProperty
    {hasOwnProperty}     = Object.prototype
    {isString}           = _
    
    define: ->
      nativeDefineProperty @target, @property,
        get:          @publicGetter()
        set:          @publicSetter()
        enumerable:   yes
        configurable: yes
  
      if @options.silent
        nativeDefineProperty @target, "_#{@property}",
          writable:     yes
          enumerable:   no
          configurable: yes
      else
        nativeDefineProperty @target, "_#{@property}",
          get:          @shadowGetter()
          set:          @shadowSetter()
          enumerable:   no
          configurable: yes
  
        unless hasOwnProperty.call(@target, "__#{@property}")
          nativeDefineProperty @target, "__#{@property}",
            enumerable:   no
            writable:     yes
            configurable: no
      this
  
    publicGetter: ->
      if @getter?
        if @options.memo
          if isString(@getter)
            do (computer = @getter, _property = "_#{@property}") ->
              ->
                this[_property] ?= this[computer]()
                this[_property]
          else
            do (computer = @getter, _property = "_#{@property}") ->
              ->
                this[_property] ?= computer.call(this)
                this[_property]
        else
          if isString(@getter)
            do (computer = @getter) -> -> this[computer]()
          else
            @getter
      else
        do (_property = "_#{@property}") -> -> this[_property]
  
    publicSetter: ->
      if @options.readonly
        do (property = @property, Error = Error) ->
          -> throw new Error("[PropertyAccessors] Property #{this.toString?()}.#{property} is readonly!")
      else if @setter?
        if isString(@getter)
          do (setter = @setter) -> (value) -> this[setter](value); return
        else
          @setter
      else
        do (_property = "_#{@property}") -> (value) -> this[_property] = value; return
  
    shadowGetter: ->
      do (__property = "__#{@property}") -> -> this[__property]
  
    shadowSetter: ->
      do (property = @property, __property = "__#{@property}") ->
        (x1) ->
          x0 = this[__property]
          if not PA.comparator(x1, x0)
            this[__property] = x1
            PA.onPropertyChange(this, property, x1, x0)
          return
  
  class PrototypeProperty extends AbstractProperty
    constructor: (@Class, @property, @getter, @setter, @options) ->
      super
      @prototype = @Class.prototype
      @target    = @prototype
    
    define: ->
      super
      PA.onPrototypePropertyDefined(@Class, @property)
      this
  
  class InstanceProperty extends AbstractProperty
    constructor: (@object, @property, @getter, @setter, @options) ->
      super
      @target = @object
  
    define: ->
      super
      PA.onInstancePropertyDefined(@target, @property)
      this
  
  defineProperty = do ({isFunction, isString, isPlainObject} = _) ->
    isAccessor = (fn) -> isString(fn) or isFunction(fn)
    isClass    = isFunction
  
    (object, property, arg3, arg4) ->
  
      unless 2 <= arguments.length <= 4
        throw new TypeError "[PropertyAccessors] Wrong number of arguments in PropertyAccessors.define() " +
                            "(given #{arguments.length}, expected 2..4)"
      
      unless object?
        throw new TypeError "[PropertyAccessors] Can't define property on null or undefined"
      
      unless isString(property)
        throw new TypeError "[PropertyAccessors] Expected property name to be a string (given #{property})"
  
      #        object  property 
      #          |  |  |   |
      # property this, 'foo'
      if arguments.length is 2
        memo     = false
        readonly = false
  
      else if arguments.length is 3
        #             property
        #        object  |   |  getter
        #          |  |  |   |  |      |
        # property this, 'foo', -> 'baz'
        if isAccessor(arg3)
          get      = arg3
          memo     = false
          readonly = false
          
        #             property
        #        object  |   |  options with getter and setter
        #          |  |  |   |  |                       |
        # property this, 'foo', memo: true, get: -> 'baz'
        else if isPlainObject(arg3)
          {get, set, memo, readonly, silent} = arg3
          
        else
          throw new TypeError "[PropertyAccessors] Expected descriptor to be " +
                              "a property getter (accepts function or function name) " +
                              "or property options as JavaScript object (given #{arg3})"
      
      else if arguments.length is 4
        #             property
        #        object  |   |  options     getter
        #          |  |  |   |  |        |  |      |
        # property this, 'foo', memo: true, -> 'baz'
        if isPlainObject(arg3) and isAccessor(arg4)
          get                      = arg4
          {memo, readonly, silent} = arg3
        else
          throw new TypeError "[PropertyAccessors] Expected descriptor to be combined of two arguments: \n" +
                              "1. property options as JavaScript object (given #{arg3}); \n" +
                              "2. property getter as function or function name (given #{arg4})."
    
      get      = null unless isAccessor(get)
      set      = null unless isAccessor(set)
      memo     = !!memo
      readonly = !!readonly
      options  = {memo, readonly, silent}
  
      if isClass(object)
        new PrototypeProperty(object, property, get, set, options).define()
      else
        new InstanceProperty(object, property, get, set, options).define()
  
  defineComputedProperty = do ({isPlainObject} = _) ->
    ->
      idx  = -1
      len  = arguments.length
      args = []
      args.push(arguments[idx]) while ++idx < len
  
      if len is 3
        #             property
        #        object  |   |  options with getter
        #          |  |  |   |  |                       |
        # computed this, 'foo', memo: true, get: -> 'bar'
        if isPlainObject(arg = args.pop())
          arg.readonly = true
          arg.silent   = true
          
        #             property
        #        object  |   |  getter
        #          |  |  |   |  |      |
        # computed this, 'foo', -> 'bar'
        else
          args.push(memo: false, readonly: true, silent: true)
          
        args.push(arg)
  
      #             property              getter
      #        object  |   |  options     |      |
      #          |  |  |   |  |        |
      # computed this, 'foo', memo: true, -> 'bar'
      else if len is 4
        if isPlainObject(args[2])
          args[2].readonly = true
          args[2].silent   = true
      
      defineProperty.apply(null, args)
  
  
  PA = 
    VERSION:    '1.0.13'
    define:     defineProperty
    computed:   defineComputedProperty
    comparator: _.isEqual
    
    onInstancePropertyDefined:  (object, property) ->
    onPrototypePropertyDefined: (Class, property) ->
    onPropertyChange:           (object, property, newvalue, oldvalue) ->
    
    InstanceMembers: {}
    
    ClassMembers:
      property: do ({isString} = _) ->
        ->
          idx   = -1
          len   = arguments.length
          props = []
          rest  = []
  
          while ++idx < len and isString(arguments[idx])
            props.push(arguments[idx])
          
          --idx
          while ++idx < len
            rest.push(arguments[idx])
            
          for prop in props
            defineProperty.apply(null, [this].concat(prop, rest))
          this
          
      computed: ->
        idx  = -1
        len  = arguments.length
        args = []
        args.push(arguments[idx]) while ++idx < len
        defineComputedProperty.apply(null, [this].concat(args))
        this
)