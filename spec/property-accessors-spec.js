var extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
  hasProp = {}.hasOwnProperty;

describe('PropertyAccessors', function() {
  var expectFunction, expectPropertyToBeReadonly;
  expectFunction = function(value) {
    return expect(typeof value).toBe('function');
  };
  expectPropertyToBeReadonly = function(object, property) {
    object['_' + property] = 1;
    expect(object[property]).toBe(1);
    object[property] = 2;
    return expect(object[property]).toBe(1);
  };
  it('defined and defined in function prototype', function() {
    expect(typeof PropertyAccessors).toBe('object');
    expectFunction(PropertyAccessors.property);
    return expectFunction(Function.prototype.property);
  });
  it('defines property on class', function() {
    var Person, person;
    Person = (function() {
      function Person() {}

      Person.property('name');

      return Person;

    })();
    expect(Person.prototype.hasOwnProperty('name')).toBeTruthy();
    expectFunction(Person.prototype.getName);
    expectFunction(Person.prototype.setName);
    person = new Person();
    person.name = 'Jacob';
    expect(person.name).toBe('Jacob');
    expect(person._name).toBe('Jacob');
    person.name = 'Adam';
    return expect(person._previousName).toBe('Jacob');
  });
  it('can inherit properties', function() {
    var Person, Student;
    Person = (function() {
      function Person() {}

      Person.property('name');

      return Person;

    })();
    Student = (function(superClass) {
      extend(Student, superClass);

      function Student() {
        return Student.__super__.constructor.apply(this, arguments);
      }

      Student.property('course');

      return Student;

    })(Person);
    expectFunction(Person.prototype.getName);
    expectFunction(Person.prototype.setName);
    expectFunction(Student.prototype.getName);
    expectFunction(Student.prototype.setName);
    expectFunction(Student.prototype.getCourse);
    return expectFunction(Student.prototype.setCourse);
  });
  it('defines property on class with custom accessors', function() {
    var Person, person;
    Person = (function() {
      function Person() {}

      Person.property('name', {
        get: function() {
          return this._name || 'Jacob';
        },
        set: function(value) {
          return this._name = value;
        }
      });

      return Person;

    })();
    person = new Person();
    expect(person.name).toBe('Jacob');
    person.name = 'Adam';
    expect(person.name).toBe('Adam');
    return expect(person._name).toBe(person.name);
  });
  it('defines readonly property on class', function() {
    var PersonA, PersonB;
    PersonA = (function() {
      function PersonA() {}

      PersonA.property('id', {
        set: false
      });

      return PersonA;

    })();
    expectPropertyToBeReadonly(new PersonA(), 'id');
    PersonB = (function() {
      function PersonB() {}

      PersonB.property('id', {
        readonly: true
      });

      return PersonB;

    })();
    return expectPropertyToBeReadonly(new PersonB(), 'id');
  });
  it('supports short readonly syntax', function() {
    var Person, person;
    Person = (function() {
      function Person() {}

      Person.property('id', function() {
        return this._id;
      });

      return Person;

    })();
    person = new Person();
    person._id = 1;
    expect(person.id).toBe(1);
    person.id = 2;
    return expect(person.id).toBe(1);
  });
  it('works well when property defined multiple times', function() {
    var Person, redefinedGetter;
    redefinedGetter = function() {};
    Person = (function() {
      function Person() {}

      Person.property('name');

      Person.property('name', {
        get: redefinedGetter
      });

      Person.property('name', {
        set: false
      });

      return Person;

    })();
    expect(Person.prototype.getName).toBe(redefinedGetter);
    return expect(Person.prototype.setName.toString()).toBe(PropertyAccessors.createGetter('name').toString());
  });
  it('breaks previously defined setter when readonly options is set', function() {
    var Person;
    Person = (function() {
      function Person() {}

      Person.property('id');

      Person.property('id', {
        readonly: true
      });

      return Person;

    })();
    return expectPropertyToBeReadonly(new Person(), 'id');
  });
  it('restores setter after readonly option', function() {
    var Person, person;
    Person = (function() {
      function Person() {}

      Person.property('id', {
        readonly: true
      });

      Person.property('id', {
        set: true
      });

      return Person;

    })();
    person = new Person();
    person.id = 1;
    expect(person.id).toBe(1);
    person.id = 2;
    return expect(person.id).toBe(2);
  });
  it('can map accessors by string', function() {
    var Person, person, ref;
    Person = (function() {
      function Person() {}

      Person.prototype.loadBiography = function() {
        return this._biography || (this._biography = {
          name: 'Jacob'
        });
      };

      Person.prototype.changeBiography = function(bio) {};

      Person.property('biography', {
        get: 'loadBiography',
        set: 'changeBiography'
      });

      return Person;

    })();
    person = new Person();
    expect(person.getBiography).toBe(Person.prototype.loadBiography);
    expect((ref = person.biography) != null ? ref.name : void 0).toBe('Jacob');
    return expect(person.setBiography).toBe(Person.prototype.changeBiography);
  });
  it('provides default actions in custom accessors', function() {
    var Person, customNameSetter, person;
    customNameSetter = function(name, options, set) {
      expectFunction(set);
      if (name) {
        set(this, name, options);
      }
      return this;
    };
    Person = (function() {
      function Person() {}

      Person.prototype.customNameGetter = function(get) {
        return get(this);
      };

      Person.property('name', {
        set: customNameSetter,
        get: 'customNameGetter'
      });

      return Person;

    })();
    person = new Person();
    expect(Person.prototype.setName).toBe(customNameSetter);
    person.name = 'Jacob';
    person.name = null;
    return expect(person.name).toBe('Jacob');
  });
  return it("throws when accessors specified as a string can't be mapped to function", function() {
    var Person;
    return Person = (function() {
      function Person() {}

      expect(function() {
        return Person.property('name', {
          get: 'loadName'
        });
      }).toThrow();

      expect(function() {
        return Person.property('name', {
          set: false
        });
      }).not.toThrow();

      return Person;

    })();
  });
});
