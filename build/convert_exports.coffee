fs = require 'fs'

# Functional purity FTW.
# Warning: this converter doesn't detect following case
#   define ->
#     a: a
#     b: b
# so you'll need to write module exports hashes in `{}`.

startsWith = (string, subString) ->
  string.lastIndexOf(subString, 0) is 0

repeat = (string, times) ->
  Array(times + 1).join(string)

TWO_SPACES = repeat ' ', 2
FOUR_SPACES = repeat ' ', 4

createLineObject = (line, index) ->
  {line, index}

nonEmpty = (line) ->
  line.line isnt ''

addTypes = (line) ->
  if startsWith(line.line, TWO_SPACES)
    if startsWith(line.line, FOUR_SPACES) or line.line.charAt(2) is '}'
      line.type = 'invalid'
    else
      line.type = 'indented'
  else
    line.type = 'default'
  line

valid = (line) ->
  line.type isnt 'invalid'

groupByNonIndented = (array, line) ->
  if line.type is 'indented'
    array[array.length - 1].push line
  else
    array.push []
  array

defined = (variable) ->
  variable?

last = (array) ->
  array[array.length - 1]

addModuleExports = (line) ->
  line.line = "  module.exports = #{line.line.trim()}"
  line

replaceOriginalLine = (lines) -> (line) ->
  lines[line.index] = line.line

convertExports = (string) ->
  lines = string.split('\n')
  lines
    .map(createLineObject)
    .filter(nonEmpty)
    .map(addTypes)
    .filter(valid)
    .reduce(groupByNonIndented, [])
    .map(last)
    .filter(defined)
    .map(addModuleExports)
    .forEach(replaceOriginalLine lines)
  lines.join('\n')

testConvertExports = ->
  test = """
  a
    a-true
      a-indent

  b
    b1
    b2
      b-intent
    b-true


  c
    c1
      c2
        c3
          c4
            c5
              c6
            c5
          c4
        c3
      c2
    c1
    c-true

  d
    d2
      d3
    d5
    {
      d6
    }
  """

  console.log convertExports test

module.exports = convertExports
