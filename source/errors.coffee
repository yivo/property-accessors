class Error extends __root__.Error
  constructor: ->
    super(@message)
    Error.captureStackTrace?(this, @name) or (@stack = new Error().stack)

class ArgumentError extends Error
  constructor: ->
    @name    = 'ArgumentError'
    @message = '[PropertyAccessors] Not enough or invalid arguments'
    super

class ReadonlyPropertyError extends Error

  {wasConstructed} = _

  constructor: (object, property) ->
    obj = if wasConstructed(object)
            object.constructor.name or object
          else
            object

    @name    = 'ReadonlyPropertyError'
    @message = "[PropertyAccessors] Property #{obj}##{property} is readonly"
    super
