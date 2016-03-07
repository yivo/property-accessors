(function() {
  var extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    hasProp = {}.hasOwnProperty;

  (function(factory) {
    var root;
    root = typeof self === 'object' && (typeof self !== "undefined" && self !== null ? self.self : void 0) === self ? self : typeof global === 'object' && (typeof global !== "undefined" && global !== null ? global.global : void 0) === global ? global : void 0;
    if (typeof define === 'function' && define.amd) {
      define(['yess', 'lodash', 'exports'], function(_) {
        return root.PropertyAccessors = factory(root, Object, Error, eval, _);
      });
    } else if (typeof module === 'object' && module !== null && (module.exports != null) && typeof module.exports === 'object') {
      module.exports = factory(root, Object, Error, eval, require('yess'), require('lodash'));
    } else {
      root.PropertyAccessors = factory(root, Object, Error, eval, root._);
    }
  })(function(__root__, Object, Error, evaluate, _) {
    var AbstractProperty, ArgumentError, BaseError, InstanceProperty, InvalidPropertyError, InvalidTargetError, PrototypeProperty, ReadonlyPropertyError, comparator, defineProperty, dependenciesToEvents, identityObject, prefixErrorMessage;
    AbstractProperty = (function() {
      var defineProperty, hasOwnProperty;

      function AbstractProperty() {}

      defineProperty = Object.defineProperty;

      hasOwnProperty = Object.prototype.hasOwnProperty;

      AbstractProperty.prototype.define = function() {
        defineProperty(this.target, this.property, {
          get: this.publicGetter(),
          set: this.publicSetter(),
          enumerable: true,
          configurable: true
        });
        if (this.options.silent) {
          defineProperty(this.target, "_" + this.property, {
            writable: true,
            enumerable: false,
            configurable: true
          });
        } else {
          defineProperty(this.target, "_" + this.property, {
            get: this.shadowGetter(),
            set: this.shadowSetter(),
            enumerable: false,
            configurable: true
          });
          if (!hasOwnProperty.call(this.target, "__" + this.property)) {
            defineProperty(this.target, "__" + this.property, {
              enumerable: false,
              writable: true,
              configurable: false
            });
          }
        }
        if (typeof this.configureDependencies === "function") {
          this.configureDependencies();
        }
        return this;
      };

      AbstractProperty.prototype.publicGetter = function() {
        if (this.getter) {
          if (this.options.memo) {
            if (typeof this.getter === 'string') {
              evaluate(" function fn() {\n  if (null == this[\"_" + this.property + "\"]) { this[\"_" + this.property + "\"] = this[\"" + this.getter + "\"](); }\n  return this[\"_" + this.property + "\"];\n}");
              return fn;
            } else {
              return (function(computer, property) {
                return function() {
                  var name1;
                  if (this[name1 = "_" + property] == null) {
                    this[name1] = computer.call(this);
                  }
                  return this["_" + property];
                };
              })(this.getter, this.property);
            }
          } else {
            if (typeof this.getter === 'string') {
              evaluate(" function fn() { return this[\"" + this.getter + "\"](); } ");
              return fn;
            } else {
              return this.getter;
            }
          }
        } else {
          evaluate(" function fn() { return this[\"_" + this.property + "\"]; } ");
          return fn;
        }
      };

      AbstractProperty.prototype.publicSetter = function() {
        if (this.options.readonly) {
          return (function(property, Error) {
            return function() {
              throw new Error(this, property);
            };
          })(this.property, ReadonlyPropertyError);
        } else if (this.setter) {
          if (typeof this.setter === 'string') {
            evaluate(" function fn(value) { this[\"" + this.setter + "\"](value); } ");
            return fn;
          } else {
            return this.setter;
          }
        } else {
          evaluate(" function fn(value) { this[\"_" + this.property + "\"] = value; } ");
          return fn;
        }
      };

      AbstractProperty.prototype.shadowGetter = function() {
        evaluate(" function fn() { return this[\"__" + this.property + "\"]; } ");
        return fn;
      };

      AbstractProperty.prototype.shadowSetter = function() {
        return (function(equal, property) {
          return function(x1) {
            var x0;
            x0 = this["__" + property];
            if (!equal(x1, x0)) {
              this["__" + property] = x1;
              this.notify("change:" + property, this, x1, x0);
            }
          };
        })(comparator, this.property);
      };

      return AbstractProperty;

    })();
    PrototypeProperty = (function(superClass) {
      extend(PrototypeProperty, superClass);

      function PrototypeProperty(Class, property1, getter, setter, options1) {
        this.Class = Class;
        this.property = property1;
        this.getter = getter;
        this.setter = setter;
        this.options = options1;
        PrototypeProperty.__super__.constructor.apply(this, arguments);
        this.prototype = this.Class.prototype;
        this.target = this.prototype;
        this.initializerKey = "properties:events:" + this.property;
      }

      PrototypeProperty.prototype.configureDependencies = function() {
        var ref;
        this.Class.deleteInitializer(this.initializerKey);
        if (this.getter && !this.options.silent && ((ref = this.options.dependencies) != null ? ref.length : void 0) > 0) {
          evaluate("function fn() {\n  this.on(\"" + (dependenciesToEvents(this.options.dependencies)) + "\", function() {\n    this[\"__" + this.property + "\"] = null;\n    this[\"" + this.property + "\"];\n  });\n}");
          return this.Class.initializer(this.initializerKey, fn);
        }
      };

      return PrototypeProperty;

    })(AbstractProperty);
    InstanceProperty = (function(superClass) {
      extend(InstanceProperty, superClass);

      function InstanceProperty(object1, property1, getter, setter, options1) {
        this.object = object1;
        this.property = property1;
        this.getter = getter;
        this.setter = setter;
        this.options = options1;
        InstanceProperty.__super__.constructor.apply(this, arguments);
        this.target = this.object;
        this.callbackKey = this.property + "Callback";
      }

      InstanceProperty.prototype.configureDependencies = function() {
        var ref;
        if (this.target[this.callbackKey]) {
          this.object.off(null, this.target[this.callbackKey]);
          delete this.target[this.callbackKey];
        }
        if (this.getter && !this.options.silent && ((ref = this.options.dependencies) != null ? ref.length : void 0) > 0) {
          evaluate(" function fn() {\n  this[\"__" + this.property + "\"] = null;\n  this[\"" + this.property + "\"];\n}");
          this.target[this.callbackKey] = fn;
          return this.object.on(dependenciesToEvents(this.options.dependencies), fn);
        }
      };

      return InstanceProperty;

    })(AbstractProperty);
    comparator = (function(arg) {
      var isEqual, wasConstructed;
      wasConstructed = arg.wasConstructed, isEqual = arg.isEqual;
      return function(a, b) {
        if (wasConstructed(a)) {
          return a === b;
        } else {
          return isEqual(a, b);
        }
      };
    })(_);
    dependenciesToEvents = function(dependencies) {
      var el, i, len1, results;
      results = [];
      for (i = 0, len1 = dependencies.length; i < len1; i++) {
        el = dependencies[i];
        results.push("change:" + el);
      }
      return results.join(' ');
    };
    identityObject = (function(arg) {
      var wasConstructed;
      wasConstructed = arg.wasConstructed;
      return function(object) {
        return (wasConstructed(object) ? object.constructor.name || object : object).toString();
      };
    })(_);
    prefixErrorMessage = function(msg) {
      return "[Properties] " + msg;
    };
    BaseError = (function(superClass) {
      extend(BaseError, superClass);

      function BaseError() {
        var ref;
        BaseError.__super__.constructor.call(this, this.message);
                if ((ref = typeof Error.captureStackTrace === "function" ? Error.captureStackTrace(this, this.name) : void 0) != null) {
          ref;
        } else {
          this.stack = new Error().stack;
        };
      }

      return BaseError;

    })(Error);
    ArgumentError = (function(superClass) {
      extend(ArgumentError, superClass);

      function ArgumentError(message) {
        this.name = 'ArgumentError';
        this.message = prefixErrorMessage(message);
        ArgumentError.__super__.constructor.apply(this, arguments);
      }

      return ArgumentError;

    })(BaseError);
    InvalidTargetError = (function(superClass) {
      extend(InvalidTargetError, superClass);

      function InvalidTargetError() {
        this.name = 'InvalidTargetError';
        this.message = prefixErrorMessage("Can't define property on null or undefined");
        InvalidTargetError.__super__.constructor.apply(this, arguments);
      }

      return InvalidTargetError;

    })(BaseError);
    InvalidPropertyError = (function(superClass) {
      extend(InvalidPropertyError, superClass);

      function InvalidPropertyError(property) {
        this.name = 'InvalidPropertyError';
        this.message = prefixErrorMessage("Invalid property name: '" + property + "'");
        InvalidPropertyError.__super__.constructor.apply(this, arguments);
      }

      return InvalidPropertyError;

    })(BaseError);
    ReadonlyPropertyError = (function(superClass) {
      extend(ReadonlyPropertyError, superClass);

      function ReadonlyPropertyError(object, property) {
        this.name = 'ReadonlyPropertyError';
        this.message = prefixErrorMessage("Property " + (identityObject(object)) + "#" + property + " is readonly");
        ReadonlyPropertyError.__super__.constructor.apply(this, arguments);
      }

      return ReadonlyPropertyError;

    })(BaseError);
    defineProperty = (function(arg) {
      var isAccessor, isClass, isFunction, isObject, isString;
      isFunction = arg.isFunction, isString = arg.isString, isClass = arg.isClass, isObject = arg.isObject;
      isAccessor = function(fn) {
        return isString(fn) || isFunction(fn);
      };
      return function(object, property, arg1, arg2) {
        var depends, get, memo, options, readonly, set, silent;
        if (object == null) {
          throw new InvalidTargetError();
        }
        if (!isString(property)) {
          throw new InvalidPropertyError(property);
        }
        memo = false;
        readonly = false;
        switch (arguments.length) {
          case 2:
            break;
          case 3:
            if (isAccessor(arg1)) {
              get = arg1;
            } else {
              if (isObject(arg1)) {
                get = arg1.get, set = arg1.set, memo = arg1.memo, readonly = arg1.readonly, depends = arg1.depends, silent = arg1.silent;
              } else {
                throw new ArgumentError("Expected object but given " + arg1);
              }
            }
            break;
          case 4:
            if (isObject(arg1) && isAccessor(arg2)) {
              memo = arg1.memo, readonly = arg1.readonly, depends = arg1.depends, silent = arg1.silent;
              get = arg2;
            } else {
              throw new ArgumentError("Expected object and accessor (function or function name) but given " + arg1 + " and " + arg2);
            }
            break;
          default:
            throw new ArgumentError('Too many arguments given');
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
          dependencies: depends,
          silent: silent
        };
        if (isClass(object)) {
          return new PrototypeProperty(object, property, get, set, options).define();
        } else {
          return new InstanceProperty(object, property, get, set, options).define();
        }
      };
    })(_);
    return {
      VERSION: '1.0.6',
      define: defineProperty,
      InstanceMembers: {},
      ClassMembers: {
        property: (function(arg) {
          var every, isString;
          every = arg.every, isString = arg.isString;
          return function() {
            var args, i, idx, len, len1, name;
            args = [];
            len = arguments.length;
            idx = -1;
            while (++idx < len) {
              args.push(arguments[idx]);
            }
            if (every(args, function(el) {
              return isString(el);
            })) {
              for (i = 0, len1 = args.length; i < len1; i++) {
                name = args[i];
                defineProperty(this, name);
              }
            } else {
              args.unshift(this);
              defineProperty.apply(null, args);
            }
          };
        })(_)
      }
    };
  });

}).call(this);
