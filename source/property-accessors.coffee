{wasConstructed, isEqual, isFunction, isString} = _

cap = (s) ->
  s.charAt(0).toUpperCase() + s.slice(1)

getClassName = (object) ->
  if isFunction(object)
    object.name
  else
    object?.constructor?.name or object?.toString?()

API = {}

API.createDescriptorGetter = (property) ->
  getterName = API.getterName(property)
  ->
    this[getterName]()

API.createDescriptorSetter = (property) ->
  setterName = API.setterName(property)
  (value) ->
    this[setterName](value)

API.createGetter = (property) ->
  privateProperty = API.privateProperty(property)
  ->
    this[privateProperty]

API.createSetter = (property) ->
  privateProperty  = API.privateProperty(property)
  previousProperty = API.previousProperty(property)
  previousProperty = API.privateProperty(previousProperty)
  changeEvent      = API.propertyChangeEvent(property)

  (value, options) ->
    # Get current value by accessing getter not directly
    previousValue = this[property]

    unless API.isEqual(value, previousValue)
      this[previousProperty] = previousValue
      this[privateProperty]  = value
      if options isnt false and options?.silent isnt true
        @notify?(changeEvent, this, value, previousValue, options)
    this

API.isEqual = (a, b) ->
  if wasConstructed(a)
    # Custom objects, created with new, compare by strict equality
    a is b

  # Other objects compare by value
  else isEqual(a, b)

API.propertyChangeEvent = (property) ->
  property + 'Change'

API.privateProperty = (property) ->
  '_' + property

API.previousProperty = (property) ->
  'previous' + cap(property)

API.getterName = (property) ->
  'get' + cap(property)

API.setterName = (property) ->
  'set' + cap(property)

API.defaultGetterName = (property) ->
  'defaultGet' + cap(property)

API.defaultSetterName = (property) ->
  'defaultSet' + cap(property)

mapAccessorByNameFailed = (object, property, type, key, value) ->
  throw new Error "
      Failed to create property '#{property}' on #{getClassName(object)}.
      You specified #{type} as a string - '#{key}' but mapped value by this key
      is not a function. Value - '#{object[key]}'.
      You should move property declaration below the '#{key}'
      or check declaration options for mistakes.
    "

API.property = (object, property, options) ->
  # Support syntax with options
  if not isFunction(options)
    getter = options?.get
    setter = options?.set

  # Support syntax with getter and setter as 3rd and 4th arguments
  else
    getter = options

    # Readonly property if no setter given as 4th arguments
    setter = (arguments.length > 3 and arguments[3]) or false

  # Arguments validation
  if options?.readonly in [true, false] and options?.readonly is !!options?.set
    throw new Error("You can't specify both 'readonly' and 'set' options")

  # Readonly when setter is false. Also supports `readonly` option
  readonly = setter is false or options?.readonly is true

  # Map getter by name
  if isString(key = getter)
    if isFunction(object[key])
      getter = object[key]
    else
      mapAccessorByNameFailed(object, property, 'getter', key)
  else
    getter = null unless isFunction(getter)

  # Map setter by name. Skip boolean values. See description below (at `readonly`)
  if isString(key = setter)
    if isFunction(object[key])
      setter = object[key]
    else
      mapAccessorByNameFailed(object, property, 'setter', key)

  # Public accessors names
  getterName = API.getterName(property)
  setterName = API.setterName(property)

  # Private accessors names
  defaultGetterName = API.defaultGetterName(property)
  defaultSetterName = API.defaultSetterName(property)

  # Current public accessors
  staleGetter = if isFunction(object[getterName]) then object[getterName] else null
  staleSetter = if isFunction(object[setterName]) then object[setterName] else null

  # Set custom getter or leave stale getter or create new default getter
  object[getterName] = getter or staleGetter or API.createGetter(property)

  # Create and set private getter if custom getter given
  object[defaultGetterName] ||= API.createGetter(property) if getter

  # Set setter
  if readonly
    object[setterName] = API.createGetter(property)
  else if setter is true
    object[setterName] = API.createSetter(property)
  else
    if isFunction(setter)
      object[setterName] = setter
      object[defaultSetterName] ||= API.createSetter(property)
    else
      object[setterName] = staleSetter or API.createSetter(property)

  unless object.hasOwnProperty(property)
    Object.defineProperty(object, property,
      get: API.createDescriptorGetter(property)
      set: API.createDescriptorSetter(property)
    )
    previousProperty = API.previousProperty(property)
    Object.defineProperty(object, previousProperty,
      get: API.createGetter(previousProperty)
    )

  API

Object.defineProperty Function::, 'property',
  value: (property, options) ->
    API.property(this.prototype, property, options)