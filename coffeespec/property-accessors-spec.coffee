describe 'PropertyAccessors', ->

  class Base
    @include Callbacks
    @include PropertyAccessors
    @include PublisherSubscriber

    constructor: -> @initialize()

  describe 'simple property', ->
    it 'correctly gets and sets value', ->
      class Person extends Base
        @property 'name'
      p = new Person()
      expect(p.name).toBe(undefined)
      p.name = 'Yaroslav'
      expect(p.name).toBe('Yaroslav')

    it 'correctly emits events', ->
      class Person extends Base
        @property 'name'
      p = new Person()
      n = 0
      p.on 'change:name', -> ++n
      expect(n).toBe(0)
      p.name = 'Yaroslav'
      expect(n).toBe(1)
      p.name = 'Yaroslav'
      expect(n).toBe(1)
      p.name = 'Yaroslav Volkov'
      expect(n).toBe(2)

    it 'emits events when value set to falsy', ->
      class Person extends Base
        @property 'name'
      p = new Person()
      p.name = 'Yaroslav'
      n = 0
      p.on 'change:name', -> ++n
      p.name = null
      expect(n).toBe(1)

  describe 'readonly property', ->
    it "doesn't throw on value get", ->
      class Person extends Base
        @property 'name', readonly: yes
      p = new Person()
      expect(-> p.name).not.toThrow()

    it 'throws on value set', ->
      class Person extends Base
        @property 'name', readonly: yes
      p = new Person()
      expect(-> p.name = 'Yaroslav').toThrow()

  describe 'property with silent events', ->
    it "doesn't emit events", ->
      class Person extends Base
        @property 'name', silent: yes
      p = new Person()
      n = 0
      p.on 'change:name', -> ++n
      p.name = 'Yaroslav'
      expect(n).toBe(0)

  describe 'computed property', ->
    it 'invokes computer on every get', ->
      class Counter extends Base
        n = 0
        @property 'count', -> ++n
      c = new Counter()
      expect(c.count).toBe(1)
      expect(c.count).toBe(2)

    it 'correctly emits events', ->
      class Counter extends Base
        c = 0
        @property 'count', -> @_count = if c > 2 then 3 else ++c
      c = new Counter()
      n = 0
      c.on 'change:count', -> ++n
      c.count
      expect(n).toBe(1)
      c.count
      expect(n).toBe(2)
      c.count
      expect(n).toBe(3)
      c.count
      expect(n).toBe(3)

    it 'works good when default value pattern used', ->
      class Counter extends Base
        @property 'count', -> ++calls; @_count ?= 0
      c      = new Counter()
      events = 0
      calls  = 0
      c.on 'change:count', -> ++events
      expect(c.count).toBe(0)
      expect(calls).toBe(1)
      expect(events).toBe(1)
      c.count = 5
      expect(c.count).toBe(5)
      expect(calls).toBe(2)
      expect(events).toBe(2)
      c.count = 5
      expect(c.count).toBe(5)
      expect(calls).toBe(3)
      expect(events).toBe(2)

    it 'correctly works with dependencies', ->
      class Person extends Base
        @property 'firstName'
        @property 'lastName'
        @property 'fullName', depends: ['firstName', 'lastName'], -> @_fullName = "#{@firstName} #{@lastName}"
      p = new Person()
      n = 0
      p.on 'change:fullName', -> ++n

      p.fullName
      expect(n).toBe(1)
      expect(p.fullName).toBe('undefined undefined')

      p.firstName = 'Yaroslav'
      expect(n).toBe(2)
      expect(p.fullName).toBe('Yaroslav undefined')

      p.lastName = 'Volkov'
      expect(n).toBe(3)
      expect(p.fullName).toBe('Yaroslav Volkov')

    it 'returns actual value if value changes during get (memo: true)', ->
      class Person extends Base
        @property 'name', memo: true, -> 'Yaroslav'
      p = new Person()
      p.on 'change:name', -> p.name = 'Tom'
      expect(p.name).toBe('Tom')

    it 'returns old value if value changes during get (memo: false)', ->
      class Person extends Base
        @property 'name', -> @_name ?= 'Yaroslav'
      p = new Person()
      p.on 'change:name', -> p.name = 'Tom'
      expect(p.name).toBe('Yaroslav')

    describe 'when memoized', ->
      it 'invokes computer only when value is falsy', ->
        class Counter extends Base
          count = 0
          @property 'count', memo: true, -> ++count
        c = new Counter()
        expect(c.count).toBe(1)
        expect(c.count).toBe(1)
        c.count = null
        expect(c.count).toBe(2)
        expect(c.count).toBe(2)

      it 'correctly emits events', ->
        class Counter extends Base
          count = 0
          @property 'count', memo: true, -> ++count
        c   = new Counter()
        n   = 0
        c.on 'change:count', -> ++n
        c.count
        expect(n).toBe(1)
        c.count
        expect(n).toBe(1)
        c.count = null
        expect(n).toBe(2)
        c.count
        expect(n).toBe(3)
        c.count
        expect(n).toBe(3)

      it 'correctly works when there are dependencies', ->
        class Person extends Base
          @property 'firstName'
          @property 'lastName'
          @property 'fullName', depends: ['firstName', 'lastName'], memo: yes, ->
            "#{@firstName} #{@lastName}"
        x = 0
        y = 0
        z = 0
        p = new Person()
        p.bind
          'change:firstName': -> ++x
          'change:lastName':  -> ++y
          'change:fullName':  -> ++z
        p.firstName = 'Yaroslav'
        expect(x).toBe(1)
        expect(y).toBe(0)
        expect(z).toBe(1)
        p.lastName = 'Volkov'
        expect(p.fullName).toBe('Yaroslav Volkov')
        expect(x).toBe(1)
        expect(y).toBe(1)
        expect(z).toBe(2)

  describe 'both readonly and computed property', ->
    it 'correctly gets, sets value and emits events', ->
      class Foo extends Base
        @property 'bar', readonly: yes, -> @_bar = ++calls
      calls  = 0
      events = 0
      f      = new Foo()
      f.on 'change:bar', -> ++events
      expect(f.bar).toBe(1)
      expect(events).toBe(1)
      f.bar
      f.bar
      expect(f.bar).toBe(4)
      expect(events).toBe(4)

    describe 'when also memoized', ->
      it 'correctly gets, sets value and emits events', ->
        class Foo extends Base
          @property 'bar', readonly: yes, memo: yes, -> ++calls
        calls  = 0
        events = 0
        f      = new Foo()
        f.on 'change:bar', -> ++events
        expect(f.bar).toBe(1)
        expect(events).toBe(1)
        f.bar
        f.bar
        expect(f.bar).toBe(1)
        expect(events).toBe(1)

  describe 'when property defined on instance', ->
    it 'correctly works', ->
      p = new Base()
      n = 0
      p.on 'change:name', -> ++n
      PropertyAccessors.define(p, 'name')
      expect(p.name).toBe(undefined)
      expect(n).toBe(0)
      p.name = 'Yaroslav'
      expect(p.name).toBe('Yaroslav')
      expect(n).toBe(1)
