// Polyfill localStorage
// https://developer.mozilla.org/nl/docs/DOM/Storage
if (!window.localStorage) { window.localStorage = { getItem: function (sKey) { if (!sKey || !this.hasOwnProperty(sKey)) { return null; } return unescape(document.cookie.replace(new RegExp("(?:^|.*;\\s*)" + escape(sKey).replace(/[\-\.\+\*]/g, "\\$&") + "\\s*\\=\\s*((?:[^;](?!;))*[^;]?).*"), "$1")); }, key: function (nKeyId) { return unescape(document.cookie.replace(/\s*\=(?:.(?!;))*$/, "").split(/\s*\=(?:[^;](?!;))*[^;]?;\s*/)[nKeyId]); }, setItem: function (sKey, sValue) { if(!sKey) { return; } document.cookie = escape(sKey) + "=" + escape(sValue) + "; expires=Tue, 19 Jan 2038 03:14:07 GMT; path=/"; this.length = document.cookie.match(/\=/g).length; }, length: 0, removeItem: function (sKey) { if (!sKey || !this.hasOwnProperty(sKey)) { return; } document.cookie = escape(sKey) + "=; expires=Thu, 01 Jan 1970 00:00:00 GMT; path=/"; this.length--; }, hasOwnProperty: function (sKey) { return (new RegExp("(?:^|;\\s*)" + escape(sKey).replace(/[\-\.\+\*]/g, "\\$&") + "\\s*\\=")).test(document.cookie); } }; window.localStorage.length = (document.cookie.match(/\=/g) || window.localStorage).length; }

// Encapsulates handling of preferred language (CoffeeScript or
// JavaScript)
CD = (function () {
  var language = localStorage.getItem('language') || 'coffeescript';
  return {
    // Get/set preferred language
    language: function (value) {
      if (value) {
        language = value;
        localStorage.setItem('language', language);
      }
      return language;
    },
    // Show code examples for given language
    show: function (language) {
      var language = language.toLowerCase();
      var other = language === "coffeescript" ? "javascript" : "coffeescript";
      // Update UI
      $('form.language li').removeClass('active').find(':radio[value=' + language + ']')
        .prop('checked', true)
        .closest('li').addClass('active');
      // Add class for inline code
      $('body').removeClass('show-' + other).addClass('show-' + language);
      // Toggle code blocks
      $('.highlight')
        .hide()
        .filter(':has(.' + language + ')').show();
    }
  };
})();

$(document).ready(function () {
  // Set up handling of language toggling
  $(':radio[name=language]')
    .click(function () {
      var language = $('form.language input:checked').val();
      CD.show(CD.language(language));
    });
  // Show code examples according to user prefs
  CD.show(CD.language());
});
