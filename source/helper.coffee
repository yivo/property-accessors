comparator = do ({wasConstructed, isEqual} = _) ->
  (a, b) ->
    if wasConstructed(a)
      # Custom objects, created with new, compare by strict equality
      a is b

    # Other objects compare by value
    else isEqual(a, b)

identityObject = do ({wasConstructed} = _) ->
  (object) ->
    (if wasConstructed(object)
      object.constructor.name or object
    else
      object).toString()
