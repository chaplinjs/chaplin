fs = require('fs')

# Functional purity FTW.

String::startsWith = (subString) ->
  this.lastIndexOf(subString, 0) is 0

String::repeat = (times) ->
  Array(times + 1).join(this)

createLineObject = (line, index) -> {line, index}

nonEmpty = (line) -> line.line isnt ''

addTypes = (line) ->
  if line.line.startsWith(' '.repeat(2))
    if line.line.startsWith(' '.repeat(4)) or line.line.charAt(2) is '}'
      line.type = 'invalid'
    else
      line.type = 'indented'
  else
    line.type = 'default'
  line

nonInvalid = (line) -> line.type isnt 'invalid'

groupByNonIndented = (array, line) ->
  if line.type is 'indented'
    array[array.length - 1].push line
  else
    array.push []
  array

nonNull = (variable) -> variable?

last = (array) ->
  array[array.length - 1]

addModuleExports = (line) ->
  line.line = "  module.exports = #{line.line.trim()}"
  line

convertExports = (string) ->
  lines = string.split('\n')
  lines
    .map(createLineObject)
    .filter(nonEmpty)
    .map(addTypes)
    .filter(nonInvalid)
    .reduce(groupByNonIndented, [])
    .map(last)
    .filter(nonNull)
    .map(addModuleExports)
    .forEach (line) ->
      lines[line.index] = line.line
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
  """

  console.log convertExports test

console.log convertExports fs.readFileSync('/dev/stdin').toString()
