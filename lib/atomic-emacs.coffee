module.exports =
  activate: ->
    atom.workspaceView.command "atomic-emacs:beginning-of-buffer", => @beginningOfBuffer()
    atom.workspaceView.command "atomic-emacs:end-of-buffer", => @endOfBuffer()
    atom.workspaceView.command "atomic-emacs:back-to-indentation", => @backToIndentation()
    atom.workspaceView.command "atomic-emacs:upcase-region", => @upcaseRegion()
    atom.workspaceView.command "atomic-emacs:downcase-region", => @downcaseRegion()
    atom.workspaceView.command "atomic-emacs:open-line", => @openLine()
    atom.workspaceView.command "atomic-emacs:transpose-lines", => @transposeLines()

  beginningOfBuffer: ->
    editor = atom.workspace.activePaneItem
    editor.moveCursorToTop()

  endOfBuffer: ->
    editor = atom.workspace.activePaneItem
    editor.moveCursorToBottom()

  backToIndentation: ->
    editor = atom.workspace.activePaneItem
    editor.moveCursorToFirstCharacterOfLine()

  upcaseRegion: ->
    editor = atom.workspace.activePaneItem
    editor.upperCase()

  downcaseRegion: ->
    editor = atom.workspace.activePaneItem
    editor.lowerCase()

  openLine: ->
    editor = atom.workspace.activePaneItem
    editor.insertNewline()
    editor.moveCursorUp()

  transposeLines: ->
    # This is probably wrong. Things get ugly on undo
    editor = atom.workspace.activePaneItem
    editor.moveCursorToBeginningOfLine()
    editor.cutToEndOfLine()
    editor.moveCursorUp()
    @openLine()
    editor.pasteText()
    editor.moveCursorToBeginningOfLine()
    editor.indent()
    editor.moveCursorDown()
    editor.moveCursorToBeginningOfLine()
    editor.indent()
    editor.moveCursorDown()
    editor.deleteLine()
