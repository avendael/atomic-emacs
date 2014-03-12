module.exports =
  open: (state) ->
    editor = atom.project.openSync()
    @set(editor, state)

  set: (editor, state) ->
    editor.setText(state)
    re = /\[(\d+)\]/g

    cursors = []
    editor.scan re, (hit) ->
      i = parseInt(hit.match.slice(1, 2), 10)
      cursors[i] = hit.range.start
      hit.replace('')

    for position, i in cursors
      position ?= [0, 0]
      if i > 0
        editor.addCursorAtBufferPosition(position)
      else
        editor.getCursors()[0].setBufferPosition(position)

    editor

  get: (editor) ->
    text = null
    editor.transact ->
      for cursor, i in editor.getCursors()
        pos = cursor.getBufferPosition()
        editor.setTextInBufferRange([pos, pos], "[#{i}]")
      text = editor.getText()
      editor.abortTransaction()
    text
