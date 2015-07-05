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
    getterName        = API.getterName(property)
    privateGetterName = API.privateGetterName(property)
  
    privateGetterAPI = (obj, value, opts) ->
      obj[privateGetterName](value, opts)
  
    ->
      this[getterName](privateGetterAPI)
  
  API.createDescriptorSetter = (property) ->
    setterName        = API.setterName(property)
    privateSetterName = API.privateSetterName(property)
  
    privateSetterAPI = (obj, value, opts) ->
      obj[privateSetterName](value, opts)
  
    (value) ->
      this[setterName](value, undefined, privateSetterAPI)
  
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
          (@notify or @trigger)?(changeEvent, this, value, previousValue, options)
      this
  
  API.isEqual = (a, b) ->
    if wasConstructed(a)
      # Custom objects, created with new, compare by strict equality
      a is b
  
    # Other objects compare by value
    else isEqual(a, b)
  
  API.propertyChangeEvent = (property) ->
    'change' + cap(property)
  
  API.privateProperty = (property) ->
    '_' + property
  
  API.previousProperty = (property) ->
    'previous' + cap(property)
  
  API.getterName = (property) ->
    'get' + cap(property)
  
  API.setterName = (property) ->
    'set' + cap(property)
  
  API.privateGetterName = (property) ->
    '__get' + cap(property)
  
  API.privateSetterName = (property) ->
    '__set' + cap(property)
  
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
    privateGetterName = API.privateGetterName(property)
    privateSetterName = API.privateSetterName(property)
  
    # Current public accessors
    staleGetter = if isFunction(object[getterName]) then object[getterName] else null
    staleSetter = if isFunction(object[setterName]) then object[setterName] else null
  
    # Set custom getter or leave stale getter or create new default getter
    object[getterName] = getter or staleGetter or API.createGetter(property)
  
    # Create and set private getter if custom getter given
    object[privateGetterName] ||= API.createGetter(property) if getter
  
    # Set setter
    if readonly
      object[setterName] = API.createGetter(property)
    else if setter is true
      object[setterName] = API.createSetter(property)
    else
      if isFunction(setter)
        object[setterName] = setter
        object[privateSetterName] ||= API.createSetter(property)
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
  API
)