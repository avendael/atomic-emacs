{Point} = require 'atom'

module.exports =
  BOB: new Point(0, 0)

  positionAfter: (editor, point) ->
    lineLength = editor.lineTextForBufferRow(point.row).length
    if point.column == lineLength
      if point.row == editor.getLastBufferRow()
        null
      else
        new Point(point.row + 1, 0)
    else
      point.translate([0, 1])

  # Return the position after the given one, or null if point is BOB.
  positionBefore: (editor, point) ->
    if point.column == 0
      if point.row == 0
        null
      else
        column = editor.lineTextForBufferRow(point.row - 1).length
        new Point(point.row - 1, column)
    else
      point.translate([0, -1])
