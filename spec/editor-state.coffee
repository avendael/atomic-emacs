{Point} = require 'atom'

module.exports =
  open: (state) ->
    editor = atom.project.openSync()
    @set(editor, state)

  # Set the state of the editor.
  #
  # State is set as the text of the editor, with the following indicators
  # stripped out:
  #
  # * [i]: Sets the head of cursor i at this location.
  # * (i): Sets the tail of cursor i at this location.
  set: (editor, state) ->
    editor.setText(state)
    re = /\[(\d+)\]|\((\d+)\)/g

    descriptors = []
    editor.scan re, (hit) ->
      i = parseInt(hit.match[0].slice(1, 2), 10)
      descriptors[i] ?= {}
      if hit.match[1]?
        descriptors[i].head = hit.range.start
      else
        descriptors[i].tail = hit.range.start
      hit.replace('')

    # addCursorAtBufferPosition gets messed up by active selections -- add all
    # cursors before setting tails.
    for descriptor, i in descriptors
      {head} = descriptor or {}
      if not head
        throw "missing head of cursor #{i}"

      cursor = editor.getCursors()[i]
      if not cursor
        cursor = editor.addCursorAtBufferPosition(head)
      else
        cursor.setBufferPosition(head)

    for descriptor, i in descriptors
      {head, tail} = descriptor or {}
      if tail
        cursor = editor.getCursors()[i]
        reversed = Point.min(head, tail) is head
        cursor.selection.setBufferRange([head, tail], isReversed: reversed)

    editor

  # Return the state (in the format described for set()) of the editor.
  get: (editor) ->
    buffer = editor.getBuffer()
    linesWithEndings = (
      [buffer.lineForRow(i), buffer.lineEndingForRow(i)] \
      for i in [0...buffer.getLineCount()]
    )

    insertions = []
    for cursor, i in editor.getCursors()
      head = cursor.marker.getHeadBufferPosition()
      tail = cursor.marker.getTailBufferPosition()
      insertions.push([head.row, head.column, "[#{i}]"])
      insertions.push([tail.row, tail.column, "(#{i})"]) if not head.isEqual(tail)

    for [row, column, text] in insertions.sort().reverse()
      [line, ending] = linesWithEndings[row]
      line = line.slice(0, column) + text + line.slice(column)
      linesWithEndings[row] = [line, ending]

    (lineWithEnding.join('') for lineWithEnding in linesWithEndings).join('')
