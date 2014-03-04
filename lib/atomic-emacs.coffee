module.exports =
  activate: ->
    atom.workspaceView.command "atomic-emacs:beginning-of-buffer", => @beginningOfBuffer()
    atom.workspaceView.command "atomic-emacs:end-of-buffer", => @endOfBuffer()
    atom.workspaceView.command "atomic-emacs:back-to-indentation", => @backToIndentation()
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
    atom.workspaceView.command "atomic-emacs:kill-region", => @killRegion()
    atom.workspaceView.command "atomic-emacs:forward-char", (event) => @forwardChar(event)
    atom.workspaceView.command "atomic-emacs:backward-char", (event) => @backwardChar(event)
    atom.workspaceView.command "atomic-emacs:next-line", (event) => @nextLine(event)
    atom.workspaceView.command "atomic-emacs:previous-line", (event) => @previousLine(event)
    atom.workspaceView.command "atomic-emacs:move-beginning-of-line", (event) => @moveBeginningOfLine(event)
    atom.workspaceView.command "atomic-emacs:move-end-of-line", (event) => @moveEndOfLine(event)

  getActiveEditor: ->
    atom.workspace.getActiveEditor()

  beginningOfBuffer: ->
    editor = @getActiveEditor()
    cursorMarker = editor.getMarkers()[0]

    if cursorMarker.retainSelection
      editor.selectToTop()
    else
      editor.moveCursorToTop()

  endOfBuffer: ->
    editor = @getActiveEditor()
    cursorMarker = editor.getMarkers()[0]

    if cursorMarker.retainSelection
      editor.selectToBottom()
    else
      editor.moveCursorToBottom()

  backToIndentation: ->
    editor = @getActiveEditor()
    cursorMarker = editor.getMarkers()[0]

    if cursorMarker.retainSelection
      editor.selectToFirstCharacterOfLine()
    else
      editor.moveCursorToFirstCharacterOfLine()

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
    cursorMarker = editor.getMarkers()[0]

    if cursorMarker.retainSelection
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

  killRegion: ->
    editor = @getActiveEditor()

    editor.cutSelectedText()
    @removeMark()

  forwardChar: (event) ->
    editor = @getActiveEditor()
    cursorMarker = editor.getMarkers()[0]

    if cursorMarker.retainSelection
      editor.selectRight()
    else
      event.abortKeyBinding()

  backwardChar: (event) ->
    editor = @getActiveEditor()
    cursorMarker = editor.getMarkers()[0]

    if cursorMarker.retainSelection
      editor.selectLeft()
    else
      event.abortKeyBinding()

  nextLine: (event) ->
    editor = @getActiveEditor()
    cursorMarker = editor.getMarkers()[0]

    if cursorMarker.retainSelection
      editor.selectDown()
    else
      event.abortKeyBinding()

  previousLine: (event) ->
    editor = @getActiveEditor()
    cursorMarker = editor.getMarkers()[0]

    if cursorMarker.retainSelection
      editor.selectUp()
    else
      event.abortKeyBinding()

  moveBeginningOfLine: (event) ->
    editor = @getActiveEditor()
    cursorMarker = editor.getMarkers()[0]

    if cursorMarker.retainSelection
      editor.selectToBeginningOfLine()
    else
      event.abortKeyBinding()

  moveEndOfLine: (event) ->
    editor = @getActiveEditor()
    cursorMarker = editor.getMarkers()[0]

    if cursorMarker.retainSelection
      editor.selectToEndOfLine()
    else
      event.abortKeyBinding()
