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
