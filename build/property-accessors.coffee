((root, factory) ->
  if typeof define is 'function' and define.amd
    define ['lodash'], (_) ->
      root.PropertyAccessors = factory(root, _)
  else if typeof module is 'object' && typeof module.exports is 'object'
    module.exports = factory(root, require('lodash'))
  else
    root.PropertyAccessors = factory(root, root._)
  return
)(this, (root, _) ->
  {isFunction} = _
  
  get = (obj, path) ->
    _obj = this
    len  = path.length
    i    = -1
    j    = 0
  
    while ++i <= len and _obj?
      if i is len or path[i] is '.'
        if j > 0
          prop = path[i - j...i]
          _obj = if typeof _obj[prop] is 'function'
            _obj[prop]()
          else
            _obj[prop]
  
          return _obj if not _obj?
          j = 0
      else ++j
  
    _obj if i > 0
  
  createAccessor = (klass, name) ->
  
  createWriter = (klass, name) ->
  
  createReader = (klass, name) ->
    prop = '_' + name
    klass::[name] ||= -> this[prop]
  
  InstanceMembers:
  
    get: (path) ->
      get(this, path)
  
    set: (path, val) ->
      i = path.lastIndexOf('.')
  
      if i > -1
        obj  = get(this, path.slice(0, i))
        prop = path.slice(i + 1)
      else
        obj  = this
        prop = path
  
      if obj?
        if typeof obj[prop] is 'function'
          switch arguments.length - 2
            when 0 then obj[prop](val)
            when 1 then obj[prop](val, arguments[3])
            when 2 then obj[prop](val, arguments[3], arguments[4])
            when 3 then obj[prop](val, arguments[3], arguments[4], arguments[5])
            when 4 then obj[prop](val, arguments[3], arguments[4], arguments[5], arguments[6])
        else
          obj[prop] = val
      this
  
  ClassMembers:
  
    property: (name, options) ->
      # Add support for Strict Parameters Concern
      @param?(name, options)
  
      readable  = options?.readable isnt false
      writable  = options?.writable isnt false
  
      action = if readable and writable
        createAccessor
      else if readable
        createReader
      else if writable
        createWriter
  
      if action
        action(this, options?.as or name.slice(name.lastIndexOf('.') + 1))
        action(this, options.alias) if options?.alias
      this
)