{wasConstructed, isEqual, isFunction, isString} = _

cap = (s) ->
  s.charAt(0).toUpperCase() + s.slice(1)

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

    changed = if wasConstructed(value)
      # Custom objects, created with new, compare by strict equality
      value isnt previousValue

      # Other objects compare by value
    else !isEqual(value, previousValue)

    if changed
      this[previousProperty] = previousValue
      this[privateProperty]  = value
      if options isnt false and options?.silent isnt true
        (@notify or @trigger)?(changeEvent, this, value, previousValue, options)
      value
    else
      previousValue

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

API.property = (object, property, options) ->
  if not isFunction(options)
    getter = options?.get
    setter = options?.set
  else
    getter = options

  getter       = object[getter] if isString(getter)
  setter       = object[setter] if isString(setter) and object[setter] isnt false
  readonly     = setter is false or options?.writable is false

  getter       = null unless isFunction(getter)
  setter       = null if readonly or not isFunction(setter)

  getterName   = API.getterName(property)
  setterName   = API.setterName(property)

  staledGetter = object[getterName]
  staledSetter = object[setterName]
  staledGetter = null unless isFunction(staledGetter)
  staledSetter = null unless isFunction(staledSetter)

  object[getterName] = getter or staledGetter or API.createGetter(property)

  object[setterName] = if readonly
    API.createGetter(property)
  else
    object[setterName] = setter or staledSetter or API.createSetter(property)

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