(function() {
  (function(root, factory) {
    if (typeof define === 'function' && define.amd) {
      define(['lodash'], function(_) {
        return root.PropertyAccessors = factory(root, _);
      });
    } else if (typeof module === 'object' && typeof module.exports === 'object') {
      module.exports = factory(root, require('lodash'));
    } else {
      root.PropertyAccessors = factory(root, root._);
    }
  })(this, function(root, _) {
    var createAccessor, createReader, createWriter, get, isFunction;
    isFunction = _.isFunction;
    get = function(obj, path) {
      var _obj, i, j, len, prop;
      _obj = this;
      len = path.length;
      i = -1;
      j = 0;
      while (++i <= len && (_obj != null)) {
        if (i === len || path[i] === '.') {
          if (j > 0) {
            prop = path.slice(i - j, i);
            _obj = typeof _obj[prop] === 'function' ? _obj[prop]() : _obj[prop];
            if (_obj == null) {
              return _obj;
            }
            j = 0;
          }
        } else {
          ++j;
        }
      }
      if (i > 0) {
        return _obj;
      }
    };
    createAccessor = function(klass, name) {};
    createWriter = function(klass, name) {};
    createReader = function(klass, name) {
      var base, prop;
      prop = '_' + name;
      return (base = klass.prototype)[name] || (base[name] = function() {
        return this[prop];
      });
    };
    return {
      InstanceMembers: {
        get: function(path) {
          return get(this, path);
        },
        set: function(path, val) {
          var i, obj, prop;
          i = path.lastIndexOf('.');
          if (i > -1) {
            obj = get(this, path.slice(0, i));
            prop = path.slice(i + 1);
          } else {
            obj = this;
            prop = path;
          }
          if (obj != null) {
            if (typeof obj[prop] === 'function') {
              switch (arguments.length - 2) {
                case 0:
                  obj[prop](val);
                  break;
                case 1:
                  obj[prop](val, arguments[3]);
                  break;
                case 2:
                  obj[prop](val, arguments[3], arguments[4]);
                  break;
                case 3:
                  obj[prop](val, arguments[3], arguments[4], arguments[5]);
                  break;
                case 4:
                  obj[prop](val, arguments[3], arguments[4], arguments[5], arguments[6]);
              }
            } else {
              obj[prop] = val;
            }
          }
          return this;
        }
      },
      ClassMembers: {
        property: function(name, options) {
          var action, readable, writable;
          if (typeof this.param === "function") {
            this.param(name, options);
          }
          readable = (options != null ? options.readable : void 0) !== false;
          writable = (options != null ? options.writable : void 0) !== false;
          action = readable && writable ? createAccessor : readable ? createReader : writable ? createWriter : void 0;
          if (action) {
            action(this, (options != null ? options.as : void 0) || name.slice(name.lastIndexOf('.') + 1));
            if (options != null ? options.alias : void 0) {
              action(this, options.alias);
            }
          }
          return this;
        }
      }
    };
  });

}).call(this);
