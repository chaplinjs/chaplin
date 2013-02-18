define [
  'backbone'
  'underscore'
  'chaplin/lib/utils'
], (Backbone, _, utils) ->
  'use strict'

  describe 'utils', ->
    class A
      prop: 1
    class B extends A
      prop: null
    class C extends B
      prop: 2
    class D extends C
      prop: 3

    describe 'beget', ->
      it 'should create a new object with the specified prototype object', ->
        a = utils.beget {a: 1}
        b = utils.beget a
        b.b = 2
        c = utils.beget b
        c.c = 3
        d = utils.beget c
        expect(c.a).to.equal 1
        expect(c.b).to.equal 2
        expect(c.c).to.equal 3

    describe 'serialize', ->
      it 'should serialize objects and incorporate duck-typing', ->
        model = new Backbone.Model a: 1
        expect(utils.serialize model).to.eql a: 1
        expect(utils.serialize {serialize: -> 5}).to.be 5
        expect(-> utils.serialize {}).to.throwError()

    describe 'readonly', ->
      it 'should make property read-only', ->
        object = {a: 228}
        supports = utils.readonly object, 'a'
        expect(-> object.a = 666).to.throwError() if supports

    describe 'getPrototypeChain', ->
      it 'should get prototype chain of instance', ->
        object = new D
        expect(utils.getPrototypeChain object).to.eql [
          D.prototype,
          C.prototype,
          B.prototype,
          A.prototype
        ]

    describe 'getAllPropertyVersions', ->
      it 'should get property from all prototypes', ->
        object = new D
        expect(utils.getAllPropertyVersions object, 'prop').to.eql [1, 2, 3]

    describe 'upcase', ->
      it 'should make the first character in string upper-cased', ->
        expect(utils.upcase 'stuff').to.be 'Stuff'
        expect(utils.upcase 'стафф').to.be 'Стафф'
        expect(utils.upcase '123456').to.be '123456'

    describe 'underscorize', ->
      it 'should convert camelCase to underscore_case', ->
        expect(utils.underscorize 'userNameAndAge').to.be 'user_name_and_age'
        expect(utils.underscorize 'User').to.be 'user'
