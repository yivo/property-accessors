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

VERSION: '1.0.4'

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
