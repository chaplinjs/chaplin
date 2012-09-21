var SinonExpect;

SinonExpect = {

  /**
   * Sinon assertions supported.
   *
   *
   * @property assertions
   * @type {Array}
   * @private
   */
  assertions: [
    "notCalled",
    "called",
    "calledOnce",
    "calledTwice",
    "calledThrice",
    "callCount",
    "callOrder",
    "calledOn",
    "alwaysCalledOn",
    "calledWith",
    "alwaysCalledWith",
    "neverCalledWith",
    "calledWithExactly",
    "alwaysCalledWithExactly",
    "threw",
    "alwaysThrew"
  ],

  /**
   * Enhances expect with sinon matchers.
   * Usage:
   *    
   *
   *    //Yes you need to override the old expect, sorry.
   *    expect = SinonExpect.enhance(expect, sinon)
   *
   *    expect(object.withSpy).spy.called();
   *
   *
   *
   * @param {expect.js} expect expect.js object
   * @param {sinon} sinon sinon instance
   */
  enhance: function(expect, sinon, name){
    if(typeof(name) === 'undefined'){
      name = 'spy';
    }

    SinonExpect._expect = expect;
    SinonExpect._sinon = sinon;

    SinonExpect.ExpectWrapper.__proto__ = expect.Assertion;
    SinonExpect.ExpectWrapper.spyName = name;

    var result = function(obj){
      return new SinonExpect.ExpectWrapper(obj);
    };

    result.Assertion = SinonExpect.ExpectWrapper;

    SinonExpect.buildMatchers();

    return result;
  },


  /**
   * Creates sinon matchers on the SinonExpect.SinonAssertions prototype.
   * This could also be done on including the file but I prefer
   * keeping it in a method.
   *
   * @private
   */
  buildMatchers: function(){
    var i = 0, len = SinonExpect.assertions.length,
        matcher;

    for(i, len; i < len; i++){
      matcher = SinonExpect.assertions[i];
      (function(matcher){
        SinonExpect.SinonAssertions.prototype[matcher] = function(){
          var args = Array.prototype.slice.call(arguments),
              sinon = SinonExpect._sinon;

          args.unshift(this.obj);

          sinon.assert[matcher].apply(
            sinon.assert,
            args
          );
        };
      }(matcher));
    }
  }
};

/**
 * Expect wrapper.
 * Creates .spy flag for all expect.Assertion instances.
 *
 * @constructor
 * @class ExpectWrapper
 * @private
 */
SinonExpect.ExpectWrapper = function(){
  SinonExpect._expect.Assertion.apply(this, arguments);
  this[SinonExpect.ExpectWrapper.spyName] = new SinonExpect.SinonAssertions(this.obj);
};


/**
 * Spy flag class.
 * Instance used when using expect(foo).spy.
 * where `spy` is an actual instance of SinonAssertions.
 * 
 *
 * @constructor
 * @class SinonAssertions
 * @private
 */

SinonExpect.SinonAssertions = function(obj){
  this.obj = obj;
};


// module.exports = exports = SinonExpect;

