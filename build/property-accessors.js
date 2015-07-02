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
  var PropertyAccessors, createAccessor, inlineGet, inlineSet, instanceGet, instanceSet, isAccessor, isEqual, isNoisy, k, len1, markAccessor, notifyPropertyChanged, prop, ref, ref1, wasConstructed;
  isNoisy = ((ref = __root__.PublisherSubscriber) != null ? ref.isNoisy : void 0) || function(options) {
    return options !== false && (options != null ? options.silent : void 0) !== true;
  };
  isAccessor = function(arg) {
    return typeof arg === 'function' && !!arg.__accessor__;
  };
  wasConstructed = _.wasConstructed, isEqual = _.isEqual;
  inlineGet = function(path) {
    var i, j, len, obj, prop, val;
    obj = this;
    len = path.length;
    i = -1;
    j = 0;
    while (++i <= len && (obj != null)) {
      if (i === len || path[i] === '.') {
        if (j > 0) {
          prop = path.slice(i - j, i);
          val = obj[prop];
          obj = isAccessor(val) ? obj[prop]() : val;
          if (obj == null) {
            return obj;
          }
          j = 0;
        }
      } else {
        ++j;
      }
    }
    if (i > 0) {
      return obj;
    }
  };
  inlineSet = function(path, val) {
    var i, obj, prop;
    i = path.lastIndexOf('.');
    if (i > -1) {
      obj = instanceGet(this, path.slice(0, i));
      prop = path.slice(i + 1);
    } else {
      obj = this;
      prop = path;
    }
    if (obj != null) {
      if (isAccessor(obj[prop])) {
        switch (arguments.length - 2) {
          case 0:
            obj[prop](val);
            break;
          case 1:
            obj[prop](val, arguments[2]);
            break;
          case 2:
            obj[prop](val, arguments[2], arguments[3]);
            break;
          case 3:
            obj[prop](val, arguments[2], arguments[3], arguments[4]);
        }
      } else {
        obj[prop] = val;
      }
    }
    return this;
  };
  instanceGet = function(obj, path) {
    return inlineGet.call(obj, path);
  };
  instanceSet = function(obj, path, val) {
    switch (arguments.length - 3) {
      case 0:
        return inlineSet.call(obj, path, val);
      case 1:
        return inlineSet.call(obj, path, val, arguments[3]);
      case 2:
        return inlineSet.call(obj, path, val, arguments[3], arguments[4]);
      case 3:
        return inlineSet.call(obj, path, val, arguments[3], arguments[4], arguments[5]);
    }
  };
  createAccessor = function(obj, prop, options) {
    obj[prop] = function(nval, options) {
      var changed, cval, props;
      props = this._properties;
      cval = props != null ? props[prop] : void 0;
      if (arguments.length > 0) {
        changed = !props ? nval !== void 0 : wasConstructed(nval) ? nval !== cval : !isEqual(cval, nval);
        if (changed) {
          (this._previousProperties || (this._previousProperties = {}))[prop] = cval;
          (props || (this._properties = {}))[prop] = nval;
          notifyPropertyChanged(this, prop, nval, options);
        }
        return this;
      } else {
        return cval;
      }
    };
  };
  notifyPropertyChanged = function(obj, prop, value, options) {
    var base;
    isNoisy(options) && (typeof (base = obj.notify || obj.trigger) === "function" ? base(prop + 'Change', obj, value) : void 0);
  };
  markAccessor = function(obj, prop, options) {
    if (typeof obj[prop] === 'function') {
      obj[prop].__accessor__ = true;
    }
  };
  PropertyAccessors = {
    get: instanceGet,
    set: instanceSet,
    property: function(obj, prop, options) {
      createAccessor(obj, prop, options);
      return markAccessor(obj, prop, options);
    },
    mark: function(obj, prop, options) {
      return markAccessor(obj, prop, options);
    }
  };
  PropertyAccessors.InstanceMembers = {
    get: inlineGet,
    set: inlineSet,
    properties: function() {
      return this._properties || (this._properties = {});
    },
    previousProperties: function() {
      return this._previousProperties || (this._previousProperties = {});
    },
    previous: function(prop) {
      var ref1;
      return (ref1 = this._previousProperties) != null ? ref1[prop] : void 0;
    }
  };
  ref1 = ['properties', 'previousProperties', 'previous'];
  for (k = 0, len1 = ref1.length; k < len1; k++) {
    prop = ref1[k];
    markAccessor(PropertyAccessors.InstanceMembers, prop);
  }
  PropertyAccessors.ClassMembers = {
    property: function(prop, options) {
      PropertyAccessors.property(this.prototype, prop, options);
      return this;
    }
  };
  return PropertyAccessors;
});
