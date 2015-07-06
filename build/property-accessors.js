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
  var API, cap, getClassName, isEqual, isFunction, isString, mapAccessorByNameFailed, wasConstructed;
  wasConstructed = _.wasConstructed, isEqual = _.isEqual, isFunction = _.isFunction, isString = _.isString;
  cap = function(s) {
    return s.charAt(0).toUpperCase() + s.slice(1);
  };
  getClassName = function(object) {
    var ref;
    if (isFunction(object)) {
      return object.name;
    } else {
      return (object != null ? (ref = object.constructor) != null ? ref.name : void 0 : void 0) || (object != null ? typeof object.toString === "function" ? object.toString() : void 0 : void 0);
    }
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
      var previousValue;
      previousValue = this[property];
      if (!API.isEqual(value, previousValue)) {
        this[previousProperty] = previousValue;
        this[privateProperty] = value;
        if (options !== false && (options != null ? options.silent : void 0) !== true) {
          if (typeof this.notify === "function") {
            this.notify(changeEvent, this, value, previousValue, options);
          }
        }
      }
      return this;
    };
  };
  API.isEqual = function(a, b) {
    if (wasConstructed(a)) {
      return a === b;
    } else {
      return isEqual(a, b);
    }
  };
  API.propertyChangeEvent = function(property) {
    return property + 'Change';
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
  API.defaultGetterName = function(property) {
    return 'defaultGet' + cap(property);
  };
  API.defaultSetterName = function(property) {
    return 'defaultSet' + cap(property);
  };
  mapAccessorByNameFailed = function(object, property, type, key, value) {
    throw new Error("Failed to create property '" + property + "' on " + (getClassName(object)) + ". You specified " + type + " as a string - '" + key + "' but mapped value by this key is not a function. Value - '" + object[key] + "'. You should move property declaration below the '" + key + "' or check declaration options for mistakes.");
  };
  API.property = function(object, property, options) {
    var defaultGetterName, defaultSetterName, getter, getterName, key, previousProperty, readonly, ref, setter, setterName, staleGetter, staleSetter;
    if (!isFunction(options)) {
      getter = options != null ? options.get : void 0;
      setter = options != null ? options.set : void 0;
    } else {
      getter = options;
      setter = (arguments.length > 3 && arguments[3]) || false;
    }
    if (((ref = options != null ? options.readonly : void 0) === true || ref === false) && (options != null ? options.readonly : void 0) === !!(options != null ? options.set : void 0)) {
      throw new Error("You can't specify both 'readonly' and 'set' options");
    }
    readonly = setter === false || (options != null ? options.readonly : void 0) === true;
    if (isString(key = getter)) {
      if (isFunction(object[key])) {
        getter = object[key];
      } else {
        mapAccessorByNameFailed(object, property, 'getter', key);
      }
    } else {
      if (!isFunction(getter)) {
        getter = null;
      }
    }
    if (isString(key = setter)) {
      if (isFunction(object[key])) {
        setter = object[key];
      } else {
        mapAccessorByNameFailed(object, property, 'setter', key);
      }
    }
    getterName = API.getterName(property);
    setterName = API.setterName(property);
    defaultGetterName = API.defaultGetterName(property);
    defaultSetterName = API.defaultSetterName(property);
    staleGetter = isFunction(object[getterName]) ? object[getterName] : null;
    staleSetter = isFunction(object[setterName]) ? object[setterName] : null;
    object[getterName] = getter || staleGetter || API.createGetter(property);
    if (getter) {
      object[defaultGetterName] || (object[defaultGetterName] = API.createGetter(property));
    }
    if (readonly) {
      object[setterName] = API.createGetter(property);
    } else if (setter === true) {
      object[setterName] = API.createSetter(property);
    } else {
      if (isFunction(setter)) {
        object[setterName] = setter;
        object[defaultSetterName] || (object[defaultSetterName] = API.createSetter(property));
      } else {
        object[setterName] = staleSetter || API.createSetter(property);
      }
    }
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
