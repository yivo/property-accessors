# @include builders/abstract-property.coffee
# @include builders/prototype-property.coffee
# @include builders/instance-property.coffee
# @include helper.coffee
# @include errors.coffee
# @include api.coffee

PA = 
  VERSION: '1.0.10'
  
  define: defineProperty

  onInstancePropertyDefined: (object, property) ->
  
  onPrototypePropertyDefined: (Class, property) ->
  
  onPropertyChange: (object, property, newvalue, oldvalue) ->
  
  InstanceMembers: {}
  
  ClassMembers:
  
    property: do ({every, isString} = _) ->
      ->
        args = []
        len  = arguments.length
        idx  = -1
        args.push(arguments[idx]) while ++idx < len
  
        if every(args, isString)
          defineProperty(this, name) for name in args
        else
          props = []
          idx   = -1
          props.push(args[idx]) while ++idx < len and isString(args[idx])
          rest  = args.slice(props.length)
          for prop in props
            defineProperty.apply(null, [this].concat(prop, rest))
        return
