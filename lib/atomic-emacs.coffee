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
  Mark: Mark

  attachInstance: (editorView, editor) ->
    editorView._atomicEmacs ?= new AtomicEmacs(editorView, editor)

  activate: ->
    atom.workspaceView.eachEditorView (editorView) ->
      atomicEmacs = new AtomicEmacs(editorView, editorView.editor)
      editorView.command "atomic-emacs:upcase-region", (event) => atomicEmacs.upcaseRegion(event)
      editorView.command "atomic-emacs:downcase-region", (event) => atomicEmacs.downcaseRegion(event)
      editorView.command "atomic-emacs:open-line", (event) => atomicEmacs.openLine(event)
      editorView.command "atomic-emacs:transpose-chars", (event) => atomicEmacs.transposeChars(event)
      editorView.command "atomic-emacs:transpose-words", (event) => atomicEmacs.transposeWords(event)
      editorView.command "atomic-emacs:transpose-lines", (event) => atomicEmacs.transposeLines(event)
      editorView.command "atomic-emacs:mark-whole-buffer", (event) => atomicEmacs.markWholeBuffer(event)
      editorView.command "atomic-emacs:set-mark", (event) => atomicEmacs.setMark(event)
      editorView.command "atomic-emacs:exchange-point-and-mark", (event) => atomicEmacs.exchangePointAndMark(event)
      editorView.command "atomic-emacs:copy", (event) => atomicEmacs.copy(event)
      editorView.command "atomic-emacs:forward-char", (event) => atomicEmacs.forwardChar(event)
      editorView.command "atomic-emacs:backward-char", (event) => atomicEmacs.backwardChar(event)
      editorView.command "atomic-emacs:forward-word", (event) => atomicEmacs.forwardWord(event)
      editorView.command "atomic-emacs:kill-word", (event) => atomicEmacs.killWord(event)
      editorView.command "atomic-emacs:next-line", (event) => atomicEmacs.nextLine(event)
      editorView.command "atomic-emacs:previous-line", (event) => atomicEmacs.previousLine(event)
      editorView.command "atomic-emacs:beginning-of-buffer", (event) => atomicEmacs.beginningOfBuffer(event)
      editorView.command "atomic-emacs:end-of-buffer", (event) => atomicEmacs.endOfBuffer(event)
      editorView.command "atomic-emacs:scroll-up", (event) => atomicEmacs.scrollUp(event)
      editorView.command "atomic-emacs:scroll-down", (event) => atomicEmacs.scrollDown(event)
      editorView.command "atomic-emacs:backward-paragraph", (event) => atomicEmacs.backwardParagraph(event)
      editorView.command "atomic-emacs:forward-paragraph", (event) => atomicEmacs.forwardParagraph(event)
      editorView.command "atomic-emacs:backward-word", (event) => atomicEmacs.backwardWord(event)
      editorView.command "atomic-emacs:backward-kill-word", (event) => atomicEmacs.backwardKillWord(event)
      editorView.command "atomic-emacs:just-one-space", (event) => atomicEmacs.justOneSpace(event)
      editorView.command "atomic-emacs:delete-horizontal-space", (event) => atomicEmacs.deleteHorizontalSpace(event)
      editorView.command "atomic-emacs:recenter-top-bottom", (event) => atomicEmacs.recenterTopBottom(event)
      editorView.command "core:cancel", (event) => atomicEmacs.keyboardQuit(event)

