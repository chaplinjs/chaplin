'use strict'
Backbone = require 'backbone'
{utils, mediator} = require '../build/chaplin'

describe 'utils', ->
  class A
    prop: 1
  class B extends A
    prop: null
  class C extends B
    prop: 2
  class D extends C
    prop: 3

  describe 'isEmpty', ->
    it 'should check whether an object does not have own properties', ->
      object = {}
      expect(utils.isEmpty object).to.be.true
      object.a = 1
      expect(utils.isEmpty object).to.be.false

    it 'should check only own properties', ->
      object = Object.create b: 2
      expect(utils.isEmpty object).to.be.true

    it 'should check non-enumerable properties too', ->
      object = {}
      Object.defineProperty object, 'c', value: 3
      expect(utils.isEmpty object).to.be.false

  describe 'serialize', ->
    it 'should serialize objects and incorporate duck-typing', ->
      date = new Date()
      expect(utils.serialize date).to.equal date.toISOString()
      model = new Backbone.Model a: 1
      expect(utils.serialize model).to.deep.equal a: 1
      expect(utils.serialize serialize: -> 2).to.equal 2
      expect(-> utils.serialize {}).to.throw TypeError

  describe 'readonly', ->
    it 'should make property read-only', ->
      object = {a: 228}
      expect(utils.readonly object, 'a').to.be.true
      expect(-> object.a = 666).to.throw TypeError
      expect(object).to.have.ownPropertyDescriptor 'a',
        value: 228
        writable: false
        enumerable: true
        configurable: false

  describe 'getPrototypeChain', ->
    it 'should get prototype chain of instance', ->
      object = new D
      expect(utils.getPrototypeChain object).to.deep.equal [
        Object.prototype,
        A.prototype,
        B.prototype,
        C.prototype,
        D.prototype
      ]

  describe 'getAllPropertyVersions', ->
    it 'should get property from all prototypes', ->
      object = new D
      expect(utils.getAllPropertyVersions object, 'prop').to.deep.equal [
        1,
        2,
        3
      ]

  describe 'upcase', ->
    it 'should make the first character in string upper-cased', ->
      expect(utils.upcase 'stuff').to.equal 'Stuff'
      expect(utils.upcase 'стафф').to.equal 'Стафф'
      expect(utils.upcase '123456').to.equal '123456'

  describe 'reverse', ->
    beforeEach ->
      mediator.unsubscribe()
    afterEach ->
      mediator.unsubscribe()

    it 'should throw exception if no route found', ->
      expect(-> utils.reverse 'foo', id: 3, d: 'data').to.throw Error

    it 'should return the url for a named route', ->
      stubbedRouteHandler = (routeName, params) ->
        expect(routeName).to.equal 'foo'
        expect(params).to.deep.equal id: 3, d: 'data'
        '/foo/bar'

      mediator.setHandler 'router:reverse', stubbedRouteHandler
      url = utils.reverse 'foo', id: 3, d: 'data'
      expect(url).to.equal '/foo/bar'

    it 'should return the url for a named route with empty path', ->
      stubbedRouteHandler = (routeName, params) ->
        expect(routeName).to.equal 'home'
        expect(params).to.be.undefined
        '/'

      mediator.setHandler 'router:reverse', stubbedRouteHandler
      url = utils.reverse 'home'
      expect(url).to.equal '/'

    # it 'should return null if router does not respond', ->
      # url = utils.reverse 'foo', id: 3, d: 'data'
      # expect(url).to.be.null

  describe 'matchesSelector', ->
    {matchesSelector} = utils

    el = document.createElement 'input'
    el.type = 'email'
    el.required = true
    el.className = 'cls'
    el.setAttribute 'data-a', 'b'

    it 'should check whether the element matches CSS selector', ->
      expect(matchesSelector el, 'input[type=email].cls').to.be.true
      expect(matchesSelector el, '[data-a][required]').to.be.true
      expect(matchesSelector el, ':not([optional])').to.be.true
      expect(matchesSelector el, '[data-a=b]').to.be.true

  describe 'queryParams', ->
    falsy = ['', 0, NaN, false, null, undefined]
    {stringify, parse} = utils.querystring

    queryParams = p1: 'With space', p2_empty: '', 'p 3': ['999', 'a&b']
    queryString = 'p1=With%20space&p2_empty=&p%203=999&p%203=a%26b'

    it 'should serialize query parameters from object into string', ->
      expect(stringify queryParams).to.equal queryString

    it 'should ignore undefined and null when serializing query parameters', ->
      params = p1: null, p2: undefined, p3: 'third'
      expect(stringify params).to.equal 'p3=third'

    it 'should ignore first parameter == null', ->
      expect(stringify {}).to.equal ''
      expect(parse '').to.deep.equal {}

    it 'should ignore non-callable second parameter', ->
      expect(stringify queryParams, 1).to.equal queryString
      expect(parse queryString, []).to.deep.equal queryParams

    it 'should serialize with replacer when provided', ->
      replacer = (key, value) ->
        value += '_'
        {key, value}

      expect(stringify queryParams, replacer).to.equal(
        'p1=With%20space_&p2_empty=_&p%203=999%2Ca%26b_')

    it 'should skip pair if replacer returns falsy value', ->
      for value in falsy
        expect(stringify queryParams, -> value).to.equal ''

    it 'should deserialize query parameters from query string into object', ->
      expect(parse queryString).to.deep.equal queryParams

    it 'should take a full url and only return params object', ->
      url = "http://foo.com/app/path?#{queryString}"
      expect(parse url).to.deep.equal queryParams

    it 'should deserialize with reviver when provided', ->
      reviver = (key, value) ->
        if ',' in value
          value = value.split(',').map (value) ->
            if isNaN value then value else +value
        {key, value}

      expect(parse 'a=1%2C2%2C3&b=c%2Cd&e=4', reviver).to.deep.equal
        a: [1, 2, 3]
        b: ['c', 'd']
        e: '4'

    it 'should skip pair if reviver returns falsy value', ->
      for value in falsy
        expect(parse queryString, -> value).to.deep.equal {}

    it 'should skip pair if reviver returns value == null', ->
      expect(parse 'a&').to.deep.equal {}
      expect(parse 'b=1', -> {value: null}).to.deep.equal {}
      expect(parse 'c=2', -> []).to.deep.equal {}

    it 'should have old methods', ->
      expect(utils.queryParams).to.respondTo 'stringify'
      expect(utils.queryParams).to.respondTo 'parse'
