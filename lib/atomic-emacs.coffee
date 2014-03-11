getActiveEditor = (event) ->
  event.targetView().editor

getCursorMarker = (editor) ->
  if editor then editor.getMarkers()[0] else false

doMotion = (event, cursorMarker, selectMotion, defaultMotion) ->
  if cursorMarker and cursorMarker.retainSelection
    if selectMotion then do selectMotion else event.abortKeyBinding()
  else
    if defaultMotion then do defaultMotion else event.abortKeyBinding()

module.exports =
  activate: ->
    atom.workspaceView.command "atomic-emacs:upcase-region", (event) => @upcaseRegion(event)
    atom.workspaceView.command "atomic-emacs:downcase-region", (event) => @downcaseRegion(event)
    atom.workspaceView.command "atomic-emacs:open-line", (event) => @openLine(event)
    atom.workspaceView.command "atomic-emacs:transpose-chars", (event) => @transposeChars(event)
    atom.workspaceView.command "atomic-emacs:transpose-lines", (event) => @transposeLines(event)
    atom.workspaceView.command "atomic-emacs:mark-whole-buffer", (event) => @markWholeBuffer(event)
    atom.workspaceView.command "atomic-emacs:set-mark", (event) => @setMark(event)
    atom.workspaceView.command "atomic-emacs:remove-mark", (event) => @removeMark(event)
    atom.workspaceView.command "atomic-emacs:exchange-point-and-mark", (event) => @exchangePointAndMark(event)
    atom.workspaceView.command "atomic-emacs:copy", (event) => @copy(event)
    atom.workspaceView.command "atomic-emacs:kill-region", (event) => @killRegion(event)
    atom.workspaceView.command "atomic-emacs:forward-char", (event) => @forwardChar(event)
    atom.workspaceView.command "atomic-emacs:backward-char", (event) => @backwardChar(event)
    atom.workspaceView.command "atomic-emacs:next-line", (event) => @nextLine(event)
    atom.workspaceView.command "atomic-emacs:previous-line", (event) => @previousLine(event)
    atom.workspaceView.command "atomic-emacs:move-beginning-of-line", (event) => @moveBeginningOfLine(event)
    atom.workspaceView.command "atomic-emacs:move-end-of-line", (event) => @moveEndOfLine(event)
    atom.workspaceView.command "atomic-emacs:beginning-of-buffer", (event) => @beginningOfBuffer(event)
    atom.workspaceView.command "atomic-emacs:end-of-buffer", (event) => @endOfBuffer(event)
    atom.workspaceView.command "atomic-emacs:back-to-indentation", (event) => @backToIndentation(event)
    atom.workspaceView.command "atomic-emacs:scroll-up", (event) => @scrollUp(event)
    atom.workspaceView.command "atomic-emacs:scroll-down", (event) => @scrollDown(event)

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

  transposeLines: (event) ->
    editor = getActiveEditor(event)

    editor.transact(->
      editor.moveCursorToBeginningOfLine()
      editor.cutToEndOfLine()
      editor.moveCursorUp()
      editor.insertNewline()
      editor.moveCursorUp()
      editor.pasteText()
      editor.moveCursorToBeginningOfLine()
      editor.indent()
      editor.moveCursorDown()
      editor.moveCursorToBeginningOfLine()
      editor.indent()
      editor.moveCursorDown()
      editor.deleteLine())

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
    firstRow = editorView.getFirstVisibleScreenRow()
    lastRow = editorView.getLastVisibleScreenRow()
    currentRow = editor.cursors[0].getBufferRow()
    rowCount = (lastRow - firstRow) - (lastRow - currentRow)

    editorView.scrollToBufferPosition([Math.floor(firstRow / 2), 0])
    doMotion(event,
      getCursorMarker(editor),
      (-> editor.selectUp(rowCount)),
      (-> editor.moveCursorUp(rowCount)))
