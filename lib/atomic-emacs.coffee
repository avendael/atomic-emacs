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

transformNextWord = (editor, transformation) ->
  editor.moveCursors (cursor) ->
    tools = new CursorTools(cursor)
    tools.skipNonWordCharactersForward()
    start = cursor.getBufferPosition()
    tools.skipWordCharactersForward()
    end = cursor.getBufferPosition()
    range = [start, end]
    text = editor.getTextInBufferRange(range)
    editor.setTextInBufferRange(range, transformation(text))

capitalize = (string) ->
  string.slice(0, 1).toUpperCase() + string.slice(1).toLowerCase()

class AtomicEmacs
  constructor: ->
    @previousCommand = null
    @recenters = 0

  commandDispatched: (event) ->
    @previousCommand = event.type

  editor: (event) ->
    # Get editor from the event if possible so we can target mini-editors.
    if event.target?.getModel
      event.target.getModel()
    else
      atom.workspace.getActiveTextEditor()

  upcaseWordOrRegion: (event) ->
    editor = @editor(event)
    if editor.getSelections().filter((s) -> not s.isEmpty()).length > 0
      # Atom bug: editor.upperCase() flips reversed ranges.
      editor.mutateSelectedText (selection) ->
        range = selection.getBufferRange()
        editor.setTextInBufferRange(range, selection.getText().toUpperCase())
    else
      transformNextWord editor, (word) -> word.toUpperCase()

  downcaseWordOrRegion: (event) ->
    editor = @editor(event)
    if editor.getSelections().filter((s) -> not s.isEmpty()).length > 0
      # Atom bug: editor.lowerCase() flips reversed ranges.
      editor.mutateSelectedText (selection) ->
        range = selection.getBufferRange()
        editor.setTextInBufferRange(range, selection.getText().toLowerCase())
    else
      transformNextWord editor, (word) -> word.toLowerCase()

  capitalizeWordOrRegion: (event) ->
    editor = @editor(event)
    if editor.getSelections().filter((selection) -> not selection.isEmpty()).length > 0
      editor.mutateSelectedText (selection) ->
        if not selection.isEmpty()
          selectionRange = selection.getBufferRange()
          editor.scanInBufferRange /\w+/g, selectionRange, (hit) ->
            hit.replace(capitalize(hit.matchText))
    else
      transformNextWord editor, capitalize

  openLine: (event) ->
    editor = @editor(event)
    editor.insertNewline()
    editor.moveUp()

  transposeChars: (event) ->
    editor = @editor(event)
    bob_cursor_ids = {}

    editor.moveCursors (cursor) ->
      {row, column} = cursor.getBufferPosition()
      if row == 0 and column == 0
        bob_cursor_ids[cursor.id] = 1
      line = editor.lineTextForBufferRow(row)
      cursor.moveLeft() if column == line.length

    editor.transpose()

    editor.moveCursors (cursor) ->
      if bob_cursor_ids.hasOwnProperty(cursor.id)
        cursor.moveLeft()
      else if cursor.getBufferColumn() > 0
        cursor.moveRight()

  transposeWords: (event) ->
    editor = @editor(event)
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
    editor = @editor(event)
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

  markWholeBuffer: (event) ->
    @editor(event).selectAll()

  setMark: (event) ->
    for cursor in @editor(event).getCursors()
      Mark.for(cursor).set().activate()

  keyboardQuit: (event) ->
    deactivateCursors(@editor(event))

  exchangePointAndMark: (event) ->
    @editor(event).moveCursors (cursor) ->
      Mark.for(cursor).exchange()

  copy: (event) ->
    editor = @editor(event)
    editor.copySelectedText()
    deactivateCursors(editor)

  closeOtherPanes: (event) ->
    activePane = atom.workspace.getActivePane()
    return if not activePane
    for pane in atom.workspace.getPanes()
      unless pane is activePane
        pane.close()

  forwardChar: (event) ->
    if atom.config.get('atomic-emacs.useNativeNavigationKeys')
      event.abortKeyBinding()
      return
    @editor(event).moveCursors (cursor) ->
      cursor.moveRight()

  backwardChar: (event) ->
    @editor(event).moveCursors (cursor) ->
      mark = Mark.for(cursor)
      if mark?.isActive()
        cursor.selection.selectLeft()
        return
      if atom.config.get('atomic-emacs.useNativeNavigationKeys')
        event.abortKeyBinding()
      else
        cursor.moveLeft()

  forwardWord: (event) ->
    @editor(event).moveCursors (cursor) ->
      tools = new CursorTools(cursor)
      tools.skipNonWordCharactersForward()
      tools.skipWordCharactersForward()

  backwardWord: (event) ->
    @editor(event).moveCursors (cursor) ->
      tools = new CursorTools(cursor)
      tools.skipNonWordCharactersBackward()
      tools.skipWordCharactersBackward()

  forwardSexp: (event) ->
    @editor(event).moveCursors (cursor) ->
      new CursorTools(cursor).skipSexpForward()

  backwardSexp: (event) ->
    @editor(event).moveCursors (cursor) ->
      new CursorTools(cursor).skipSexpBackward()

  markSexp: (event) ->
    @editor(event).moveCursors (cursor) ->
      new CursorTools(cursor).markSexp()

  backToIndentation: (event) ->
    editor = @editor(event)
    editor.moveCursors (cursor) ->
      position = cursor.getBufferPosition()
      line = editor.lineTextForBufferRow(position.row)
      targetColumn = line.search(/\S/)
      targetColumn = line.length if targetColumn == -1

      if position.column != targetColumn
        cursor.setBufferPosition([position.row, targetColumn])

  nextLine: (event) ->
    if atom.config.get('atomic-emacs.useNativeNavigationKeys')
      event.abortKeyBinding()
      return
    @editor(event).moveCursors (cursor) ->
      cursor.moveDown()

  previousLine: (event) ->
    if atom.config.get('atomic-emacs.useNativeNavigationKeys')
      event.abortKeyBinding()
      return
    @editor(event).moveCursors (cursor) ->
      cursor.moveUp()

  scrollUp: (event) ->
    editor = @editor(event)
    [firstRow,lastRow] = editor.getVisibleRowRange()
    currentRow = editor.cursors[0].getBufferRow()
    rowCount = (lastRow - firstRow) - 2
    editor.moveDown(rowCount)

  scrollDown: (event) ->
    editor = @editor(event)
    [firstRow,lastRow] = editor.getVisibleRowRange()
    currentRow = editor.cursors[0].getBufferRow()
    rowCount = (lastRow - firstRow) - 2
    editor.moveUp(rowCount)

  backwardParagraph: (event) ->
    @editor(event).moveCursors (cursor) ->
      position = cursor.getBufferPosition()
      unless position.row == 0
        cursor.setBufferPosition([position.row - 1, 0])

      cursorTools = new CursorTools(cursor)
      cursorTools.goToMatchStartBackward(/^\s*$/) or
        cursor.moveToTop()

  forwardParagraph: (event) ->
    editor = @editor(event)
    lastRow = editor.getLastBufferRow()
    editor.moveCursors (cursor) ->
      position = cursor.getBufferPosition()
      unless position.row == lastRow
        cursor.setBufferPosition([position.row + 1, 0])

      cursorTools = new CursorTools(cursor)
      cursorTools.goToMatchStartForward(/^\s*$/) or
        cursor.moveToBottom()

  backwardKillWord: (event) ->
    editor = @editor(event)
    editor.transact =>
      for selection in editor.getSelections()
        selection.modifySelection ->
          if selection.isEmpty()
            cursorTools = new CursorTools(selection.cursor)
            cursorTools.skipNonWordCharactersBackward()
            cursorTools.skipWordCharactersBackward()
          selection.deleteSelectedText()

  killWord: (event) ->
    editor = @editor(event)
    editor.transact =>
      for selection in editor.getSelections()
        selection.modifySelection ->
          if selection.isEmpty()
            cursorTools = new CursorTools(selection.cursor)
            cursorTools.skipNonWordCharactersForward()
            cursorTools.skipWordCharactersForward()
          selection.deleteSelectedText()

  justOneSpace: (event) ->
    editor = @editor(event)
    for cursor in editor.cursors
      range = horizontalSpaceRange(cursor)
      editor.setTextInBufferRange(range, ' ')

  deleteHorizontalSpace: (event) ->
    editor = @editor(event)
    for cursor in editor.cursors
      range = horizontalSpaceRange(cursor)
      editor.setTextInBufferRange(range, '')

  recenterTopBottom: (event) ->
    if @previousCommand == 'atomic-emacs:recenter-top-bottom'
      @recenters = (@recenters + 1) % 3
    else
      @recenters = 0

    editor = @editor(event)
    return unless editor
    editorElement = atom.views.getView(editor)
    minRow = Math.min((c.getBufferRow() for c in editor.getCursors())...)
    maxRow = Math.max((c.getBufferRow() for c in editor.getCursors())...)
    minOffset = editorElement.pixelPositionForBufferPosition([minRow, 0])
    maxOffset = editorElement.pixelPositionForBufferPosition([maxRow, 0])

    switch @recenters
      when 0
        editor.setScrollTop((minOffset.top + maxOffset.top - editor.getHeight())/2)
      when 1
        # Atom applies a (hardcoded) 2-line buffer while scrolling -- do that here.
        editor.setScrollTop(minOffset.top - 2*editor.getLineHeightInPixels())
      when 2
        editor.setScrollTop(maxOffset.top + 3*editor.getLineHeightInPixels() - editor.getHeight())

  deleteIndentation: =>
    editor = @editor(event)
    return unless editor
    editor.transact ->
      editor.moveUp()
      editor.joinLines()

