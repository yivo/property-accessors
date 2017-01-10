require('coffee-concerns')
global.PublisherSubscriber = require('publisher-subscriber')
global.PropertyAccessors   = require('../../build/property-accessors.js')
global.PropertyAccessors.onPropertyChange = (object, property, newvalue, oldvalue) ->
  object.notify?("change:#{property}", newvalue, oldvalue)
