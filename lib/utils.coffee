{Point} = require 'atom'

module.exports =
  BOB: new Point(0, 0)

  # Stolen from underscore-plus.
  escapeForRegExp: (string) ->
    if string
      string.replace(/[-\/\\^$*+?.()|[\]{}]/g, '\\$&')
    else
      ''
