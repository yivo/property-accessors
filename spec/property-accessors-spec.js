var extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
  hasProp = {}.hasOwnProperty;

describe('API', function() {
  var expectFunction;
  expectFunction = function(value) {
    return expect(typeof value).toBe('function');
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
    var Person, person;
    Person = (function() {
      Person.property('id', {
        set: false
      });

      function Person() {
        this._id = 1;
      }

      return Person;

    })();
    person = new Person();
    expect(person.id).toBe(1);
    person.id = 2;
    return expect(person.id).toBe(1);
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
  it('defines property multiple times and works stable', function() {
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
  it('can map accessor by string', function() {
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
  return it('supports writable option', function() {
    var Person, person;
    Person = (function() {
      function Person() {}

      Person.property('id', {
        writable: false
      });

      return Person;

    })();
    person = new Person();
    person._id = 1;
    expect(person.id).toBe(1);
    person.id = 2;
    return expect(person.id).toBe(1);
  });
});
