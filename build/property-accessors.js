
/*!
 * property-accessors 1.0.13 | https://github.com/yivo/property-accessors | MIT License
 */

(function() {
  var extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    hasProp = {}.hasOwnProperty;

  (function(factory) {
    var __root__;
    __root__ = typeof self === 'object' && self !== null && self.self === self ? self : typeof global === 'object' && global !== null && global.global === global ? global : Function('return this')();
    if (typeof define === 'function' && typeof define.amd === 'object' && define.amd !== null) {
      define(['lodash'], function(_) {
        return __root__.PropertyAccessors = factory(__root__, Object, Error, TypeError, _);
      });
    } else if (typeof module === 'object' && module !== null && typeof module.exports === 'object' && module.exports !== null) {
      module.exports = factory(__root__, Object, Error, TypeError, require('lodash'));
    } else {
      __root__.PropertyAccessors = factory(__root__, Object, Error, TypeError, _);
    }
  })(function(__root__, Object, Error, TypeError, _) {
    var AbstractProperty, InstanceProperty, PA, PrototypeProperty, defineComputedProperty, defineProperty;
    AbstractProperty = (function() {
      var hasOwnProperty, isString, nativeDefineProperty;

      function AbstractProperty() {}

      nativeDefineProperty = Object.defineProperty;

      hasOwnProperty = Object.prototype.hasOwnProperty;

      isString = _.isString;

      AbstractProperty.prototype.define = function() {
        nativeDefineProperty(this.target, this.property, {
          get: this.publicGetter(),
          set: this.publicSetter(),
          enumerable: true,
          configurable: true
        });
        if (this.options.silent) {
          nativeDefineProperty(this.target, "_" + this.property, {
            writable: true,
            enumerable: false,
            configurable: true
          });
        } else {
          nativeDefineProperty(this.target, "_" + this.property, {
            get: this.shadowGetter(),
            set: this.shadowSetter(),
            enumerable: false,
            configurable: true
          });
          if (!hasOwnProperty.call(this.target, "__" + this.property)) {
            nativeDefineProperty(this.target, "__" + this.property, {
              enumerable: false,
              writable: true,
              configurable: false
            });
          }
        }
        return this;
      };

      AbstractProperty.prototype.publicGetter = function() {
        if (this.getter != null) {
          if (this.options.memo) {
            if (isString(this.getter)) {
              return (function(computer, _property) {
                return function() {
                  if (this[_property] == null) {
                    this[_property] = this[computer]();
                  }
                  return this[_property];
                };
              })(this.getter, "_" + this.property);
            } else {
              return (function(computer, _property) {
                return function() {
                  if (this[_property] == null) {
                    this[_property] = computer.call(this);
                  }
                  return this[_property];
                };
              })(this.getter, "_" + this.property);
            }
          } else {
            if (isString(this.getter)) {
              return (function(computer) {
                return function() {
                  return this[computer]();
                };
              })(this.getter);
            } else {
              return this.getter;
            }
          }
        } else {
          return (function(_property) {
            return function() {
              return this[_property];
            };
          })("_" + this.property);
        }
      };

      AbstractProperty.prototype.publicSetter = function() {
        if (this.options.readonly) {
          return (function(property, Error) {
            return function() {
              throw new Error("[PropertyAccessors] Property " + (typeof this.toString === "function" ? this.toString() : void 0) + "." + property + " is readonly!");
            };
          })(this.property, Error);
        } else if (this.setter != null) {
          if (isString(this.getter)) {
            return (function(setter) {
              return function(value) {
                this[setter](value);
              };
            })(this.setter);
          } else {
            return this.setter;
          }
        } else {
          return (function(_property) {
            return function(value) {
              this[_property] = value;
            };
          })("_" + this.property);
        }
      };

      AbstractProperty.prototype.shadowGetter = function() {
        return (function(__property) {
          return function() {
            return this[__property];
          };
        })("__" + this.property);
      };

      AbstractProperty.prototype.shadowSetter = function() {
        return (function(property, __property) {
          return function(x1) {
            var x0;
            x0 = this[__property];
            if (!PA.comparator(x1, x0)) {
              this[__property] = x1;
              PA.onPropertyChange(this, property, x1, x0);
            }
          };
        })(this.property, "__" + this.property);
      };

      return AbstractProperty;

    })();
    PrototypeProperty = (function(superClass) {
      extend(PrototypeProperty, superClass);

      function PrototypeProperty(Class1, property1, getter, setter1, options1) {
        this.Class = Class1;
        this.property = property1;
        this.getter = getter;
        this.setter = setter1;
        this.options = options1;
        PrototypeProperty.__super__.constructor.apply(this, arguments);
        this.prototype = this.Class.prototype;
        this.target = this.prototype;
      }

      PrototypeProperty.prototype.define = function() {
        PrototypeProperty.__super__.define.apply(this, arguments);
        PA.onPrototypePropertyDefined(this.Class, this.property);
        return this;
      };

      return PrototypeProperty;

    })(AbstractProperty);
    InstanceProperty = (function(superClass) {
      extend(InstanceProperty, superClass);

      function InstanceProperty(object1, property1, getter, setter1, options1) {
        this.object = object1;
        this.property = property1;
        this.getter = getter;
        this.setter = setter1;
        this.options = options1;
        InstanceProperty.__super__.constructor.apply(this, arguments);
        this.target = this.object;
      }

      InstanceProperty.prototype.define = function() {
        InstanceProperty.__super__.define.apply(this, arguments);
        PA.onInstancePropertyDefined(this.target, this.property);
        return this;
      };

      return InstanceProperty;

    })(AbstractProperty);
    defineProperty = (function(arg1) {
      var isAccessor, isClass, isFunction, isPlainObject, isString;
      isFunction = arg1.isFunction, isString = arg1.isString, isPlainObject = arg1.isPlainObject;
      isAccessor = function(fn) {
        return isString(fn) || isFunction(fn);
      };
      isClass = isFunction;
      return function(object, property, arg3, arg4) {
        var get, memo, options, readonly, ref, set, silent;
        if (!((2 <= (ref = arguments.length) && ref <= 4))) {
          throw new TypeError("[PropertyAccessors] Wrong number of arguments in PropertyAccessors.define() " + ("(given " + arguments.length + ", expected 2..4)"));
        }
        if (object == null) {
          throw new TypeError("[PropertyAccessors] Can't define property on null or undefined");
        }
        if (!isString(property)) {
          throw new TypeError("[PropertyAccessors] Expected property name to be a string (given " + property + ")");
        }
        if (arguments.length === 2) {
          memo = false;
          readonly = false;
        } else if (arguments.length === 3) {
          if (isAccessor(arg3)) {
            get = arg3;
            memo = false;
            readonly = false;
          } else if (isPlainObject(arg3)) {
            get = arg3.get, set = arg3.set, memo = arg3.memo, readonly = arg3.readonly, silent = arg3.silent;
          } else {
            throw new TypeError("[PropertyAccessors] Expected descriptor to be " + "a property getter (accepts function or function name) " + ("or property options as JavaScript object (given " + arg3 + ")"));
          }
        } else if (arguments.length === 4) {
          if (isPlainObject(arg3) && isAccessor(arg4)) {
            get = arg4;
            memo = arg3.memo, readonly = arg3.readonly, silent = arg3.silent;
          } else {
            throw new TypeError("[PropertyAccessors] Expected descriptor to be combined of two arguments: \n" + ("1. property options as JavaScript object (given " + arg3 + "); \n") + ("2. property getter as function or function name (given " + arg4 + ")."));
          }
        }
        if (!isAccessor(get)) {
          get = null;
        }
        if (!isAccessor(set)) {
          set = null;
        }
        memo = !!memo;
        readonly = !!readonly;
        options = {
          memo: memo,
          readonly: readonly,
          silent: silent
        };
        if (isClass(object)) {
          return new PrototypeProperty(object, property, get, set, options).define();
        } else {
          return new InstanceProperty(object, property, get, set, options).define();
        }
      };
    })(_);
    defineComputedProperty = (function(arg1) {
      var isPlainObject;
      isPlainObject = arg1.isPlainObject;
      return function() {
        var arg, args, idx, len;
        idx = -1;
        len = arguments.length;
        args = [];
        while (++idx < len) {
          args.push(arguments[idx]);
        }
        if (len === 3) {
          if (isPlainObject(arg = args.pop())) {
            arg.readonly = true;
            arg.silent = true;
          } else {
            args.push({
              memo: false,
              readonly: true,
              silent: true
            });
          }
          args.push(arg);
        } else if (len === 4) {
          if (isPlainObject(args[2])) {
            args[2].readonly = true;
            args[2].silent = true;
          }
        }
        return defineProperty.apply(null, args);
      };
    })(_);
    return PA = {
      VERSION: '1.0.13',
      define: defineProperty,
      computed: defineComputedProperty,
      comparator: _.isEqual,
      onInstancePropertyDefined: function(object, property) {},
      onPrototypePropertyDefined: function(Class, property) {},
      onPropertyChange: function(object, property, newvalue, oldvalue) {},
      InstanceMembers: {},
      ClassMembers: {
        property: (function(arg1) {
          var isString;
          isString = arg1.isString;
          return function() {
            var i, idx, len, len1, prop, props, rest;
            idx = -1;
            len = arguments.length;
            props = [];
            rest = [];
            while (++idx < len && isString(arguments[idx])) {
              props.push(arguments[idx]);
            }
            --idx;
            while (++idx < len) {
              rest.push(arguments[idx]);
            }
            for (i = 0, len1 = props.length; i < len1; i++) {
              prop = props[i];
              defineProperty.apply(null, [this].concat(prop, rest));
            }
            return this;
          };
        })(_),
        computed: function() {
          var args, idx, len;
          idx = -1;
          len = arguments.length;
          args = [];
          while (++idx < len) {
            args.push(arguments[idx]);
          }
          defineComputedProperty.apply(null, [this].concat(args));
          return this;
        }
      }
    };
  });

}).call(this);
