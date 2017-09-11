'use strict'
{Composition, EventBroker, mediator} = require '../build/chaplin'

describe 'Composition', ->
  composition = null

  beforeEach ->
    # Instantiate
    composition = new Composition()

  afterEach ->
    # Dispose
    composition.dispose()
    composition = null

  # Mixin
  # -----

  it 'should mixin a EventBroker', ->
    prototype = Composition.prototype
    expect(prototype).to.contain.all.keys EventBroker

  # Initialize
  # ----------

  it 'should initialize', ->
    expect(composition).to.respondTo 'initialize'
    composition.initialize()

    expect(composition.stale()).to.be.false
    expect(composition.item).to.equal composition

  # Disposal
  # --------

  it 'should dispose itself correctly', ->
    expect(composition.disposed).to.be.false
    expect(composition).to.respondTo 'dispose'
    composition.dispose()

    expect(composition).not.to.have.property 'compositions'
    expect(composition.disposed).to.be.true
    expect(composition).to.be.frozen

  # Extensible
  # ----------

  it 'should be extendable', ->
    expect(Composition).itself.to.respondTo 'extend'

    DerivedComposition = Composition.extend()
    derivedComposition = new DerivedComposition()
    derivedComposition.dispose()

    expect(derivedComposition).to.be.an.instanceof Composition
