module.exports =
  activate: ->
    atom.workspaceView.command "atomic-emacs:upcase-region", => @upcaseRegion()
    atom.workspaceView.command "atomic-emacs:downcase-region", => @downcaseRegion()
    atom.workspaceView.command "atomic-emacs:open-line", => @openLine()
    atom.workspaceView.command "atomic-emacs:transpose-chars", => @transposeChars()
    atom.workspaceView.command "atomic-emacs:transpose-lines", => @transposeLines()
    atom.workspaceView.command "atomic-emacs:mark-whole-buffer", => @markWholeBuffer()
    atom.workspaceView.command "atomic-emacs:set-mark", => @setMark()
    atom.workspaceView.command "atomic-emacs:remove-mark", (event) => @removeMark(event)
    atom.workspaceView.command "atomic-emacs:exchange-point-and-mark", => @exchangePointAndMark()
    atom.workspaceView.command "atomic-emacs:copy", => @copy()
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

  getActiveEditor: ->
    atom.workspace.getActiveEditor()

  doMotion: (event, selectMotion, defaultMotion) ->
    editor = @getActiveEditor()
    cursorMarker = if editor then editor.getMarkers()[0] else false

    if cursorMarker and cursorMarker.retainSelection
      editor[selectMotion]()
    else
      if defaultMotion then editor[defaultMotion]() else event.abortKeyBinding()

  upcaseRegion: ->
    @getActiveEditor().upperCase()

  downcaseRegion: ->
    @getActiveEditor().lowerCase()

  openLine: ->
    editor = @getActiveEditor()

    editor.insertNewline()
    editor.moveCursorUp()

  transposeChars: ->
    editor = @getActiveEditor()

    editor.transpose()
    editor.moveCursorRight()

  transposeLines: ->
    editor = @getActiveEditor()

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
      editor.deleteLine()
    )

  markWholeBuffer: ->
    @getActiveEditor().selectAll()

  setMark: ->
    editor = @getActiveEditor()
    cursorMarker = editor.getMarkers()[0]

    if cursorMarker.retainSelection
      editor.clearSelections()
    else
      cursorMarker.retainSelection = true

  removeMark: (event) ->
    editor = @getActiveEditor()
    cursorMarker = if editor then editor.getMarkers()[0] else false

    if cursorMarker and cursorMarker.retainSelection
      cursorMarker.retainSelection = false
      editor.clearSelections()
    else
      event.abortKeyBinding()

  exchangePointAndMark: ->
    marker = @getActiveEditor().getLastSelectionInBuffer().marker.bufferMarker
    headPosition = marker.getHeadPosition()
    tailPosition = marker.getTailPosition()

    marker.setHeadPosition(tailPosition)
    marker.setTailPosition(headPosition)

  copy: ->
    editor = @getActiveEditor()
    cursorMarker = editor.getMarkers()[0]

    editor.copySelectedText()
    cursorMarker.retainSelection = false
    editor.clearSelections()

  killRegion: (event) ->
    editor = @getActiveEditor()

    try
      editor.cutSelectedText()
      @removeMark()
    catch
      event.abortKeyBinding()

  forwardChar: (event) ->
    @doMotion(event, 'selectRight')

  backwardChar: (event) ->
    @doMotion(event, 'selectLeft')

  nextLine: (event) ->
    @doMotion(event, 'selectDown')

  previousLine: (event) ->
    @doMotion(event, 'selectUp')

  moveBeginningOfLine: (event) ->
    @doMotion(event, 'selectToBeginningOfLine')

  moveEndOfLine: (event) ->
    @doMotion(event, 'selectToEndOfLine')

  beginningOfBuffer: (event) ->
    @doMotion(event, 'selectToTop', 'moveCursorToTop')

  endOfBuffer: (event) ->
    @doMotion(event, 'selectToBottom', 'moveCursorToBottom')

  backToIndentation: (event) ->
    @doMotion(event, 'selectToFirstCharacterOfLine', 'moveCursorToFirstCharacterOfLine')
