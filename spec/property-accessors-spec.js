var extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
  hasProp = {}.hasOwnProperty;

describe('PropertyAccessors', function() {
  var Base;
  Base = (function() {
    Base.include(Callbacks);

    Base.include(PropertyAccessors);

    Base.include(PublisherSubscriber);

    function Base() {
      this.bindCallbacks();
      this.runInitializers();
    }

    return Base;

  })();
  describe('simple property', function() {
    it('correctly gets and sets value', function() {
      var Person, p;
      Person = (function(superClass) {
        extend(Person, superClass);

        function Person() {
          return Person.__super__.constructor.apply(this, arguments);
        }

        Person.property('name');

        return Person;

      })(Base);
      p = new Person();
      expect(p.name).toBe(void 0);
      p.name = 'Yaroslav';
      return expect(p.name).toBe('Yaroslav');
    });
    it('correctly emits events', function() {
      var Person, n, p;
      Person = (function(superClass) {
        extend(Person, superClass);

        function Person() {
          return Person.__super__.constructor.apply(this, arguments);
        }

        Person.property('name');

        return Person;

      })(Base);
      p = new Person();
      n = 0;
      p.on('change:name', function() {
        return ++n;
      });
      expect(n).toBe(0);
      p.name = 'Yaroslav';
      expect(n).toBe(1);
      p.name = 'Yaroslav';
      expect(n).toBe(1);
      p.name = 'Yaroslav Volkov';
      return expect(n).toBe(2);
    });
    return it('emits events when value set to falsy', function() {
      var Person, n, p;
      Person = (function(superClass) {
        extend(Person, superClass);

        function Person() {
          return Person.__super__.constructor.apply(this, arguments);
        }

        Person.property('name');

        return Person;

      })(Base);
      p = new Person();
      p.name = 'Yaroslav';
      n = 0;
      p.on('change:name', function() {
        return ++n;
      });
      p.name = null;
      return expect(n).toBe(1);
    });
  });
  describe('readonly property', function() {
    it("doesn't throw on value get", function() {
      var Person, p;
      Person = (function(superClass) {
        extend(Person, superClass);

        function Person() {
          return Person.__super__.constructor.apply(this, arguments);
        }

        Person.property('name', {
          readonly: true
        });

        return Person;

      })(Base);
      p = new Person();
      return expect(function() {
        return p.name;
      }).not.toThrow();
    });
    return it('throws on value set', function() {
      var Person, p;
      Person = (function(superClass) {
        extend(Person, superClass);

        function Person() {
          return Person.__super__.constructor.apply(this, arguments);
        }

        Person.property('name', {
          readonly: true
        });

        return Person;

      })(Base);
      p = new Person();
      return expect(function() {
        return p.name = 'Yaroslav';
      }).toThrow();
    });
  });
  describe('property with silent events', function() {
    return it("doesn't emit events", function() {
      var Person, n, p;
      Person = (function(superClass) {
        extend(Person, superClass);

        function Person() {
          return Person.__super__.constructor.apply(this, arguments);
        }

        Person.property('name', {
          silent: true
        });

        return Person;

      })(Base);
      p = new Person();
      n = 0;
      p.on('change:name', function() {
        return ++n;
      });
      p.name = 'Yaroslav';
      return expect(n).toBe(0);
    });
  });
  describe('computed property', function() {
    it('invokes computer on every get', function() {
      var Counter, c;
      Counter = (function(superClass) {
        var n;

        extend(Counter, superClass);

        function Counter() {
          return Counter.__super__.constructor.apply(this, arguments);
        }

        n = 0;

        Counter.property('count', function() {
          return ++n;
        });

        return Counter;

      })(Base);
      c = new Counter();
      expect(c.count).toBe(1);
      return expect(c.count).toBe(2);
    });
    it('correctly emits events', function() {
      var Counter, c, n;
      Counter = (function(superClass) {
        var c;

        extend(Counter, superClass);

        function Counter() {
          return Counter.__super__.constructor.apply(this, arguments);
        }

        c = 0;

        Counter.property('count', function() {
          return this._count = c > 2 ? 3 : ++c;
        });

        return Counter;

      })(Base);
      c = new Counter();
      n = 0;
      c.on('change:count', function() {
        return ++n;
      });
      c.count;
      expect(n).toBe(1);
      c.count;
      expect(n).toBe(2);
      c.count;
      expect(n).toBe(3);
      c.count;
      return expect(n).toBe(3);
    });
    it('works good when default value pattern used', function() {
      var Counter, c, calls, events;
      Counter = (function(superClass) {
        extend(Counter, superClass);

        function Counter() {
          return Counter.__super__.constructor.apply(this, arguments);
        }

        Counter.property('count', function() {
          ++calls;
          return this._count != null ? this._count : this._count = 0;
        });

        return Counter;

      })(Base);
      c = new Counter();
      events = 0;
      calls = 0;
      c.on('change:count', function() {
        return ++events;
      });
      expect(c.count).toBe(0);
      expect(calls).toBe(1);
      expect(events).toBe(1);
      c.count = 5;
      expect(c.count).toBe(5);
      expect(calls).toBe(2);
      expect(events).toBe(2);
      c.count = 5;
      expect(c.count).toBe(5);
      expect(calls).toBe(3);
      return expect(events).toBe(2);
    });
    it('correctly works with dependencies', function() {
      var Person, n, p;
      Person = (function(superClass) {
        extend(Person, superClass);

        function Person() {
          return Person.__super__.constructor.apply(this, arguments);
        }

        Person.property('firstName');

        Person.property('lastName');

        Person.property('fullName', {
          depends: ['firstName', 'lastName']
        }, function() {
          return this._fullName = this.firstName + " " + this.lastName;
        });

        return Person;

      })(Base);
      p = new Person();
      n = 0;
      p.on('change:fullName', function() {
        return ++n;
      });
      p.fullName;
      expect(n).toBe(1);
      expect(p.fullName).toBe('undefined undefined');
      p.firstName = 'Yaroslav';
      expect(n).toBe(2);
      expect(p.fullName).toBe('Yaroslav undefined');
      p.lastName = 'Volkov';
      expect(n).toBe(3);
      return expect(p.fullName).toBe('Yaroslav Volkov');
    });
    it('returns actual value if value changes during get (memo: true)', function() {
      var Person, p;
      Person = (function(superClass) {
        extend(Person, superClass);

        function Person() {
          return Person.__super__.constructor.apply(this, arguments);
        }

        Person.property('name', {
          memo: true
        }, function() {
          return 'Yaroslav';
        });

        return Person;

      })(Base);
      p = new Person();
      p.on('change:name', function() {
        return p.name = 'Tom';
      });
      return expect(p.name).toBe('Tom');
    });
    it('returns old value if value changes during get (memo: false)', function() {
      var Person, p;
      Person = (function(superClass) {
        extend(Person, superClass);

        function Person() {
          return Person.__super__.constructor.apply(this, arguments);
        }

        Person.property('name', function() {
          return this._name != null ? this._name : this._name = 'Yaroslav';
        });

        return Person;

      })(Base);
      p = new Person();
      p.on('change:name', function() {
        return p.name = 'Tom';
      });
      return expect(p.name).toBe('Yaroslav');
    });
    return describe('when memoized', function() {
      it('invokes computer only when value is falsy', function() {
        var Counter, c;
        Counter = (function(superClass) {
          var count;

          extend(Counter, superClass);

          function Counter() {
            return Counter.__super__.constructor.apply(this, arguments);
          }

          count = 0;

          Counter.property('count', {
            memo: true
          }, function() {
            return ++count;
          });

          return Counter;

        })(Base);
        c = new Counter();
        expect(c.count).toBe(1);
        expect(c.count).toBe(1);
        c.count = null;
        expect(c.count).toBe(2);
        return expect(c.count).toBe(2);
      });
      it('correctly emits events', function() {
        var Counter, c, n;
        Counter = (function(superClass) {
          var count;

          extend(Counter, superClass);

          function Counter() {
            return Counter.__super__.constructor.apply(this, arguments);
          }

          count = 0;

          Counter.property('count', {
            memo: true
          }, function() {
            return ++count;
          });

          return Counter;

        })(Base);
        c = new Counter();
        n = 0;
        c.on('change:count', function() {
          return ++n;
        });
        c.count;
        expect(n).toBe(1);
        c.count;
        expect(n).toBe(1);
        c.count = null;
        expect(n).toBe(2);
        c.count;
        expect(n).toBe(3);
        c.count;
        return expect(n).toBe(3);
      });
      return it('correctly works when there are dependencies', function() {
        var Person, p, x, y, z;
        Person = (function(superClass) {
          extend(Person, superClass);

          function Person() {
            return Person.__super__.constructor.apply(this, arguments);
          }

          Person.property('firstName');

          Person.property('lastName');

          Person.property('fullName', {
            depends: ['firstName', 'lastName'],
            memo: true
          }, function() {
            return this.firstName + " " + this.lastName;
          });

          return Person;

        })(Base);
        x = 0;
        y = 0;
        z = 0;
        p = new Person();
        p.bind({
          'change:firstName': function() {
            return ++x;
          },
          'change:lastName': function() {
            return ++y;
          },
          'change:fullName': function() {
            return ++z;
          }
        });
        p.firstName = 'Yaroslav';
        expect(x).toBe(1);
        expect(y).toBe(0);
        expect(z).toBe(1);
        p.lastName = 'Volkov';
        expect(p.fullName).toBe('Yaroslav Volkov');
        expect(x).toBe(1);
        expect(y).toBe(1);
        return expect(z).toBe(2);
      });
    });
  });
  describe('both readonly and computed property', function() {
    it('correctly gets, sets value and emits events', function() {
      var Foo, calls, events, f;
      Foo = (function(superClass) {
        extend(Foo, superClass);

        function Foo() {
          return Foo.__super__.constructor.apply(this, arguments);
        }

        Foo.property('bar', {
          readonly: true
        }, function() {
          return this._bar = ++calls;
        });

        return Foo;

      })(Base);
      calls = 0;
      events = 0;
      f = new Foo();
      f.on('change:bar', function() {
        return ++events;
      });
      expect(f.bar).toBe(1);
      expect(events).toBe(1);
      f.bar;
      f.bar;
      expect(f.bar).toBe(4);
      return expect(events).toBe(4);
    });
    return describe('when also memoized', function() {
      return it('correctly gets, sets value and emits events', function() {
        var Foo, calls, events, f;
        Foo = (function(superClass) {
          extend(Foo, superClass);

          function Foo() {
            return Foo.__super__.constructor.apply(this, arguments);
          }

          Foo.property('bar', {
            readonly: true,
            memo: true
          }, function() {
            return ++calls;
          });

          return Foo;

        })(Base);
        calls = 0;
        events = 0;
        f = new Foo();
        f.on('change:bar', function() {
          return ++events;
        });
        expect(f.bar).toBe(1);
        expect(events).toBe(1);
        f.bar;
        f.bar;
        expect(f.bar).toBe(1);
        return expect(events).toBe(1);
      });
    });
  });
  return describe('when property defined on instance', function() {
    return it('correctly works', function() {
      var n, p;
      p = new Base();
      n = 0;
      p.on('change:name', function() {
        return ++n;
      });
      PropertyAccessors.define(p, 'name');
      expect(p.name).toBe(void 0);
      expect(n).toBe(0);
      p.name = 'Yaroslav';
      expect(p.name).toBe('Yaroslav');
      return expect(n).toBe(1);
    });
  });
});
