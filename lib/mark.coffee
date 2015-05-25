{Point, CompositeDisposable} = require('atom')

# Represents an Emacs-style mark.
#
# Get the mark for a cursor with Mark.for(cursor). If the cursor has no mark
# yet, one will be created, and set to the cursor's position.
#
# The can then be set() at any time, which will move to where the cursor is.
#
# It can also be activate()d and deactivate()d. While active, the region between
# the mark and the cursor is selected, and this selection is updated as the
# cursor is moved. If the buffer is edited, the mark is automatically
# deactivated.
class Mark
  MARK_MODE_CLASS = 'atomic-emacs-mark-mode'

  _marks = new WeakMap

  @for: (cursor) ->
    mark = _marks.get(cursor)
    unless mark
      mark = new Mark(cursor)
      _marks.set(cursor, mark)
    mark

  constructor: (@cursor) ->
    @editor = cursor.editor
    @marker = @editor.markBufferPosition(cursor.getBufferPosition())
    @active = false
    @updating = false
    @subscriptions = new CompositeDisposable()
    @subscriptions.add(@cursor.onDidDestroy(@_destroy))

  set: ()->
    @deactivate()
    @marker.setHeadBufferPosition(@cursor.getBufferPosition())
    @

  setBufferRange: (range) ->
    @deactivate()
    @activate()
    @marker.setHeadBufferPosition(range.start)
    @_updateSelection(newBufferPosition: range.end)

  getBufferPosition: ->
    @marker.getHeadBufferPosition()

  activate: ->
    return if @active
    @markerSubscriptions = new CompositeDisposable()
    @markerSubscriptions.add(@cursor.onDidChangePosition(@_updateSelection))
    @markerSubscriptions.add(@editor.getBuffer().onDidChange(@_onModified))
    atom.views.getView(@editor).classList.add(MARK_MODE_CLASS)
    @active = true

  deactivate: ->
    if @active
      @markerSubscriptions?.dispose()
      @markerSubscriptions = null
      atom.views.getView(@editor).classList.remove(MARK_MODE_CLASS)
      @active = false
    @cursor.clearSelection()

  isActive: ->
    @active

  exchange: ->
    position = @marker.getHeadBufferPosition()
    @set().activate()
    @cursor.setBufferPosition(position)

  _destroy: =>
    @deactivate() if @active
    @marker.destroy()
    @subscriptions?.dispose()
    @subscriptions = null

  _updateSelection: ({newBufferPosition}) =>
    # Updating the selection updates the cursor marker, so guard against the
    # nested invocation.
    return if @updating
    @updating = true
    try
      if @cursor.selection.isEmpty()
        a = @marker.getHeadBufferPosition()
      else
        a = @cursor.selection.getTailBufferPosition()

      b = newBufferPosition
      @cursor.selection.setBufferRange([a, b], reversed: Point.min(a, b) is b)
    finally
      @updating = false

  _onModified: (event) =>
    return if @_isIndent(event) or @_isOutdent(event)
    @deactivate()

  _isIndent: (event)->
    @_isIndentOutdent(event.newRange, event.newText)

  _isOutdent: (event)->
    @_isIndentOutdent(event.oldRange, event.oldText)

  _isIndentOutdent: (range, text)->
    tabLength = @editor.getTabLength()
    diff = range.end.column - range.start.column
    true if diff == @editor.getTabLength() and range.start.row == range.end.row and @_checkTextForSpaces(text, tabLength)

  _checkTextForSpaces: (text, tabSize)->
    return false unless text and text.length is tabSize

    for ch in text
      return false unless ch is " "
    true

module.exports = Mark
