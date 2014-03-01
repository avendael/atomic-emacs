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
    atom.workspaceView.command "atomic-emacs:remove-mark", => @removeMark()
    atom.workspaceView.command "atomic-emacs:exchange-point-and-mark", => @exchangePointAndMark()
    atom.workspaceView.command "atomic-emacs:copy", => @copy()

  getActiveEditor: ->
    atom.workspace.getActiveEditor()

  beginningOfBuffer: ->
    @getActiveEditor().moveCursorToTop()

  endOfBuffer: ->
    @getActiveEditor().moveCursorToBottom()

  backToIndentation: ->
    @getActiveEditor().moveCursorToFirstCharacterOfLine()

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
    lastSelection = editor.getLastSelectionInBuffer()

    if lastSelection.retainSelection
      lastSelection.retainSelection = false

      editor.clearSelections()
    else
      displayMarker = editor.getMarkers()[0]
      selection = editor.addSelectionForBufferRange(displayMarker.bufferMarker.range)
      selection.retainSelection = true

  removeMark: ->
    editor = @getActiveEditor()

    editor.getLastSelectionInBuffer().retainSelection = false
    editor.clearSelections()

  exchangePointAndMark: ->
    marker = @getActiveEditor().getLastSelectionInBuffer().marker.bufferMarker
    headPosition = marker.getHeadPosition()
    tailPosition = marker.getTailPosition()

    marker.setHeadPosition(tailPosition)
    marker.setTailPosition(headPosition)

  copy: ->
    editor = @getActiveEditor()

    editor.copySelectedText()
    editor.getLastSelectionInBuffer().retainSelection = false
    editor.clearSelections()
