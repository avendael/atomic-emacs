CursorTools = require '../lib/cursor-tools'

getActiveEditor = (event) ->
  event.targetView().editor

getCursorMarker = (editor) ->
  if editor then editor.getMarkers()[0] else false

doMotion = (event, cursorMarker, selectMotion, defaultMotion) ->
  if cursorMarker and cursorMarker.retainSelection
    if selectMotion then do selectMotion else event.abortKeyBinding()
  else
    if defaultMotion then do defaultMotion else event.abortKeyBinding()

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

module.exports =
  activate: ->
    atom.workspaceView.command "atomic-emacs:upcase-region", (event) => @upcaseRegion(event)
    atom.workspaceView.command "atomic-emacs:downcase-region", (event) => @downcaseRegion(event)
    atom.workspaceView.command "atomic-emacs:open-line", (event) => @openLine(event)
    atom.workspaceView.command "atomic-emacs:transpose-chars", (event) => @transposeChars(event)
    atom.workspaceView.command "atomic-emacs:transpose-words", (event) => @transposeWords(event)
    atom.workspaceView.command "atomic-emacs:transpose-lines", (event) => @transposeLines(event)
    atom.workspaceView.command "atomic-emacs:mark-whole-buffer", (event) => @markWholeBuffer(event)
    atom.workspaceView.command "atomic-emacs:set-mark", (event) => @setMark(event)
    atom.workspaceView.command "atomic-emacs:remove-mark", (event) => @removeMark(event)
    atom.workspaceView.command "atomic-emacs:exchange-point-and-mark", (event) => @exchangePointAndMark(event)
    atom.workspaceView.command "atomic-emacs:copy", (event) => @copy(event)
    atom.workspaceView.command "atomic-emacs:kill-region", (event) => @killRegion(event)
    atom.workspaceView.command "atomic-emacs:forward-char", (event) => @forwardChar(event)
    atom.workspaceView.command "atomic-emacs:backward-char", (event) => @backwardChar(event)
    atom.workspaceView.command "atomic-emacs:forward-word", (event) => @forwardWord(event)
    atom.workspaceView.command "atomic-emacs:backward-word", (event) => @backwardWord(event)
    atom.workspaceView.command "atomic-emacs:next-line", (event) => @nextLine(event)
    atom.workspaceView.command "atomic-emacs:previous-line", (event) => @previousLine(event)
    atom.workspaceView.command "atomic-emacs:move-beginning-of-line", (event) => @moveBeginningOfLine(event)
    atom.workspaceView.command "atomic-emacs:move-end-of-line", (event) => @moveEndOfLine(event)
    atom.workspaceView.command "atomic-emacs:beginning-of-buffer", (event) => @beginningOfBuffer(event)
    atom.workspaceView.command "atomic-emacs:end-of-buffer", (event) => @endOfBuffer(event)
    atom.workspaceView.command "atomic-emacs:back-to-indentation", (event) => @backToIndentation(event)
    atom.workspaceView.command "atomic-emacs:scroll-up", (event) => @scrollUp(event)
    atom.workspaceView.command "atomic-emacs:scroll-down", (event) => @scrollDown(event)
    atom.workspaceView.command "atomic-emacs:backward-paragraph", (event) => @backwardParagraph(event)
    atom.workspaceView.command "atomic-emacs:forward-paragraph", (event) => @forwardParagraph(event)
    atom.workspaceView.command "atomic-emacs:just-one-space", (event) => @justOneSpace(event)
    atom.workspaceView.command "atomic-emacs:delete-horizontal-space", (event) => @deleteHorizontalSpace(event)
    atom.workspaceView.command "atomic-emacs:recenter-top-bottom", (event) => @recenterTopBottom(event)

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
    cursorMarker = editor.getMarkers()[0]

    if cursorMarker.retainSelection
      editor.clearSelections()
    else
      cursorMarker.retainSelection = true

  removeMark: (event) ->
    editor = getActiveEditor(event)
    cursorMarker = if editor then editor.getMarkers()[0] else false

    if cursorMarker and cursorMarker.retainSelection
      cursorMarker.retainSelection = false
      editor.clearSelections()
    else
      event.abortKeyBinding()

  exchangePointAndMark: (event) ->
    marker = getActiveEditor(event).getLastSelectionInBuffer().marker.bufferMarker
    headPosition = marker.getHeadPosition()
    tailPosition = marker.getTailPosition()

    marker.setHeadPosition(tailPosition)
    marker.setTailPosition(headPosition)

  copy: (event) ->
    editor = getActiveEditor(event)
    cursorMarker = editor.getMarkers()[0]

    editor.copySelectedText()
    cursorMarker.retainSelection = false
    editor.clearSelections()

  killRegion: (event) ->
    editor = getActiveEditor(event)

    try
      editor.cutSelectedText()
      @removeMark()
    catch
      event.abortKeyBinding()

  forwardChar: (event) ->
    editor = getActiveEditor(event)

    doMotion(event, getCursorMarker(editor), -> editor.selectRight())

  backwardChar: (event) ->
    editor = getActiveEditor(event)

    doMotion(event, getCursorMarker(editor), -> editor.selectLeft())

  forwardWord: (event) ->
    editor = getActiveEditor(event)

    doMotion(event, getCursorMarker(editor), -> editor.selectToEndOfWord())

  backwardWord: (event) ->
    editor = getActiveEditor(event)

    doMotion(event, getCursorMarker(editor), -> editor.selectToBeginningOfWord())

  nextLine: (event) ->
    editor = getActiveEditor(event)

    doMotion(event, getCursorMarker(editor), -> editor.selectDown())

  previousLine: (event) ->
    editor = getActiveEditor(event)

    doMotion(event, getCursorMarker(editor), -> editor.selectUp())

  moveBeginningOfLine: (event) ->
    editor = getActiveEditor(event)

    doMotion(event, getCursorMarker(editor), -> editor.selectToBeginningOfLine())

  moveEndOfLine: (event) ->
    editor = getActiveEditor(event)

    doMotion(event, getCursorMarker(editor), -> editor.selectToEndOfLine())

  beginningOfBuffer: (event) ->
    editor = getActiveEditor(event)

    doMotion(event,
      getCursorMarker(editor),
      (-> editor.selectToTop()),
      (-> editor.moveCursorToTop()))

  endOfBuffer: (event) ->
    editor = getActiveEditor(event)

    doMotion(event,
      getCursorMarker(editor),
      (-> editor.selectToBottom()),
      (-> editor.moveCursorToBottom()))

  backToIndentation: (event) ->
    editor = getActiveEditor(event)

    doMotion(event,
      getCursorMarker(editor),
      (-> editor.selectToFirstCharacterOfLine()),
      (-> editor.moveCursorToFirstCharacterOfLine()))

  scrollUp: (event) ->
    editor = getActiveEditor(event)
    editorView = atom.workspaceView.find('.editor.is-focused').view()

    if editorView
      firstRow = editorView.getFirstVisibleScreenRow()
      lastRow = editorView.getLastVisibleScreenRow()
      currentRow = editor.cursors[0].getBufferRow()
      rowCount = (lastRow - firstRow) - (currentRow - firstRow)

      editorView.scrollToBufferPosition([lastRow * 2, 0])

    doMotion(event,
      getCursorMarker(editor),
      (-> editor.selectDown(rowCount)),
      (-> editor.moveCursorDown(rowCount)))

  scrollDown: (event) ->
    editor = getActiveEditor(event)
    editorView = atom.workspaceView.find('.editor.is-focused').view()

    if editorView
      firstRow = editorView.getFirstVisibleScreenRow()
      lastRow = editorView.getLastVisibleScreenRow()
      currentRow = editor.cursors[0].getBufferRow()
      rowCount = (lastRow - firstRow) - (lastRow - currentRow)

      editorView.scrollToBufferPosition([Math.floor(firstRow / 2), 0])

    doMotion(event,
      getCursorMarker(editor),
      (-> editor.selectUp(rowCount)),
      (-> editor.moveCursorUp(rowCount)))

  backwardParagraph: (event) ->
    editor = getActiveEditor(event)

    for cursor in editor.getCursors()
      currentRow = editor.getCursorBufferPosition().row

      break if currentRow <= 0

      cursorTools = new CursorTools(cursor)
      blankRow = cursorTools.locateBackward(/^\s+$|^\s*$/).start.row

      while currentRow == blankRow
        break if currentRow <= 0

        doMotion(event,
          getCursorMarker(editor),
          (-> editor.selectUp()),
          (-> editor.moveCursorUp()))

        currentRow = editor.getCursorBufferPosition().row
        blankRange = cursorTools.locateBackward(/^\s+$|^\s*$/)
        blankRow = if blankRange then blankRange.start.row else 0

      rowCount = currentRow - blankRow

      doMotion(event,
        getCursorMarker(editor),
        (-> editor.selectUp(rowCount))
        (-> editor.moveCursorUp(rowCount)))

  forwardParagraph: (event) ->
    editor = getActiveEditor(event)
    lineCount = editor.buffer.getLineCount() - 1

    for cursor in editor.getCursors()
      currentRow = editor.getCursorBufferPosition().row
      break if currentRow >= lineCount

      cursorTools = new CursorTools(cursor)
      blankRow = cursorTools.locateForward(/^\s+$|^\s*$/).start.row

      while currentRow == blankRow
        doMotion(event,
          getCursorMarker(editor),
          (-> editor.selectDown()),
          (-> editor.moveCursorDown()))

        currentRow = editor.getCursorBufferPosition().row
        blankRow = cursorTools.locateForward(/^\s+$|^\s*$/).start.row

      rowCount = blankRow - currentRow

      doMotion(event,
        getCursorMarker(editor),
        (-> editor.selectDown(rowCount))
        (-> editor.moveCursorDown(rowCount)))

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
