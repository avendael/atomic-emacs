{CompositeDisposable} = require 'atom'
EmacsCursor = require './emacs-cursor'
KillRing = require './kill-ring'
Mark = require './mark'
State = require './state'

module.exports =
class EmacsEditor
  @for: (editor) ->
    editor._atomicEmacs ?= new EmacsEditor(editor)

  constructor: (@editor) ->
    @disposable = new CompositeDisposable
    @disposable.add @editor.onDidRemoveCursor =>
      cursors = @editor.getCursors()
      if cursors.length == 1
        EmacsCursor.for(cursors[0]).clearLocalKillRing()
    @disposable.add @editor.onDidDestroy =>
      @destroy()

  destroy: ->
    # Neither cursor.did-destroy nor TextEditor.did-remove-cursor seems to fire
    # when the editor is destroyed. (Atom bug?) So we destroy EmacsCursors here.
    for cursor in @getEmacsCursors()
      cursor.destroy()
    @disposable.dispose()

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

  backwardList: ->
    @moveEmacsCursors (emacsCursor) ->
      emacsCursor.skipListBackward()

  forwardList: ->
    @moveEmacsCursors (emacsCursor) ->
      emacsCursor.skipListForward()

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
    @_pullFromClipboard()
    method = if State.killing then 'prepend' else 'push'
    @editor.transact =>
      @moveEmacsCursors (emacsCursor, cursor) =>
        emacsCursor.backwardKillWord(method)
    @_updateGlobalKillRing(method)
    State.killed()

  killWord: ->
    @_pullFromClipboard()
    method = if State.killing then 'append' else 'push'
    @editor.transact =>
      @moveEmacsCursors (emacsCursor) =>
        emacsCursor.killWord(method)
    @_updateGlobalKillRing(method)
    State.killed()

  killLine: ->
    @_pullFromClipboard()
    method = if State.killing then 'append' else 'push'
    @editor.transact =>
      @moveEmacsCursors (emacsCursor) =>
        emacsCursor.killLine(method)
    @_updateGlobalKillRing(method)
    State.killed()

  killRegion: ->
    @_pullFromClipboard()
    method = if State.killing then 'append' else 'push'
    @editor.transact =>
      @moveEmacsCursors (emacsCursor) =>
        emacsCursor.killRegion(method)
    @_updateGlobalKillRing(method)
    State.killed()

  copyRegionAsKill: ->
    @_pullFromClipboard()
    method = if State.killing then 'append' else 'push'
    @editor.transact =>
      for selection in @editor.getSelections()
        emacsCursor = EmacsCursor.for(selection.cursor)
        emacsCursor.killRing()[method](selection.getText())
        emacsCursor.killRing().getCurrentEntry()
        emacsCursor.mark().deactivate()
    @_updateGlobalKillRing(method)

  yank: ->
    @_pullFromClipboard()
    @editor.transact =>
      for emacsCursor in @getEmacsCursors()
        emacsCursor.yank()
    State.yanked()

  yankPop: ->
    return if not State.yanking
    @_pullFromClipboard()
    @editor.transact =>
      for emacsCursor in @getEmacsCursors()
        emacsCursor.rotateYank(-1)
    State.yanked()

  yankShift: ->
    return if not State.yanking
    @_pullFromClipboard()
    @editor.transact =>
      for emacsCursor in @getEmacsCursors()
        emacsCursor.rotateYank(1)
    State.yanked()

  _pushToClipboard: ->
    if atom.config.get("atomic-emacs.killToClipboard")
      KillRing.pushToClipboard()

  _pullFromClipboard: ->
    if atom.config.get("atomic-emacs.yankFromClipboard")
      killRings = (c.killRing() for c in @getEmacsCursors())
      KillRing.pullFromClipboard(killRings)

  _updateGlobalKillRing: (method) ->
    if @editor.hasMultipleCursors()
      kills = (c.killRing().getCurrentEntry() for c in @getEmacsCursors())
      method = 'replace' if method != 'push'
      KillRing.global[method](kills.join('\n') + '\n')
    @_pushToClipboard()

  ###
  Section: Editing
  ###

  deleteHorizontalSpace: ->
    @editor.transact =>
      @moveEmacsCursors (emacsCursor) =>
        range = emacsCursor.horizontalSpaceRange()
        @editor.setTextInBufferRange(range, '')

  deleteIndentation: ->
    return unless @editor
    @editor.transact =>
      @editor.moveUp()
      @editor.joinLines()

  openLine: ->
    @editor.transact =>
      for emacsCursor in @getEmacsCursors()
        emacsCursor.insertAfter("\n")

  justOneSpace: ->
    @editor.transact =>
      for emacsCursor in @getEmacsCursors()
        range = emacsCursor.horizontalSpaceRange()
        @editor.setTextInBufferRange(range, ' ')

  deleteBlankLines: ->
    @editor.transact =>
      for emacsCursor in @getEmacsCursors()
        emacsCursor.deleteBlankLines()

  transposeChars: ->
    @editor.transact =>
      @moveEmacsCursors (emacsCursor) =>
        emacsCursor.transposeChars()

  transposeWords: ->
    @editor.transact =>
      @moveEmacsCursors (emacsCursor) =>
        emacsCursor.transposeWords()

  transposeLines: ->
    @editor.transact =>
      @moveEmacsCursors (emacsCursor) =>
        emacsCursor.transposeLines()

  transposeSexps: ->
    @editor.transact =>
      @moveEmacsCursors (emacsCursor) =>
        emacsCursor.transposeSexps()

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
    @editor.transact =>
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
    [first, rest...] = @editor.getCursors()
    c.destroy() for c in rest
    emacsCursor = EmacsCursor.for(first)
    first.moveToBottom()
    emacsCursor.mark().set().activate()
    first.moveToTop()

  exchangePointAndMark: ->
    @moveEmacsCursors (emacsCursor) ->
      emacsCursor.mark().exchange()

  ###
  Section: UI
  ###

  recenterTopBottom: ->
    return unless @editor
    view = atom.views.getView(@editor)
    minRow = Math.min((c.getBufferRow() for c in @editor.getCursors())...)
    maxRow = Math.max((c.getBufferRow() for c in @editor.getCursors())...)
    minOffset = view.pixelPositionForBufferPosition([minRow, 0])
    maxOffset = view.pixelPositionForBufferPosition([maxRow, 0])

    switch State.recenters
      when 0
        view.setScrollTop((minOffset.top + maxOffset.top - view.getHeight())/2)
      when 1
        # Atom applies a (hardcoded) 2-line buffer while scrolling -- do that here.
        view.setScrollTop(minOffset.top - 2*@editor.getLineHeightInPixels())
      when 2
        view.setScrollTop(maxOffset.top + 3*@editor.getLineHeightInPixels() - view.getHeight())

    State.recentered()

  scrollUp: ->
    if (visibleRowRange = @editor.getVisibleRowRange())
      [firstRow,lastRow] = visibleRowRange
      currentRow = @editor.cursors[0].getBufferRow()
      rowCount = (lastRow - firstRow) - 2
      @editor.moveDown(rowCount)

  scrollDown: ->
    if (visibleRowRange = @editor.getVisibleRowRange())
      [firstRow,lastRow] = visibleRowRange
      currentRow = @editor.cursors[0].getBufferRow()
      rowCount = (lastRow - firstRow) - 2
      @editor.moveUp(rowCount)

  ###
  Section: Other
  ###

  keyboardQuit: ->
    for emacsCursor in @getEmacsCursors()
      emacsCursor.mark().deactivate()
