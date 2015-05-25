{CompositeDisposable} = require 'atom'
CursorTools = require './cursor-tools'
Mark = require './mark'

horizontalSpaceRange = (cursor) ->
  cursorTools = new CursorTools(cursor)
  cursorTools.skipCharactersBackward(' \t')
  start = cursor.getBufferPosition()
  cursorTools.skipCharactersForward(' \t')
  end = cursor.getBufferPosition()
  [start, end]

endLineIfNecessary = (cursor) ->
  row = cursor.getBufferPosition().row
  editor = cursor.editor
  if row == editor.getLineCount() - 1
    length = cursor.getCurrentBufferLine().length
    editor.setTextInBufferRange([[row, length], [row, length]], "\n")

deactivateCursors = (editor) ->
  for cursor in editor.getCursors()
    Mark.for(cursor).deactivate()

module.exports =
class AtomicEmacs
  editor: ->
    atom.workspace.getActiveTextEditor()

  upcaseRegion: (event) ->
    @editor().upperCase()

  downcaseRegion: (event) ->
    @editor().lowerCase()

  openLine: (event) ->
    editor = @editor()
    editor.insertNewline()
    editor.moveUp()

  transposeChars: (event) ->
    editor = @editor()
    editor.transpose()
    editor.moveCursorRight()

  transposeWords: (event) ->
    editor = @editor()
    editor.transact =>
      for cursor in editor.getCursors()
        cursorTools = new CursorTools(cursor)
        cursorTools.skipNonWordCharactersBackward()

        word1 = cursorTools.extractWord()
        word1Pos = cursor.getBufferPosition()
        cursorTools.skipNonWordCharactersForward()
        if editor.getEofBufferPosition().isEqual(cursor.getBufferPosition())
          # No second word - put the first word back.
          editor.setTextInBufferRange([word1Pos, word1Pos], word1)
          cursorTools.skipNonWordCharactersBackward()
        else
          word2 = cursorTools.extractWord()
          word2Pos = cursor.getBufferPosition()
          editor.setTextInBufferRange([word2Pos, word2Pos], word1)
          editor.setTextInBufferRange([word1Pos, word1Pos], word2)
        cursor.setBufferPosition(cursor.getBufferPosition())

  transposeLines: (event) ->
    editor = @editor()
    cursor = editor.getLastCursor()
    row = cursor.getBufferRow()

    editor.transact =>
      if row == 0
        endLineIfNecessary(cursor)
        cursor.moveDown()
        row += 1
      endLineIfNecessary(cursor)

      text = editor.getTextInBufferRange([[row, 0], [row + 1, 0]])
      editor.deleteLine(row)
      editor.setTextInBufferRange([[row - 1, 0], [row - 1, 0]], text)

  setMark: (event) ->
    for cursor in @editor().getCursors()
      Mark.for(cursor).set().activate()

  keyboardQuit: (event) ->
    deactivateCursors(@editor())

  exchangePointAndMark: (event) ->
    @editor().moveCursors (cursor) ->
      Mark.for(cursor).exchange()

  copy: (event) ->
    editor = @editor()
    editor.copySelectedText()
    deactivateCursors(editor)

  forwardWord: (event) ->
    @editor().moveCursors (cursor) ->
      tools = new CursorTools(cursor)
      tools.skipNonWordCharactersForward()
      tools.skipWordCharactersForward()

  backwardWord: (event) ->
    @editor().moveCursors (cursor) ->
      tools = new CursorTools(cursor)
      tools.skipNonWordCharactersBackward()
      tools.skipWordCharactersBackward()

  backwardParagraph: (event) ->
    editor = @editor()
    for cursor in editor.getCursors()
      currentRow = editor.getCursorBufferPosition().row

      break if currentRow <= 0

      cursorTools = new CursorTools(cursor)
      blankRow = cursorTools.locateBackward(/^\s+$|^\s*$/).start.row

      while currentRow == blankRow
        break if currentRow <= 0

        editor.moveUp()

        currentRow = editor.getCursorBufferPosition().row
        blankRange = cursorTools.locateBackward(/^\s+$|^\s*$/)
        blankRow = if blankRange then blankRange.start.row else 0

      rowCount = currentRow - blankRow
      editor.moveUp(rowCount)

  forwardParagraph: (event) ->
    editor = @editor()
    lineCount = editor.buffer.getLineCount() - 1

    for cursor in editor.getCursors()
      currentRow = editor.getCursorBufferPosition().row
      break if currentRow >= lineCount

      cursorTools = new CursorTools(cursor)
      blankRow = cursorTools.locateForward(/^\s+$|^\s*$/).start.row

      while currentRow == blankRow
        editor.moveDown()

        currentRow = editor.getCursorBufferPosition().row
        blankRow = cursorTools.locateForward(/^\s+$|^\s*$/).start.row

      rowCount = blankRow - currentRow
      editor.moveDown(rowCount)

  backwardKillWord: (event) ->
    editor = @editor()
    editor.transact =>
      for selection in editor.getSelections()
        selection.modifySelection ->
          if selection.isEmpty()
            cursorTools = new CursorTools(selection.cursor)
            cursorTools.skipNonWordCharactersBackward()
            cursorTools.skipWordCharactersBackward()
          selection.deleteSelectedText()

  killWord: (event) ->
    editor = @editor()
    editor.transact =>
      for selection in editor.getSelections()
        selection.modifySelection ->
          if selection.isEmpty()
            cursorTools = new CursorTools(selection.cursor)
            cursorTools.skipNonWordCharactersForward()
            cursorTools.skipWordCharactersForward()
          selection.deleteSelectedText()

  justOneSpace: (event) ->
    editor = @editor()
    for cursor in editor.cursors
      range = horizontalSpaceRange(cursor)
      editor.setTextInBufferRange(range, ' ')

  deleteHorizontalSpace: (event) ->
    editor = @editor()
    for cursor in editor.cursors
      range = horizontalSpaceRange(cursor)
      editor.setTextInBufferRange(range, '')

  recenterTopBottom: (event) ->
    editor = @editor()
    return unless editor
    editorElement = atom.views.getView(editor)
    minRow = Math.min((c.getBufferRow() for c in editor.getCursors())...)
    maxRow = Math.max((c.getBufferRow() for c in editor.getCursors())...)
    minOffset = editorElement.pixelPositionForBufferPosition([minRow, 0])
    maxOffset = editorElement.pixelPositionForBufferPosition([maxRow, 0])
    editor.setScrollTop((minOffset.top + maxOffset.top - editor.getHeight())/2)

  deleteIndentation: =>
    editor = @editor()
    return unless editor
    editor.transact ->
      editor.moveCursorUp()
      editor.joinLines()