module.exports =
  AtomicEmacs: AtomicEmacs
  Mark: Mark

  activate: ->
    atomicEmacs = new AtomicEmacs()
    document.getElementsByTagName('atom-workspace')[0]?.classList?.add('atomic-emacs')
    @disposable = new CompositeDisposable
    @disposable.add atom.commands.onDidDispatch (event) -> atomicEmacs.commandDispatched(event)
    @disposable.add atom.commands.add 'atom-text-editor',
      "atomic-emacs:backward-char": (event) -> atomicEmacs.backwardChar(event)
      "atomic-emacs:backward-kill-word": (event) -> atomicEmacs.backwardKillWord(event)
      "atomic-emacs:backward-paragraph": (event) -> atomicEmacs.backwardParagraph(event)
      "atomic-emacs:backward-word": (event) -> atomicEmacs.backwardWord(event)
      "atomic-emacs:beginning-of-buffer": (event) -> atomicEmacs.beginningOfBuffer(event)
      "atomic-emacs:capitalize-word-or-region": (event) -> atomicEmacs.capitalizeWordOrRegion(event)
      "atomic-emacs:close-other-panes": (event) -> atomicEmacs.closeOtherPanes(event)
      "atomic-emacs:copy": (event) -> atomicEmacs.copy(event)
      "atomic-emacs:delete-horizontal-space": (event) -> atomicEmacs.deleteHorizontalSpace(event)
      "atomic-emacs:delete-indentation": atomicEmacs.deleteIndentation
      "atomic-emacs:downcase-word-or-region": (event) -> atomicEmacs.downcaseWordOrRegion(event)
      "atomic-emacs:end-of-buffer": (event) -> atomicEmacs.endOfBuffer(event)
      "atomic-emacs:exchange-point-and-mark": (event) -> atomicEmacs.exchangePointAndMark(event)
      "atomic-emacs:forward-char": (event) -> atomicEmacs.forwardChar(event)
      "atomic-emacs:forward-paragraph": (event) -> atomicEmacs.forwardParagraph(event)
      "atomic-emacs:forward-word": (event) -> atomicEmacs.forwardWord(event)
      "atomic-emacs:forward-sexp": (event) -> atomicEmacs.forwardSexp(event)
      "atomic-emacs:backward-sexp": (event) -> atomicEmacs.backwardSexp(event)
      "atomic-emacs:mark-sexp": (event) -> atomicEmacs.markSexp(event)
      "atomic-emacs:just-one-space": (event) -> atomicEmacs.justOneSpace(event)
      "atomic-emacs:kill-word": (event) -> atomicEmacs.killWord(event)
      "atomic-emacs:mark-whole-buffer": (event) -> atomicEmacs.markWholeBuffer(event)
      "atomic-emacs:back-to-indentation": (event) -> atomicEmacs.backToIndentation(event)
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
      "atomic-emacs:upcase-word-or-region": (event) -> atomicEmacs.upcaseWordOrRegion(event)
      "core:cancel": (event) -> atomicEmacs.keyboardQuit(event)

  deactivate: ->
    document.getElementsByTagName('atom-workspace')[0]?.classList?.remove('atomic-emacs')
    @disposable?.dispose()
    @disposable = null
