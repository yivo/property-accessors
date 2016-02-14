(function() {
  var extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    hasProp = {}.hasOwnProperty;

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
    var AbstractProperty, ArgumentError, Error, InstanceProperty, PrototypeProperty, ReadonlyPropertyError, comparator, defineProperty, isClass, isFunction, isObject, supportsConst;
    AbstractProperty = (function() {
      function AbstractProperty() {}

      AbstractProperty.prototype.build = function() {};

      AbstractProperty.prototype.defineGetter = function() {
        var fn;
        if (this.getter) {
          if (this.options.memo) {
            eval("fn = (function(computer) {\n       return function fn() {\n         var val = this[\"_" + this.property + "\"];\n         if (val == null) {\n           var ref = this[\"_" + this.property + "\"] = computer.call(this);\n           if (val !== ref) { this.notify(\"change:" + this.property + "\", this, ref, val); }\n           return ref;\n         } else { return val; }\n       }\n     })(this.getter);");
          } else {
            fn = (function(computer) {
              return function() {
                return computer.call(this);
              };
            })(this.getter);
          }
        } else {
          eval(" fn = function() { return this[\"_" + this.property + "\"]; } ");
        }
        return this.metadata[this.property + "Getter"] = fn;
      };

      AbstractProperty.prototype.defineSetter = function() {
        var code;
        code = " function fn(value) {\nvar old = this[\"_" + this.property + "\"];";
        if (this.options.readonly) {
          code += "   if (old != null) {\n  throw new ReadonlyPropertyError(this, \"" + this.property + "\");\n}";
        }
        code += "   if (!comparator(value, old)) {\n    this[\"_" + this.property + "\"] = value;\n    this.notify(\"change:" + this.property + "\", this, value, old);\n  }\n}";
        eval(code);
        this.metadata["_" + this.property + "Setter"] = fn;
        return this.metadata[this.property + "Setter"] = this.setter || fn;
      };

      AbstractProperty.prototype.defineProperty = function() {
        if (!this.target.hasOwnProperty(this.property)) {
          return Object.defineProperty(this.target, this.property, {
            get: this.metadata[this.property + "Getter"],
            set: this.metadata[this.property + "Setter"]
          });
        }
      };

      AbstractProperty.prototype.toEvents = function(deps) {
        return _.map(deps, function(el) {
          return "change:" + el;
        }).join(' ');
      };

      return AbstractProperty;

    })();
    PrototypeProperty = (function(superClass) {
      extend(PrototypeProperty, superClass);

      function PrototypeProperty(Class, property1, getter, setter, options) {
        this.Class = Class;
        this.property = property1;
        this.getter = getter;
        this.setter = setter;
        this.options = options;
        PrototypeProperty.__super__.constructor.apply(this, arguments);
        this.prototype = this.Class.prototype;
        this.target = this.prototype;
        this.metadata = this.Class.reopenObject(METADATA);
        this.initializerKey = "property-accessors:events:" + this.property;
      }

      PrototypeProperty.prototype.build = function() {
        this.defineGetter();
        this.defineSetter();
        this.defineProperty();
        return this.defineCallback();
      };

      PrototypeProperty.prototype.defineCallback = function() {
        var ref;
        this.Class.deleteInitializer(this.initializerKey);
        if (this.getter && this.options.memo && ((ref = this.options.dependencies) != null ? ref.length : void 0) > 0) {
          eval("function fn() {\n  this.on(\"" + (this.toEvents(this.options.dependencies)) + "\", function() {\n    this[\"_" + this.property + "\"] = null;\n    this[\"" + this.property + "\"];\n  });\n}");
          return this.Class.initializer(this.initializerKey, fn);
        }
      };

      return PrototypeProperty;

    })(AbstractProperty);
    InstanceProperty = (function(superClass) {
      extend(InstanceProperty, superClass);

      function InstanceProperty(object1, property1, getter, setter, options) {
        var base;
        this.object = object1;
        this.property = property1;
        this.getter = getter;
        this.setter = setter;
        this.options = options;
        InstanceProperty.__super__.constructor.apply(this, arguments);
        (base = this.object)[METADATA] || (base[METADATA] = {});
        this.metadata = this.object[METADATA];
        this.target = this.object;
        this.callbackKey = this.property + "Callback";
      }

      InstanceProperty.prototype.build = function() {
        this.defineGetter();
        this.defineSetter();
        this.defineProperty();
        return this.defineCallback();
      };

      InstanceProperty.prototype.defineCallback = function() {
        var ref;
        if (this.metadata[this.callbackKey]) {
          this.object.off(null, this.metadata[this.callbackKey]);
          delete this.metadata[this.callbackKey];
        }
        if (this.getter && this.options.memo && ((ref = this.options.dependencies) != null ? ref.length : void 0) > 0) {
          eval(" function fn() {\n  this[\"_" + this.property + "\"] = null;\n  this[\"" + this.property + "\"];\n}");
          this.metadata[this.callbackKey] = fn;
          return this.object.on(this.toEvents(this.options.dependencies), fn);
        }
      };

      return InstanceProperty;

    })(AbstractProperty);
    Error = (function(superClass) {
      extend(Error, superClass);

      function Error() {
        Error.__super__.constructor.call(this, this.message);
        (typeof Error.captureStackTrace === "function" ? Error.captureStackTrace(this, this.name) : void 0) || (this.stack = new Error().stack);
      }

      return Error;

    })(__root__.Error);
    ArgumentError = (function(superClass) {
      extend(ArgumentError, superClass);

      function ArgumentError() {
        this.name = 'ArgumentError';
        this.message = '[PropertyAccessors] Not enough or invalid arguments';
        ArgumentError.__super__.constructor.apply(this, arguments);
      }

      return ArgumentError;

    })(Error);
    ReadonlyPropertyError = (function(superClass) {
      var wasConstructed;

      extend(ReadonlyPropertyError, superClass);

      wasConstructed = _.wasConstructed;

      function ReadonlyPropertyError(object, property) {
        var obj;
        obj = wasConstructed(object) ? object.constructor.name || object : object;
        this.name = 'ReadonlyPropertyError';
        this.message = "[PropertyAccessors] Property " + obj + "#" + property + " is readonly";
        ReadonlyPropertyError.__super__.constructor.apply(this, arguments);
      }

      return ReadonlyPropertyError;

    })(Error);
    supportsConst = (function() {
      try {
        eval('const BLACKHOLE;');
        return true;
      } catch (_error) {
        return false;
      }
    })();
    if (supportsConst) {
      eval("const METADATA = '_' + _.generateID();");
    } else {
      eval("var METADATA = '_' + _.generateID();");
    }
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
    isFunction = _.isFunction, isClass = _.isClass, isObject = _.isObject;
    defineProperty = function(object, property, arg1, arg2) {
      var get, memo, readonly, set;
      memo = false;
      readonly = false;
      switch (arguments.length) {
        case 2:
          break;
        case 3:
          if (isFunction(arg1)) {
            get = arg1;
          } else {
            if (isObject(arg1)) {
              get = arg1.get, set = arg1.set, memo = arg1.memo, readonly = arg1.readonly;
            } else {
              throw new ArgumentError();
            }
          }
          break;
        case 4:
          if (isObject(arg1) && isFunction(arg2)) {
            get = arg2;
            memo = arg1.memo, readonly = arg1.readonly;
          } else {
            throw new ArgumentError();
          }
      }
      if (!isFunction(get)) {
        get = null;
      }
      if (!isFunction(set)) {
        set = null;
      }
      memo = !!memo;
      readonly = !!readonly;
      if (isClass(object)) {
        return new PrototypeProperty(object, property, get, set, {
          memo: memo,
          readonly: readonly
        }).build();
      } else {
        return new InstanceProperty(object, property, get, set, {
          memo: memo,
          readonly: readonly
        }).build();
      }
    };
    return {
      property: defineProperty,
      ArgumentError: ArgumentError,
      ClassMembers: {
        property: function(property) {
          var args, idx, len;
          args = [this];
          len = arguments.length;
          idx = -1;
          while (++idx < len) {
            args.push(arguments[idx]);
          }
          return defineProperty.apply(null, args);
        }
      },
      InstanceMembers: {
        _get: function(property) {
          var name;
          return typeof this[name = "_" + property + "Getter"] === "function" ? this[name]() : void 0;
        },
        _set: function(property, value) {
          var name;
          return typeof this[name = "_" + property + "Setter"] === "function" ? this[name](value) : void 0;
        }
      }
    };
  });

}).call(this);
