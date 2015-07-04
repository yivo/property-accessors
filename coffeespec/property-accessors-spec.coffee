describe 'API', ->

  expectFunction = (value) ->
    expect(typeof value).toBe('function')

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
    class Person
      @property 'id', set: false

      constructor: ->
        @_id = 1

    person = new Person()
    expect(person.id).toBe(1)
    person.id = 2
    expect(person.id).toBe(1)

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

  it 'defines property multiple times and works stable', ->

    redefinedGetter = ->

    class Person
      @property 'name'

      @property 'name', get: redefinedGetter

      @property 'name', set: false

    expect(Person::getName).toBe(redefinedGetter)
    expect(Person::setName.toString()).toBe(PropertyAccessors.createGetter('name').toString())

  it 'can map accessor by string', ->
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

  it 'supports writable option', ->
    class Person
      @property 'id', writable: no

    person = new Person()
    person._id = 1
    expect(person.id).toBe(1)
    person.id = 2
    expect(person.id).toBe(1)
