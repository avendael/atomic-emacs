{Point} = require 'atom'
Search = require './search'
SearchResults = require './search-results'
SearchView = require './search-view'

escapeForRegExp = (string) -> string.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')

module.exports =
class SearchManager
  constructor: ->
    @panel = null
    @searchEditor = null
    @emacsEditor = null

    @searchView = null
    @startCursors = null

    @search = null
    @results = null

  start: (@emacsEditor, @direction) ->
    @searchView ?= new SearchView(this)
    @searchView.start()
    @startCursors = @emacsEditor.saveCursors()

  exit: ->
    @searchView.exit()
    @emacsEditor.editor.element.focus()

  cancel: ->
    @searchView.cancel()
    @emacsEditor.editor.element.focus()

  repeatFoward: ->
    if @searchView.isEmpty()
      @searchView.repeatLastQuery()
      return

    if @results?
      @_advanceCursors()
    else
      # TODO: repeat last query

  changed: (text, {caseSensitive, isRegExp}) ->
    @results?.clear()
    @search?.stop()

    @results = SearchResults.for(@emacsEditor.editor)
    @results.clear()
    @searchView.resetProgress()

    return if text == ''

    caseSensitive = caseSensitive or (not isRegExp and /[A-Z]/.test(text))

    wrapped = false
    moved = false
    lastCursorPosition = @startCursors[@startCursors.length - 1].head

    # If the query used to match, but no longer does, we need to go back to the
    # original positions.
    @emacsEditor.restoreCursors(@startCursors)

    @search = new Search
      editor: @emacsEditor.editor
      startPosition: @startCursors[0].head
      regex: new RegExp(
        if isRegExp then text else escapeForRegExp(text)
        if caseSensitive then '' else 'i'
      )
      onMatch: (range) =>
        return if not @results?
        @results.add(range, wrapped)
        @searchView.setTotal(@results.numMatches())
        if not moved and (@results.findResultAfter(lastCursorPosition) or wrapped)
          @_advanceCursors()
          moved = true
      onWrapped: ->
        wrapped = true
      onFinished: =>
        return if not @results?
        if @results.numMatches() == 0
          @emacsEditor.restoreCursors(@startCursors)
        else if not moved
          @_advanceCursors()
        @searchView.scanningDone()

    @search?.start()

  _advanceCursors: ->
    # TODO: Store request and fire it when we can.
    return if not @results?

    markers = []
    @emacsEditor.moveEmacsCursors (emacsCursor) =>
      marker = @results.findResultAfter(emacsCursor.cursor.getBufferPosition()) or
        @results.findResultAfter(new Point(0, 0))
      emacsCursor.cursor.setBufferPosition(marker.getEndBufferPosition())
      markers.push(marker)

    @results.setCurrent(markers)

    point = @emacsEditor.editor.getCursors()[0].getBufferPosition()
    @searchView.setIndex(@results.numMatchesBefore(point))

  exited: ->
    @_deactivate()

  canceled: ->
    @emacsEditor.restoreCursors(@startCursors)
    @_deactivate()

  _deactivate: ->
    @search?.stop()
    @search = null
    @results?.clear()
    @results = null
    @startCursors = null
