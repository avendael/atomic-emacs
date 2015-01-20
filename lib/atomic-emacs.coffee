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
  Mark: Mark
  disposables: new CompositeDisposable

  attachInstance: (editorView, editor) ->
    editorView._atomicEmacs ?= new AtomicEmacs(null, editor)

  activate: ->
    atom.workspace.observeTextEditors (editor) =>
      atomicEmacs = new AtomicEmacs(null, editor)
      @disposables.add atom.commands.add 'atom-text-editor',
          "atomic-emacs:backward-char": (event) -> atomicEmacs.backwardChar(event)
          "atomic-emacs:backward-kill-word": (event) -> atomicEmacs.backwardKillWord(event)
          "atomic-emacs:backward-paragraph": (event) -> atomicEmacs.backwardParagraph(event)
          "atomic-emacs:backward-word": (event) -> atomicEmacs.backwardWord(event)
          "atomic-emacs:beginning-of-buffer": (event) -> atomicEmacs.beginningOfBuffer(event)
          "atomic-emacs:copy": (event) -> atomicEmacs.copy(event)
          "atomic-emacs:delete-horizontal-space": (event) -> atomicEmacs.deleteHorizontalSpace(event)
          "atomic-emacs:downcase-region": (event) -> atomicEmacs.downcaseRegion(event)
          "atomic-emacs:end-of-buffer": (event) -> atomicEmacs.endOfBuffer(event)
          "atomic-emacs:exchange-point-and-mark": (event) -> atomicEmacs.exchangePointAndMark(event)
          "atomic-emacs:forward-char": (event) -> atomicEmacs.forwardChar(event)
          "atomic-emacs:forward-paragraph": (event) -> atomicEmacs.forwardParagraph(event)
          "atomic-emacs:forward-word": (event) -> atomicEmacs.forwardWord(event)
          "atomic-emacs:just-one-space": (event) -> atomicEmacs.justOneSpace(event)
          "atomic-emacs:kill-word": (event) -> atomicEmacs.killWord(event)
          "atomic-emacs:mark-whole-buffer": (event) -> atomicEmacs.markWholeBuffer(event)
          "atomic-emacs:next-line": (event) -> atomicEmacs.nextLine(event)
          "atomic-emacs:open-line": (event) -> atomicEmacs.openLine(event)
          "atomic-emacs:previous-line": (event) -> atomicEmacs.previousLine(event)
          "atomic-emacs:recenter-top-bottom": (event) -> atomicEmacs.recenterTopBottom(event)
          "atomic-emacs:scroll-down": (event) -> atomicEmacs.scrollDown(event)
          "atomic-emacs:scroll-up": (event) -> atomicEmacs.scrollUp(event)
          "atomic-emacs:set-mark": (event) -> atomicEmacs.setMark(event)
          "atomic-emacs:transpose-chars": (event) -> atomicEmacs.transposeChars(event)
          "atomic-emacs:transpose-lines": (event) -> atomicEmacs.transposeLines(event)
          "atomic-emacs:transpose-words": (event) -> atomicEmacs.transposeWords(event)
          "atomic-emacs:upcase-region": (event) -> atomicEmacs.upcaseRegion(event)
          "core:cancel": (event) -> atomicEmacs.keyboardQuit(event)

  destroy: ->
    @disposables.dispose()

class AtomicEmacs
  constructor: (_, @editor) ->

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
    @editor.moveCursors (cursor) ->
      cursor.moveDown()

  previousLine: (event) ->
    @editor.moveCursors (cursor) ->
      cursor.moveUp()

  scrollUp: (event) ->
    [firstRow,lastRow] = @editor.getVisibleRowRange()
    currentRow = @editor.cursors[0].getBufferRow()
    rowCount = (lastRow - firstRow) - (currentRow - firstRow)

    @editor.scrollToBufferPosition([lastRow * 2, 0])
    @editor.moveCursorDown(rowCount)

  scrollDown: (event) ->
    [firstRow,lastRow] = @editor.getVisibleRowRange()
    currentRow = @editor.cursors[0].getBufferRow()
    rowCount = (lastRow - firstRow) - (lastRow - currentRow)

    @editor.scrollToBufferPosition([Math.floor(firstRow / 2), 0])
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
    minOffset = @editor.pixelPositionForBufferPosition([minRow, 0])
    maxOffset = @editor.pixelPositionForBufferPosition([maxRow, 0])
    @editor.setScrollTop((minOffset.top + maxOffset.top - @editor.getHeight())/2)
