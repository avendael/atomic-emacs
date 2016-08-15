{CompositeDisposable, Point} = require 'atom'
State = require './state'

# Represents an Emacs-style mark.
#
# Each cursor may have a Mark. On construction, the mark is at the cursor's
# position.
#
# The mark can then be set() at any time, which will move it to where the cursor
# is.
#
# It can also be activate()d and deactivate()d. While active, the region between
# the mark and the cursor is selected, and this selection is updated as the
# cursor is moved. If the buffer is edited, the mark is automatically
# deactivated.
class Mark
  @deactivatable = []

  @deactivatePending: ->
    for mark in @deactivatable
      mark.deactivate()
    @deactivatable.length = 0

  constructor: (cursor) ->
    @cursor = cursor
    @editor = cursor.editor
    @marker = @editor.markBufferPosition(cursor.getBufferPosition())
    @active = false
    @updating = false

  destroy: ->
    @deactivate() if @active
    @marker.destroy()

  set: (point=@cursor.getBufferPosition()) ->
    @deactivate()
    @marker.setHeadBufferPosition(point)
    @_updateSelection()
    @

  getBufferPosition: ->
    @marker.getHeadBufferPosition()

  activate: ->
    if not @active
      @activeSubscriptions = new CompositeDisposable
      @activeSubscriptions.add @cursor.onDidChangePosition (event) =>
        @_updateSelection(event)
      # Cursor movement commands like cursor.moveDown deactivate the selection
      # unconditionally, but don't trigger onDidChangePosition if the position
      # doesn't change (e.g. at EOF). So we also update the selection after any
      # command.
      @activeSubscriptions.add atom.commands.onDidDispatch (event) =>
        @_updateSelection(event)
      @activeSubscriptions.add @editor.getBuffer().onDidChange (event) =>
        unless @_isIndent(event) or @_isOutdent(event)
          # If we're in a command (as opposed to a simple character insert),
          # delay the deactivation until the end of the command. Otherwise
          # updating one selection may prematurely deactivate the mark and clear
          # a second selection before it has a chance to be updated.
          if State.isDuringCommand
            Mark.deactivatable.push(this)
          else
            @deactivate()
      @active = true

  deactivate: ->
    if @active
      @activeSubscriptions.dispose()
      @active = false
    unless @cursor.editor.isDestroyed()
      @cursor.clearSelection()

  isActive: ->
    @active

  exchange: ->
    position = @marker.getHeadBufferPosition()
    @set().activate()
    @cursor.setBufferPosition(position)

  _updateSelection: (event) ->
    # Updating the selection updates the cursor marker, so guard against the
    # nested invocation.
    if !@updating
      @updating = true
      try
        head = @cursor.getBufferPosition()
        tail = @marker.getHeadBufferPosition()
        @setSelectionRange(head, tail)
      finally
        @updating = false

  getSelectionRange: ->
    @cursor.selection.getBufferRange()

  setSelectionRange: (head, tail) ->
    reversed = Point.min(head, tail) is head
    @cursor.selection.setBufferRange([head, tail], reversed: reversed)

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
