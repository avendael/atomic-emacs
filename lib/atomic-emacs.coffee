CursorTools = require './cursor-tools'
Mark = require './mark'

getActiveEditor = (event) ->
  event.targetView().editor

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
  Mark: Mark

  activate: ->
    atom.workspaceView.command "atomic-emacs:upcase-region", (event) => @upcaseRegion(event)
    atom.workspaceView.command "atomic-emacs:downcase-region", (event) => @downcaseRegion(event)
    atom.workspaceView.command "atomic-emacs:open-line", (event) => @openLine(event)
    atom.workspaceView.command "atomic-emacs:transpose-chars", (event) => @transposeChars(event)
    atom.workspaceView.command "atomic-emacs:transpose-words", (event) => @transposeWords(event)
    atom.workspaceView.command "atomic-emacs:transpose-lines", (event) => @transposeLines(event)
    atom.workspaceView.command "atomic-emacs:mark-whole-buffer", (event) => @markWholeBuffer(event)
    atom.workspaceView.command "atomic-emacs:set-mark", (event) => @setMark(event)
    atom.workspaceView.command "atomic-emacs:exchange-point-and-mark", (event) => @exchangePointAndMark(event)
    atom.workspaceView.command "atomic-emacs:copy", (event) => @copy(event)
    atom.workspaceView.command "atomic-emacs:forward-char", (event) => @forwardChar(event)
    atom.workspaceView.command "atomic-emacs:backward-char", (event) => @backwardChar(event)
    atom.workspaceView.command "atomic-emacs:forward-word", (event) => @forwardWord(event)
    atom.workspaceView.command "atomic-emacs:kill-word", (event) => @killWord(event)
    atom.workspaceView.command "atomic-emacs:next-line", (event) => @nextLine(event)
    atom.workspaceView.command "atomic-emacs:previous-line", (event) => @previousLine(event)
    atom.workspaceView.command "atomic-emacs:beginning-of-buffer", (event) => @beginningOfBuffer(event)
    atom.workspaceView.command "atomic-emacs:end-of-buffer", (event) => @endOfBuffer(event)
    atom.workspaceView.command "atomic-emacs:scroll-up", (event) => @scrollUp(event)
    atom.workspaceView.command "atomic-emacs:scroll-down", (event) => @scrollDown(event)
    atom.workspaceView.command "atomic-emacs:backward-paragraph", (event) => @backwardParagraph(event)
    atom.workspaceView.command "atomic-emacs:forward-paragraph", (event) => @forwardParagraph(event)
    atom.workspaceView.command "atomic-emacs:backward-word", (event) => @backwardWord(event)
    atom.workspaceView.command "atomic-emacs:backward-kill-word", (event) => @backwardKillWord(event)
    atom.workspaceView.command "atomic-emacs:just-one-space", (event) => @justOneSpace(event)
    atom.workspaceView.command "atomic-emacs:delete-horizontal-space", (event) => @deleteHorizontalSpace(event)
    atom.workspaceView.command "atomic-emacs:recenter-top-bottom", (event) => @recenterTopBottom(event)
    atom.workspaceView.command "core:cancel", (event) => @keyboardQuit(event)

  upcaseRegion: (event) ->
    getActiveEditor(event).upperCase()

  downcaseRegion: (event) ->
    getActiveEditor(event).lowerCase()

  openLine: (event) ->
    editor = getActiveEditor(event)

    editor.insertNewline()
    editor.moveCursorUp()

  transposeChars: (event) ->
    editor = getActiveEditor(event)

    editor.transpose()
    editor.moveCursorRight()

  transposeWords: (event) ->
    editor = getActiveEditor(event)

    editor.transact ->
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
    editor = getActiveEditor(event)
    cursor = editor.getCursor()
    row = cursor.getBufferRow()

    editor.transact ->
      if row == 0
        endLineIfNecessary(cursor)
        cursor.moveDown()
        row += 1
      endLineIfNecessary(cursor)

      text = editor.getTextInBufferRange([[row, 0], [row + 1, 0]])
      editor.deleteLine(row)
      editor.setTextInBufferRange([[row - 1, 0], [row - 1, 0]], text)

  markWholeBuffer: (event) ->
    getActiveEditor(event).selectAll()

  setMark: (event) ->
    editor = getActiveEditor(event)
    for cursor in editor.getCursors()
      Mark.for(cursor).set().activate()

  keyboardQuit: (event) ->
    editor = getActiveEditor(event)
    deactivateCursors(editor)

  exchangePointAndMark: (event) ->
    editor = getActiveEditor(event)
    editor.moveCursors (cursor) ->
      Mark.for(cursor).exchange()

  copy: (event) ->
    editor = getActiveEditor(event)

    editor.copySelectedText()
    deactivateCursors(editor)

  forwardChar: (event) ->
    editor = getActiveEditor(event)
    editor.moveCursors (cursor) ->
      cursor.moveRight()

  backwardChar: (event) ->
    editor = getActiveEditor(event)
    editor.moveCursors (cursor) ->
      cursor.moveLeft()

  forwardWord: (event) ->
    editor = getActiveEditor(event)
    editor.moveCursors (cursor) ->
      tools = new CursorTools(cursor)
      tools.skipNonWordCharactersForward()
      tools.skipWordCharactersForward()

  backwardWord: (event) ->
    editor = getActiveEditor(event)
    editor.moveCursors (cursor) ->
      tools = new CursorTools(cursor)
      tools.skipNonWordCharactersBackward()
      tools.skipWordCharactersBackward()

  nextLine: (event) ->
    if atom.workspaceView.find('.fuzzy-finder').view() or
       atom.workspaceView.find('.command-palette').view()
      event.abortKeyBinding()

    editor = getActiveEditor(event)
    editor.moveCursors (cursor) ->
      cursor.moveDown()

  previousLine: (event) ->
    if atom.workspaceView.find('.fuzzy-finder').view() or
       atom.workspaceView.find('.command-palette').view()
      event.abortKeyBinding()

    editor = getActiveEditor(event)
    editor.moveCursors (cursor) ->
      cursor.moveUp()

  scrollUp: (event) ->
    editor = getActiveEditor(event)
    editorView = atom.workspaceView.find('.editor.is-focused').view()

    if editorView
      firstRow = editorView.getFirstVisibleScreenRow()
      lastRow = editorView.getLastVisibleScreenRow()
      currentRow = editor.cursors[0].getBufferRow()
      rowCount = (lastRow - firstRow) - (currentRow - firstRow)

      editorView.scrollToBufferPosition([lastRow * 2, 0])
      editor.moveCursorDown(rowCount)

  scrollDown: (event) ->
    editor = getActiveEditor(event)
    editorView = atom.workspaceView.find('.editor.is-focused').view()

    if editorView
      firstRow = editorView.getFirstVisibleScreenRow()
      lastRow = editorView.getLastVisibleScreenRow()
      currentRow = editor.cursors[0].getBufferRow()
      rowCount = (lastRow - firstRow) - (lastRow - currentRow)

      editorView.scrollToBufferPosition([Math.floor(firstRow / 2), 0])
      editor.moveCursorUp(rowCount)

  backwardParagraph: (event) ->
    editor = getActiveEditor(event)

    for cursor in editor.getCursors()
      currentRow = editor.getCursorBufferPosition().row

      break if currentRow <= 0

      cursorTools = new CursorTools(cursor)
      blankRow = cursorTools.locateBackward(/^\s+$|^\s*$/).start.row

      while currentRow == blankRow
        break if currentRow <= 0

        editor.moveCursorUp()

        currentRow = editor.getCursorBufferPosition().row
        blankRange = cursorTools.locateBackward(/^\s+$|^\s*$/)
        blankRow = if blankRange then blankRange.start.row else 0

      rowCount = currentRow - blankRow
      editor.moveCursorUp(rowCount)

  forwardParagraph: (event) ->
    editor = getActiveEditor(event)
    lineCount = editor.buffer.getLineCount() - 1

    for cursor in editor.getCursors()
      currentRow = editor.getCursorBufferPosition().row
      break if currentRow >= lineCount

      cursorTools = new CursorTools(cursor)
      blankRow = cursorTools.locateForward(/^\s+$|^\s*$/).start.row

      while currentRow == blankRow
        editor.moveCursorDown()

        currentRow = editor.getCursorBufferPosition().row
        blankRow = cursorTools.locateForward(/^\s+$|^\s*$/).start.row

      rowCount = blankRow - currentRow
      editor.moveCursorDown(rowCount)

  backwardKillWord: (event) ->
    editor = getActiveEditor(event)
    editor.transact ->
      for selection in editor.getSelections()
        selection.modifySelection ->
          if selection.isEmpty()
            cursorTools = new CursorTools(selection.cursor)
            cursorTools.skipNonWordCharactersBackward()
            cursorTools.skipWordCharactersBackward()
          selection.deleteSelectedText()

  killWord: (event) ->
    editor = getActiveEditor(event)
    editor.transact ->
      for selection in editor.getSelections()
        selection.modifySelection ->
          if selection.isEmpty()
            cursorTools = new CursorTools(selection.cursor)
            cursorTools.skipNonWordCharactersForward()
            cursorTools.skipWordCharactersForward()
          selection.deleteSelectedText()

  justOneSpace: (event) ->
    editor = getActiveEditor(event)
    for cursor in editor.cursors
      range = horizontalSpaceRange(cursor)
      editor.setTextInBufferRange(range, ' ')

  deleteHorizontalSpace: (event) ->
    editor = getActiveEditor(event)
    for cursor in editor.cursors
      range = horizontalSpaceRange(cursor)
      editor.setTextInBufferRange(range, '')

  recenterTopBottom: (event) ->
    editor = getActiveEditor(event)
    view = event.targetView()
    minRow = Math.min((c.getBufferRow() for c in editor.getCursors())...)
    maxRow = Math.max((c.getBufferRow() for c in editor.getCursors())...)
    minOffset = view.pixelPositionForBufferPosition([minRow, 0])
    maxOffset = view.pixelPositionForBufferPosition([maxRow, 0])
    view.scrollTop((minOffset.top + maxOffset.top - view.scrollView.height())/2)
