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
        strict = do (-> 'use strict'; !this)
        object = {a: 228}
        supports = utils.readonly object, 'a'
        expect(-> object.a = 666).to.throwError() if supports and strict

    describe 'getPrototypeChain', ->
      it 'should get prototype chain of instance', ->
        object = new D
        expect(utils.getPrototypeChain object).to.eql [
          A.prototype,
          B.prototype,
          C.prototype,
          D.prototype
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

    describe 'QueryParams', ->
      queryParams = 'p1': 'With space', 'p 2': [999, 'a&b']
      queryString = 'p1=With%20space&p%202=999&p%202=a%26b'

      it 'should serialize query parameters from object into string', ->
        expect(utils.QueryParams.stringify queryParams).to.be queryString

      it 'should deserialize query parameters from query string into object', ->
        expect(utils.QueryParams.parse queryString).to.eql queryParams
