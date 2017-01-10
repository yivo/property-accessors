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
