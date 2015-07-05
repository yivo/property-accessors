describe 'PropertyAccessors', ->

  expectFunction = (value) ->
    expect(typeof value).toBe('function')

  expectPropertyToBeReadonly = (object, property) ->
    object['_' + property] = 1
    expect(object[property]).toBe(1)
    object[property] = 2
    expect(object[property]).toBe(1)

  it 'defined and defined in function prototype', ->
    expect(typeof PropertyAccessors).toBe 'object'
    expectFunction(PropertyAccessors.property)
    expectFunction(Function::property)

  it 'defines property on class', ->
    class Person
      @property 'name'

    expect(Person.prototype.hasOwnProperty('name')).toBeTruthy()
    expectFunction(Person::getName)
    expectFunction(Person::setName)

    person = new Person()
    person.name = 'Jacob'
    expect(person.name).toBe('Jacob')
    expect(person._name).toBe('Jacob')
    person.name = 'Adam'
    expect(person._previousName).toBe('Jacob')

  it 'can inherit properties', ->
    class Person
      @property 'name'

    class Student extends Person
      @property 'course'

    expectFunction(Person::getName)
    expectFunction(Person::setName)
    expectFunction(Student::getName)
    expectFunction(Student::setName)
    expectFunction(Student::getCourse)
    expectFunction(Student::setCourse)

  it 'defines property on class with custom accessors', ->
    class Person
      @property 'name',
        get: -> @_name or 'Jacob'
        set: (value) -> @_name = value

    person = new Person()
    expect(person.name).toBe('Jacob')
    person.name = 'Adam'
    expect(person.name).toBe('Adam')
    expect(person._name).toBe(person.name)

  it 'defines readonly property on class', ->
    class PersonA
      @property 'id', set: false
    expectPropertyToBeReadonly(new PersonA(), 'id')

    class PersonB
      @property 'id', readonly: true
    expectPropertyToBeReadonly(new PersonB(), 'id')

  it 'supports short readonly syntax', ->
    class Person
      @property 'id', -> @_id

    person = new Person()
    person._id = 1
    expect(person.id).toBe(1)
    person.id = 2
    expect(person.id).toBe(1)

  it 'works well when property defined multiple times', ->
    redefinedGetter = ->
    class Person
      @property 'name'
      @property 'name', get: redefinedGetter
      @property 'name', set: false

    expect(Person::getName).toBe(redefinedGetter)
    expect(Person::setName.toString()).toBe(PropertyAccessors.createGetter('name').toString())

  it 'breaks previously defined setter when readonly options is set', ->
    class Person
      @property 'id'
      @property 'id', readonly: yes

    expectPropertyToBeReadonly(new Person(), 'id')

  it 'restores setter after readonly option', ->
    class Person
      @property 'id', readonly: true
      @property 'id', set: true

    person = new Person()
    person.id = 1
    expect(person.id).toBe(1)
    person.id = 2
    expect(person.id).toBe(2)

  it 'can map accessors by string', ->
    class Person
      loadBiography: ->
        @_biography ||= name: 'Jacob'

      changeBiography: (bio) ->

      @property 'biography',
        get: 'loadBiography'
        set: 'changeBiography'

    person = new Person()
    expect(person.getBiography).toBe(Person::loadBiography)
    expect(person.biography?.name).toBe('Jacob')
    expect(person.setBiography).toBe(Person::changeBiography)

  it 'provides default actions in custom accessors', ->
    customNameSetter = (name, options, set) ->
      expectFunction(set)
      set(this, name, options) if name
      this

    class Person
      customNameGetter: (get) -> get(this)

      @property 'name',
        set: customNameSetter
        get: 'customNameGetter'

    person = new Person()
    expect(Person::setName).toBe(customNameSetter)
    person.name = 'Jacob'
    person.name = null
    expect(person.name).toBe('Jacob')

  it "throws when accessors specified as a string can't be mapped to function", ->
    class Person
      expect(=> @property('name', get: 'loadName')).toThrow()
      expect(=> @property('name', set: false)).not.toThrow()