{Point} = require('atom')

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
  constructor: (cursor) ->
    @cursor = cursor
    @editor = cursor.editor
    @marker = @editor.markBufferPosition(cursor.getBufferPosition())
    @active = false
    @updating = false

    @cursorDestroyedCallback = (event) => @_destroy()
    @cursor.on 'destroyed', @cursorDestroyedCallback

  set: ->
    @deactivate()
    @marker.setHeadBufferPosition(@cursor.getBufferPosition())
    @

  getBufferPosition: ->
    @marker.getHeadBufferPosition()

  activate: ->
    if not @active
      @movedCallback ?= (event) => @_updateSelection(event)
      @modifiedCallback ?= (event) =>
        return if @_isIndent(event) or @_isOutdent(event)
        @deactivate()
      @cursor.on 'moved', @movedCallback
      @editor.getBuffer().on 'changed', @modifiedCallback
      @active = true

  deactivate: ->
    if @active
      @cursor.off 'moved', @movedCallback
      @editor.getBuffer().on 'changed', @modifiedCallback
      @active = false
    @cursor.clearSelection()
    @cursor.selection.screenRangeChanged(@marker)  # force redraw of selection

  isActive: ->
    @active

  exchange: ->
    position = @marker.getHeadBufferPosition()
    @set().activate()
    @cursor.setBufferPosition(position)

  _destroy: ->
    @deactivate() if @active
    @marker.destroy()
    @cursor.off 'destroyed', @cursorDestroyedCallback
    delete @cursor._atomicEmacsMark

  _updateSelection: (event) ->
    # Updating the selection updates the cursor marker, so guard against the
    # nested invocation.
    if !@updating
      @updating = true
      try
        a = @marker.getHeadBufferPosition()
        b = @cursor.getBufferPosition()
        @cursor.selection.setBufferRange([a, b], isReversed: Point.min(a, b) is b)
      finally
        @updating = false

  Mark.for = (cursor) ->
   cursor._atomicEmacsMark ?= new Mark(cursor)

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