class AtomicEmacs
  constructor: (@editorView, @editor) ->

  Mark: Mark

  upcaseRegion: (event) ->
    @editor.upperCase()

  downcaseRegion: (event) ->
    @editor.lowerCase()

  openLine: (event) ->
    @editor.insertNewline()
    @editor.moveCursorUp()

  transposeChars: (event) ->
    @editor.transpose()
    @editor.moveCursorRight()

  transposeWords: (event) ->
    @editor.transact =>
      for cursor in @editor.getCursors()
        cursorTools = new CursorTools(cursor)
        cursorTools.skipNonWordCharactersBackward()

        word1 = cursorTools.extractWord()
        word1Pos = cursor.getBufferPosition()
        cursorTools.skipNonWordCharactersForward()
        if @editor.getEofBufferPosition().isEqual(cursor.getBufferPosition())
          # No second word - put the first word back.
          @editor.setTextInBufferRange([word1Pos, word1Pos], word1)
          cursorTools.skipNonWordCharactersBackward()
        else
          word2 = cursorTools.extractWord()
          word2Pos = cursor.getBufferPosition()
          @editor.setTextInBufferRange([word2Pos, word2Pos], word1)
          @editor.setTextInBufferRange([word1Pos, word1Pos], word2)
        cursor.setBufferPosition(cursor.getBufferPosition())

  transposeLines: (event) ->
    cursor = @editor.getCursor()
    row = cursor.getBufferRow()

    @editor.transact =>
      if row == 0
        endLineIfNecessary(cursor)
        cursor.moveDown()
        row += 1
      endLineIfNecessary(cursor)

      text = @editor.getTextInBufferRange([[row, 0], [row + 1, 0]])
      @editor.deleteLine(row)
      @editor.setTextInBufferRange([[row - 1, 0], [row - 1, 0]], text)

  markWholeBuffer: (event) ->
    @editor.selectAll()

  setMark: (event) ->
    for cursor in @editor.getCursors()
      Mark.for(cursor).set().activate()

  keyboardQuit: (event) ->
    deactivateCursors(@editor)

  exchangePointAndMark: (event) ->
    @editor.moveCursors (cursor) ->
      Mark.for(cursor).exchange()

  copy: (event) ->
    @editor.copySelectedText()
    deactivateCursors(@editor)

  forwardChar: (event) ->
    @editor.moveCursors (cursor) ->
      cursor.moveRight()

  backwardChar: (event) ->
    @editor.moveCursors (cursor) ->
      cursor.moveLeft()

  forwardWord: (event) ->
    @editor.moveCursors (cursor) ->
      tools = new CursorTools(cursor)
      tools.skipNonWordCharactersForward()
      tools.skipWordCharactersForward()

  backwardWord: (event) ->
    @editor.moveCursors (cursor) ->
      tools = new CursorTools(cursor)
      tools.skipNonWordCharactersBackward()
      tools.skipWordCharactersBackward()

  nextLine: (event) ->
    if atom.workspaceView.find('.fuzzy-finder').view() or
       atom.workspaceView.find('.command-palette').view()
      event.abortKeyBinding()

    @editor.moveCursors (cursor) ->
      cursor.moveDown()

  previousLine: (event) ->
    if atom.workspaceView.find('.fuzzy-finder').view() or
       atom.workspaceView.find('.command-palette').view()
      event.abortKeyBinding()

    @editor.moveCursors (cursor) ->
      cursor.moveUp()

  scrollUp: (event) ->
    firstRow = @editorView.getFirstVisibleScreenRow()
    lastRow = @editorView.getLastVisibleScreenRow()
    currentRow = @editor.cursors[0].getBufferRow()
    rowCount = (lastRow - firstRow) - (currentRow - firstRow)

    @editorView.scrollToBufferPosition([lastRow * 2, 0])
    @editor.moveCursorDown(rowCount)

  scrollDown: (event) ->
    firstRow = @editorView.getFirstVisibleScreenRow()
    lastRow = @editorView.getLastVisibleScreenRow()
    currentRow = @editor.cursors[0].getBufferRow()
    rowCount = (lastRow - firstRow) - (lastRow - currentRow)

    @editorView.scrollToBufferPosition([Math.floor(firstRow / 2), 0])
    @editor.moveCursorUp(rowCount)

  backwardParagraph: (event) ->
    for cursor in @editor.getCursors()
      currentRow = @editor.getCursorBufferPosition().row

      break if currentRow <= 0

      cursorTools = new CursorTools(cursor)
      blankRow = cursorTools.locateBackward(/^\s+$|^\s*$/).start.row

      while currentRow == blankRow
        break if currentRow <= 0

        @editor.moveCursorUp()

        currentRow = @editor.getCursorBufferPosition().row
        blankRange = cursorTools.locateBackward(/^\s+$|^\s*$/)
        blankRow = if blankRange then blankRange.start.row else 0

      rowCount = currentRow - blankRow
      @editor.moveCursorUp(rowCount)

  forwardParagraph: (event) ->
    lineCount = @editor.buffer.getLineCount() - 1

    for cursor in @editor.getCursors()
      currentRow = @editor.getCursorBufferPosition().row
      break if currentRow >= lineCount

      cursorTools = new CursorTools(cursor)
      blankRow = cursorTools.locateForward(/^\s+$|^\s*$/).start.row

      while currentRow == blankRow
        @editor.moveCursorDown()

        currentRow = @editor.getCursorBufferPosition().row
        blankRow = cursorTools.locateForward(/^\s+$|^\s*$/).start.row

      rowCount = blankRow - currentRow
      @editor.moveCursorDown(rowCount)

  backwardKillWord: (event) ->
    @editor.transact =>
      for selection in @editor.getSelections()
        selection.modifySelection ->
          if selection.isEmpty()
            cursorTools = new CursorTools(selection.cursor)
            cursorTools.skipNonWordCharactersBackward()
            cursorTools.skipWordCharactersBackward()
          selection.deleteSelectedText()

  killWord: (event) ->
    @editor.transact =>
      for selection in @editor.getSelections()
        selection.modifySelection ->
          if selection.isEmpty()
            cursorTools = new CursorTools(selection.cursor)
            cursorTools.skipNonWordCharactersForward()
            cursorTools.skipWordCharactersForward()
          selection.deleteSelectedText()

  justOneSpace: (event) ->
    for cursor in @editor.cursors
      range = horizontalSpaceRange(cursor)
      @editor.setTextInBufferRange(range, ' ')

  deleteHorizontalSpace: (event) ->
    for cursor in @editor.cursors
      range = horizontalSpaceRange(cursor)
      @editor.setTextInBufferRange(range, '')

  recenterTopBottom: (event) ->
    minRow = Math.min((c.getBufferRow() for c in @editor.getCursors())...)
    maxRow = Math.max((c.getBufferRow() for c in @editor.getCursors())...)
    minOffset = @editorView.pixelPositionForBufferPosition([minRow, 0])
    maxOffset = @editorView.pixelPositionForBufferPosition([maxRow, 0])
    @editorView.scrollTop((minOffset.top + maxOffset.top - @editorView.scrollView.height())/2)
