EmacsCursor = require './emacs-cursor'
KillRing = require './kill-ring'
Mark = require './mark'
State = require './state'

horizontalSpaceRange = (cursor) ->
  emacsCursor = EmacsCursor.for(cursor)
  emacsCursor.skipCharactersBackward(' \t')
  start = cursor.getBufferPosition()
  emacsCursor.skipCharactersForward(' \t')
  end = cursor.getBufferPosition()
  [start, end]

endLineIfNecessary = (cursor) ->
  row = cursor.getBufferPosition().row
  editor = cursor.editor
  if row == editor.getLineCount() - 1
    length = cursor.getCurrentBufferLine().length
    editor.setTextInBufferRange([[row, length], [row, length]], "\n")

module.exports =
class EmacsEditor
  @for: (editor, state) ->
    editor._atomicEmacs ?= new EmacsEditor(editor, state)

  constructor: (@editor, @state) ->

  getEmacsCursors: () ->
    EmacsCursor.for(c) for c in @editor.getCursors()

  moveEmacsCursors: (callback) ->
    @editor.moveCursors (cursor) ->
      # Atom bug: if moving one cursor destroys another, the destroyed one's
      # emitter is disposed, but cursor.isDestroyed() is still false. However
      # cursor.destroyed == true. TextEditor.moveCursors probably shouldn't even
      # yield it in this case.
      return if cursor.destroyed == true
      callback(EmacsCursor.for(cursor), cursor)

  ###
  Section: Navigation
  ###

  backwardChar: ->
    @editor.moveCursors (cursor) ->
      cursor.moveLeft()

  forwardChar: ->
    @editor.moveCursors (cursor) ->
      cursor.moveRight()

  backwardWord: ->
    @moveEmacsCursors (emacsCursor) ->
      emacsCursor.skipNonWordCharactersBackward()
      emacsCursor.skipWordCharactersBackward()

  forwardWord: ->
    @moveEmacsCursors (emacsCursor) ->
      emacsCursor.skipNonWordCharactersForward()
      emacsCursor.skipWordCharactersForward()

  backwardSexp: ->
    @moveEmacsCursors (emacsCursor) ->
      emacsCursor.skipSexpBackward()

  forwardSexp: ->
    @moveEmacsCursors (emacsCursor) ->
      emacsCursor.skipSexpForward()

  previousLine: ->
    @editor.moveCursors (cursor) ->
      cursor.moveUp()

  nextLine: ->
    @editor.moveCursors (cursor) ->
      cursor.moveDown()

  backwardParagraph: ->
    @moveEmacsCursors (emacsCursor, cursor) ->
      position = cursor.getBufferPosition()
      unless position.row == 0
        cursor.setBufferPosition([position.row - 1, 0])

      emacsCursor.goToMatchStartBackward(/^\s*$/) or
        cursor.moveToTop()

  forwardParagraph: ->
    lastRow = @editor.getLastBufferRow()
    @moveEmacsCursors (emacsCursor, cursor) ->
      position = cursor.getBufferPosition()
      unless position.row == lastRow
        cursor.setBufferPosition([position.row + 1, 0])

      emacsCursor.goToMatchStartForward(/^\s*$/) or
        cursor.moveToBottom()

  backToIndentation: ->
    @editor.moveCursors (cursor) =>
      position = cursor.getBufferPosition()
      line = @editor.lineTextForBufferRow(position.row)
      targetColumn = line.search(/\S/)
      targetColumn = line.length if targetColumn == -1

      if position.column != targetColumn
        cursor.setBufferPosition([position.row, targetColumn])

  ###
  Section: Killing & Yanking
  ###

  backwardKillWord: ->
    @editor.transact =>
      for selection in @editor.getSelections()
        # Atom bug: if moving one cursor destroys another, the destroyed one's
        # emitter is disposed, but cursor.isDestroyed() is still false. However
        # cursor.destroyed == true. TextEditor.moveCursors probably shouldn't even
        # yield it in this case.
        continue if selection.cursor.destroyed == true

        selection.modifySelection =>
          emacsCursor = EmacsCursor.for(selection.cursor)
          if selection.isEmpty()
            emacsCursor.skipNonWordCharactersBackward()
            emacsCursor.skipWordCharactersBackward()
          method = if @state.killing then 'prepend' else 'push'
          emacsCursor.killRing()[method](selection.getText())
          selection.deleteSelectedText()
        selection.clear()
    @state.killed = true

  killWord: ->
    @editor.transact =>
      for selection in @editor.getSelections()
        # Atom bug: if moving one cursor destroys another, the destroyed one's
        # emitter is disposed, but cursor.isDestroyed() is still false. However
        # cursor.destroyed == true. TextEditor.moveCursors probably shouldn't even
        # yield it in this case.
        continue if selection.cursor.destroyed == true

        selection.modifySelection =>
          emacsCursor = EmacsCursor.for(selection.cursor)
          if selection.isEmpty()
            emacsCursor.skipNonWordCharactersForward()
            emacsCursor.skipWordCharactersForward()
          method = if @state.killing then 'append' else 'push'
          emacsCursor.killRing()[method](selection.getText())
          selection.deleteSelectedText()
        selection.clear()
    @state.killed = true

  killLine: ->
    @editor.transact =>
      for selection in @editor.getSelections()
        # Atom bug: if moving one cursor destroys another, the destroyed one's
        # emitter is disposed, but cursor.isDestroyed() is still false. However
        # cursor.destroyed == true. TextEditor.moveCursors probably shouldn't even
        # yield it in this case.
        continue if selection.cursor.destroyed == true

        selection.modifySelection =>
          emacsCursor = EmacsCursor.for(selection.cursor)
          if selection.isEmpty()
            {row, column} = selection.cursor.getBufferPosition()
            line = @editor.lineTextForBufferRow(row)
            selection.cursor.moveToEndOfLine()
            if /^\s*$/.test(line.slice(column))
              selection.cursor.moveRight()
          killRing = emacsCursor.killRing()
          killRing[if @state.killing then 'append' else 'push'](selection.getText())
          selection.deleteSelectedText()
        selection.clear()
    @state.killed = true

  killRegion: ->
    @editor.transact =>
      for selection in @editor.getSelections()
        # Atom bug: if moving one cursor destroys another, the destroyed one's
        # emitter is disposed, but cursor.isDestroyed() is still false. However
        # cursor.destroyed == true. TextEditor.moveCursors probably shouldn't even
        # yield it in this case.
        continue if selection.cursor.destroyed == true

        selection.modifySelection =>
          emacsCursor = EmacsCursor.for(selection.cursor)
          emacsCursor.killRing().push(selection.getText())
          selection.deleteSelectedText()
          emacsCursor.mark().deactivate()
        selection.clear()
    @state.killed = true

  copyRegionAsKill: ->
    @editor.transact =>
      for selection in @editor.getSelections()
        emacsCursor = EmacsCursor.for(selection.cursor)
        emacsCursor.killRing().push(selection.getText())
        emacsCursor.mark().deactivate()

  yank: ->
    @editor.transact =>
      for emacsCursor in @getEmacsCursors()
        emacsCursor.yank()
    @state.yanked = true

  yankPop: ->
    return if not @state.yanking
    @editor.transact =>
      for emacsCursor in @getEmacsCursors()
        emacsCursor.rotateYank(-1)
    @state.yanked = true

  yankShift: ->
    return if not @state.yanking
    @editor.transact =>
      for emacsCursor in @getEmacsCursors()
        emacsCursor.rotateYank(1)
    @state.yanked = true

  ###
  Section: Editing
  ###

  deleteHorizontalSpace: ->
    for cursor in @editor.getCursors()
      range = horizontalSpaceRange(cursor)
      @editor.setTextInBufferRange(range, '')

  deleteIndentation: ->
    return unless @editor
    @editor.transact =>
      @editor.moveUp()
      @editor.joinLines()

  openLine: ->
    @editor.insertNewline()
    @editor.moveUp()

  justOneSpace: ->
    for cursor in @editor.getCursors()
      range = horizontalSpaceRange(cursor)
      @editor.setTextInBufferRange(range, ' ')

  transposeChars: ->
    bob_cursor_ids = {}

    @editor.moveCursors (cursor) =>
      {row, column} = cursor.getBufferPosition()
      if row == 0 and column == 0
        bob_cursor_ids[cursor.id] = 1
      line = @editor.lineTextForBufferRow(row)
      cursor.moveLeft() if column == line.length

    @editor.transpose()

    @editor.moveCursors (cursor) ->
      if bob_cursor_ids.hasOwnProperty(cursor.id)
        cursor.moveLeft()
      else if cursor.getBufferColumn() > 0
        cursor.moveRight()

  transposeWords: ->
    @editor.transact =>
      for emacsCursor in @getEmacsCursors()
        cursor = emacsCursor.cursor
        emacsCursor.skipNonWordCharactersBackward()

        word1 = emacsCursor.extractWord()
        word1Pos = cursor.getBufferPosition()
        emacsCursor.skipNonWordCharactersForward()
        if @editor.getEofBufferPosition().isEqual(cursor.getBufferPosition())
          # No second word - put the first word back.
          @editor.setTextInBufferRange([word1Pos, word1Pos], word1)
          emacsCursor.skipNonWordCharactersBackward()
        else
          word2 = emacsCursor.extractWord()
          word2Pos = cursor.getBufferPosition()
          @editor.setTextInBufferRange([word2Pos, word2Pos], word1)
          @editor.setTextInBufferRange([word1Pos, word1Pos], word2)
        cursor.setBufferPosition(cursor.getBufferPosition())

  transposeLines: ->
    cursor = @editor.getLastCursor()
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

  downcase = (s) -> s.toLowerCase()
  upcase = (s) -> s.toUpperCase()
  capitalize = (s) -> s.slice(0, 1).toUpperCase() + s.slice(1).toLowerCase()

  downcaseWordOrRegion: ->
    @_transformWordOrRegion(downcase)

  upcaseWordOrRegion: ->
    @_transformWordOrRegion(upcase)

  capitalizeWordOrRegion: ->
    @_transformWordOrRegion(capitalize, wordAtATime: true)

  _transformWordOrRegion: (transformWord, {wordAtATime}={}) ->
    if @editor.getSelections().filter((s) -> not s.isEmpty()).length > 0
      @editor.mutateSelectedText (selection) =>
        range = selection.getBufferRange()
        if wordAtATime
          @editor.scanInBufferRange /\w+/g, range, (hit) ->
            hit.replace(transformWord(hit.matchText))
        else
          @editor.setTextInBufferRange(range, transformWord(selection.getText()))
    else
      for cursor in @editor.getCursors()
        cursor.emitter.__track = true
      @moveEmacsCursors (emacsCursor) =>
        emacsCursor.transformWord(transformWord)

  ###
  Section: Marking & Selecting
  ###

  setMark: ->
    for emacsCursor in @getEmacsCursors()
      emacsCursor.mark().set().activate()

  markSexp: ->
    @moveEmacsCursors (emacsCursor) ->
      emacsCursor.markSexp()

  markWholeBuffer: ->
    @editor.selectAll()

  exchangePointAndMark: ->
    @moveEmacsCursors (emacsCursor) ->
      emacsCursor.mark().exchange()

  ###
  Section: UI
  ###

  recenterTopBottom: ->
    if @previousCommand == 'atomic-emacs:recenter-top-bottom'
      @recenters = (@recenters + 1) % 3
    else
      @recenters = 0

    return unless @editor
    editorElement = atom.views.getView(@editor)
    minRow = Math.min((c.getBufferRow() for c in @editor.getCursors())...)
    maxRow = Math.max((c.getBufferRow() for c in @editor.getCursors())...)
    minOffset = editorElement.pixelPositionForBufferPosition([minRow, 0])
    maxOffset = editorElement.pixelPositionForBufferPosition([maxRow, 0])

    switch @recenters
      when 0
        @editor.setScrollTop((minOffset.top + maxOffset.top - @editor.getHeight())/2)
      when 1
        # Atom applies a (hardcoded) 2-line buffer while scrolling -- do that here.
        @editor.setScrollTop(minOffset.top - 2*@editor.getLineHeightInPixels())
      when 2
        @editor.setScrollTop(maxOffset.top + 3*@editor.getLineHeightInPixels() - @editor.getHeight())

  scrollUp: ->
    [firstRow,lastRow] = @editor.getVisibleRowRange()
    currentRow = @editor.cursors[0].getBufferRow()
    rowCount = (lastRow - firstRow) - 2
    @editor.moveDown(rowCount)

  scrollDown: ->
    [firstRow,lastRow] = @editor.getVisibleRowRange()
    currentRow = @editor.cursors[0].getBufferRow()
    rowCount = (lastRow - firstRow) - 2
    @editor.moveUp(rowCount)

  ###
  Section: Other
  ###

  keyboardQuit: ->
    for emacsCursor in @getEmacsCursors()
      emacsCursor.mark().deactivate()
