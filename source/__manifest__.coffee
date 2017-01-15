# @include builders/abstract-property.coffee
# @include builders/prototype-property.coffee
# @include builders/instance-property.coffee
# @include api.coffee

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

