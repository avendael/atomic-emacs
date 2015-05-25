_ = require 'underscore-plus'
{CompositeDisposable} = require 'atom'
Mark = require './mark'

module.exports =
class EmacsState
  destroyed: false

  constructor: (@editor) ->
    @subscriptions = new CompositeDisposable
    @subscriptions.add(@editor.onDidDestroy(@destroy))

    @subscriptions.add(@editor.onDidChangeSelectionRange(_.debounce((event) =>
      @selectionRangeChanged(event)
    , 100)))

  destroy: =>
    return if @destroyed
    @destroyed = true
    @subscriptions.dispose()
    @editor = null

  selectionRangeChanged: ({selection, newBufferRange} = {}) ->
    return unless selection?
    return if selection.isEmpty()
    return if @destroyed
    return if selection.cursor.destroyed?

    mark = Mark.for(selection.cursor)
    mark.setBufferRange(newBufferRange) unless mark.isActive()
