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
  # Support for PublisherSubscriber and Backbone
  isNoisy = __root__.PublisherSubscriber?.isNoisy or (options) ->
    options isnt false and options?.silent isnt true
  
  isAccessor = (arg) ->
    typeof arg is 'function' and !!arg.__accessor__
  
  {wasConstructed, isEqual} = _
  
  inlineGet = (path) ->
    obj  = this
    len  = path.length
    i    = -1
    j    = 0
  
    while ++i <= len and obj?
      if i is len or path[i] is '.'
        if j > 0
          prop = path[i - j...i]
          val  = obj[prop]
          obj  = if isAccessor(val) then obj[prop]() else val
          return obj if not obj?
          j = 0
      else ++j
  
    obj if i > 0
  
  inlineSet = (path, val) ->
    i = path.lastIndexOf('.')
  
    if i > -1
      obj  = instanceGet(this, path.slice(0, i))
      prop = path.slice(i + 1)
    else
      obj  = this
      prop = path
  
    if obj?
      if isAccessor(obj[prop])
        switch arguments.length - 2
          when 0 then obj[prop](val)
          when 1 then obj[prop](val, arguments[2])
          when 2 then obj[prop](val, arguments[2], arguments[3])
          when 3 then obj[prop](val, arguments[2], arguments[3], arguments[4])
      else
        obj[prop] = val
    this
  
  instanceGet = (obj, path) ->
    inlineGet.call(obj, path)
  
  instanceSet = (obj, path, val) ->
    switch arguments.length - 3
      when 0
        inlineSet.call(obj, path, val)
      when 1
        inlineSet.call(obj, path, val, arguments[3])
      when 2
        inlineSet.call(obj, path, val, arguments[3], arguments[4])
      when 3
        inlineSet.call(obj, path, val, arguments[3], arguments[4], arguments[5])
  
  createAccessor = (obj, prop, options) ->
    obj[prop] = (nval, options) ->
      props = @_properties
      cval  = props?[prop]
      if arguments.length > 0
        changed = if not props
          nval isnt undefined
        else if wasConstructed(nval)
          nval isnt cval
        else not isEqual(cval, nval)
  
        if changed
          (@_previousProperties ||= {})[prop]  = cval
          (props or (@_properties = {}))[prop] = nval
          notifyPropertyChanged(this, prop, nval, options)
        this
      else cval
    return
  
  notifyPropertyChanged = (obj, prop, value, options) ->
    # Both PublisherSubscriber and Backbone support
    isNoisy(options) and (obj.notify or obj.trigger)?(prop + 'Change', obj, value)
    return
  
  markAccessor = (obj, prop, options) ->
    if typeof obj[prop] is 'function'
      obj[prop].__accessor__ = true
    return
  
  PropertyAccessors =
  
    get: instanceGet
    set: instanceSet
  
    property: (obj, prop, options) ->
      createAccessor(obj, prop, options)
      markAccessor(obj, prop, options)
  
    mark: (obj, prop, options) ->
      markAccessor(obj, prop, options)
  
  PropertyAccessors.InstanceMembers =
    get: inlineGet
    set: inlineSet
  
    properties: ->
      @_properties ||= {}
  
    previousProperties: ->
      @_previousProperties ||= {}
  
    previous: (prop) ->
      @_previousProperties?[prop]
  
  for prop in ['properties', 'previousProperties', 'previous']
    markAccessor(PropertyAccessors.InstanceMembers, prop)
  
  PropertyAccessors.ClassMembers =
  
    property: (prop, options) ->
      PropertyAccessors.property(this.prototype, prop, options)
      this
  PropertyAccessors
)