(function(root, factory) {
  if (typeof define === 'function' && define.amd) {
    define(['lodash', 'yess'], function(_) {
      return root.PropertyAccessors = factory(root, _);
    });
  } else if (typeof module === 'object' && typeof module.exports === 'object') {
    module.exports = factory(root, require('lodash'), require('yess'));
  } else {
    root.PropertyAccessors = factory(root, root._);
  }
})(this, function(__root__, _) {
  var API, cap, isEqual, isFunction, isString, wasConstructed;
  wasConstructed = _.wasConstructed, isEqual = _.isEqual, isFunction = _.isFunction, isString = _.isString;
  cap = function(s) {
    return s.charAt(0).toUpperCase() + s.slice(1);
  };
  API = {};
  API.createDescriptorGetter = function(property) {
    var getterName;
    getterName = API.getterName(property);
    return function() {
      return this[getterName]();
    };
  };
  API.createDescriptorSetter = function(property) {
    var setterName;
    setterName = API.setterName(property);
    return function(value) {
      return this[setterName](value);
    };
  };
  API.createGetter = function(property) {
    var privateProperty;
    privateProperty = API.privateProperty(property);
    return function() {
      return this[privateProperty];
    };
  };
  API.createSetter = function(property) {
    var changeEvent, previousProperty, privateProperty;
    privateProperty = API.privateProperty(property);
    previousProperty = API.previousProperty(property);
    previousProperty = API.privateProperty(previousProperty);
    changeEvent = API.propertyChangeEvent(property);
    return function(value, options) {
      var base, changed, previousValue;
      previousValue = this[property];
      changed = wasConstructed(value) ? value !== previousValue : !isEqual(value, previousValue);
      if (changed) {
        this[previousProperty] = previousValue;
        this[privateProperty] = value;
        if (options !== false && (options != null ? options.silent : void 0) !== true) {
          if (typeof (base = this.notify || this.trigger) === "function") {
            base(changeEvent, this, value, previousValue, options);
          }
        }
        return value;
      } else {
        return previousValue;
      }
    };
  };
  API.propertyChangeEvent = function(property) {
    return 'change' + cap(property);
  };
  API.privateProperty = function(property) {
    return '_' + property;
  };
  API.previousProperty = function(property) {
    return 'previous' + cap(property);
  };
  API.getterName = function(property) {
    return 'get' + cap(property);
  };
  API.setterName = function(property) {
    return 'set' + cap(property);
  };
  API.property = function(object, property, options) {
    var getter, getterName, previousProperty, readonly, setter, setterName, staledGetter, staledSetter;
    if (!isFunction(options)) {
      getter = options != null ? options.get : void 0;
      setter = options != null ? options.set : void 0;
    } else {
      getter = options;
    }
    if (isString(getter)) {
      getter = object[getter];
    }
    if (isString(setter) && object[setter] !== false) {
      setter = object[setter];
    }
    readonly = setter === false || (options != null ? options.writable : void 0) === false;
    if (!isFunction(getter)) {
      getter = null;
    }
    if (readonly || !isFunction(setter)) {
      setter = null;
    }
    getterName = API.getterName(property);
    setterName = API.setterName(property);
    staledGetter = object[getterName];
    staledSetter = object[setterName];
    if (!isFunction(staledGetter)) {
      staledGetter = null;
    }
    if (!isFunction(staledSetter)) {
      staledSetter = null;
    }
    object[getterName] = getter || staledGetter || API.createGetter(property);
    object[setterName] = readonly ? API.createGetter(property) : object[setterName] = setter || staledSetter || API.createSetter(property);
    if (!object.hasOwnProperty(property)) {
      Object.defineProperty(object, property, {
        get: API.createDescriptorGetter(property),
        set: API.createDescriptorSetter(property)
      });
      previousProperty = API.previousProperty(property);
      Object.defineProperty(object, previousProperty, {
        get: API.createGetter(previousProperty)
      });
    }
    return API;
  };
  Object.defineProperty(Function.prototype, 'property', {
    value: function(property, options) {
      return API.property(this.prototype, property, options);
    }
  });
  return API;
});
