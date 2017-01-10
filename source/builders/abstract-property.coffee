class AbstractProperty

  nativeDefineProperty = Object.defineProperty
  {hasOwnProperty}     = Object.prototype
  {isString}           = _
  
  define: ->
    nativeDefineProperty @target, @property,
      get:          @publicGetter()
      set:          @publicSetter()
      enumerable:   yes
      configurable: yes

    if @options.silent
      nativeDefineProperty @target, "_#{@property}",
        writable:     yes
        enumerable:   no
        configurable: yes
    else
      nativeDefineProperty @target, "_#{@property}",
        get:          @shadowGetter()
        set:          @shadowSetter()
        enumerable:   no
        configurable: yes

      unless hasOwnProperty.call(@target, "__#{@property}")
        nativeDefineProperty @target, "__#{@property}",
          enumerable:   no
          writable:     yes
          configurable: no
    this

  publicGetter: ->
    if @getter?
      if @options.memo
        if isString(@getter)
          do (computer = @getter, _property = "_#{@property}") ->
            ->
              this[_property] ?= this[computer]()
              this[_property]
        else
          do (computer = @getter, _property = "_#{@property}") ->
            ->
              this[_property] ?= computer.call(this)
              this[_property]
      else
        if isString(@getter)
          do (computer = @getter) -> -> this[computer]()
        else
          @getter
    else
      do (_property = "_#{@property}") -> -> this[_property]

  publicSetter: ->
    if @options.readonly
      do (property = @property, Error = Error) ->
        -> throw new Error("[PropertyAccessors] Property #{this.toString?()}.#{property} is readonly!")
    else if @setter?
      if isString(@getter)
        do (setter = @setter) -> (value) -> this[setter](value); return
      else
        @setter
    else
      do (_property = "_#{@property}") -> (value) -> this[_property] = value; return

  shadowGetter: ->
    do (__property = "__#{@property}") -> -> this[__property]

  shadowSetter: ->
    do (property = @property, __property = "__#{@property}") ->
      (x1) ->
        x0 = this[__property]
        if not PA.comparator(x1, x0)
          this[__property] = x1
          PA.onPropertyChange(this, property, x1, x0)
        return
