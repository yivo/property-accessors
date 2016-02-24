prefixErrorMessage = (msg) -> "[Properties] #{msg}"

class BaseError extends Error
  constructor: ->
    super(@message)
    Error.captureStackTrace?(this, @name) or (@stack = new Error().stack)

class ArgumentError extends BaseError
  constructor: (message) ->
    @name    = 'ArgumentError'
    @message = prefixErrorMessage(message)
    super

class InvalidTargetError extends BaseError
  constructor: ->
    @name    = 'InvalidTargetError'
    @message = prefixErrorMessage("Can't define property on null or undefined")
    super

class InvalidPropertyError extends BaseError
  constructor: (property) ->
    @name    = 'InvalidPropertyError'
    @message = prefixErrorMessage("Invalid property name: '#{property}'")
    super

class ReadonlyPropertyError extends BaseError
  constructor: (object, property) ->
    @name    = 'ReadonlyPropertyError'
    @message = prefixErrorMessage("Property #{identityObject(object)}##{property} is readonly")
    super
