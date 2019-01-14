{Point, Range} = require 'atom'
SearchView = require './search-view'

# Handles the search through the buffer from a given starting point, in a given
# direction, wrapping back around to the starting point. Each call to proceed()
# advances up to a limited distance, calling the onMatch callback at most once,
# and return true until the starting point has been reached again. Once that
# happens, proceed() will return false, and will never call the onMatch callback
# anymore.
class Searcher
  constructor: ({@editor, @startPosition, @regex, @onMatch, @onWrapped, @onFinished}) ->
    @blockLines = 100
    @wrapped = false
    @finished = false

    # TODO: Don't assume regex can't span lines. need a configurable overlap?
    @_startBlock(@startPosition)
    @buffer = @editor.getBuffer()
    @eob = @buffer.getEndPosition()
    @_stopRequested = false

  start: ->
    task = =>
      if not @_stopRequested and @_proceed()
        setTimeout(task, 0)
    setTimeout(task, 0)

  stop: ->
    @_stopRequested = true

  # Proceed with the scan until either a match, or the end of the current range
  # is reached. Return true if the search isn't finished yet, false otherwise.
  _proceed: ->
    return false if @finished

    found = false

    @editor.scanInBufferRange @regex, new Range(@currentPosition, @currentEnd), ({range}) =>
      found = true
      @onMatch(range)
      # If range is empty, advance one char to ensure finite progress.
      if range.isEmpty()
        @currentPosition = @buffer.positionForCharacterIndex(@buffer.characterIndexForPosition(range.end) + 1)
      else
        @currentPosition = range.end
      stop()

    if not found
      if @wrapped and @currentEnd.isEqual(@startPosition)
        @finished = true
        @onFinished()
        return false
      else if not @wrapped and @currentEnd.isEqual(@eob)
        @wrapped = true
        @onWrapped()
        @_startBlock(new Point(0, 0))
      else
        @_startBlock(@currentEnd)

    true

  _startBlock: (blockStart) ->
    @currentPosition = blockStart
    @currentEnd = @_endOfRangeAfter(@currentPosition)

  _endOfRangeAfter: (point) ->
    guess = new Point(point.row + @blockLines, 0)
    limit = if @wrapped then @startPosition else @editor.getEofBufferPosition()
    if guess.isGreaterThan(limit) then limit else guess

class SearchResults
  @for: (editor) ->
    editor._atomicEmacsSearchResults ?= new SearchResults(editor)

  constructor: (@editor) ->
    @markerLayer = @editor.addMarkerLayer()
    @editor.decorateMarkerLayer @markerLayer,
      type: 'highlight'
      class: 'atomic-emacs-search-result'
    @_numMatches = 0
    @currentDecorations = []

  clear: ->
    @markerLayer.clear()
    @_numMatches = 0

  add: (range) ->
    @_numMatches += 1
    @markerLayer.bufferMarkerLayer.markRange(range)

  numMatches: ->
    @_numMatches

  numMatchesBefore: (point) ->
    markers = @markerLayer.findMarkers
      startsInRange: new Range(new Point(0, 0), point)
    markers.length

  findResultAfter: (point) ->
    # TODO: scan in blocks
    markers = @markerLayer.findMarkers
      startsInRange: new Range(point, @editor.getBuffer().getEndPosition())
    markers[0] or null

  setCurrent: (markers) ->
    # TODO: don't destroy markers that don't need to be destroyed?
    @currentDecorations.forEach (decoration) ->
      decoration.destroy()

    @currentDecorations = markers.map (marker) =>
      @editor.decorateMarker marker,
        type: 'highlight'
        class: 'atomic-emacs-current-result'

module.exports =
class Search
  constructor: ->
    @panel = null
    @searchEditor = null
    @emacsEditor = null

    @searchView = null
    @startCursors = null

    @searcher = null
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

  changed: (text) ->
    @results?.clear()
    @searcher?.stop()

    @results = SearchResults.for(@emacsEditor.editor)
    @results.clear()
    @searchView.resetProgress()

    return if text == ''

    caseSensitive = /[A-Z]/.test(text)

    wrapped = false
    moved = false
    lastCursorPosition = @startCursors[@startCursors.length - 1].head

    # If the query used to match, but no longer does, we need to go back to the
    # original positions.
    @emacsEditor.restoreCursors(@startCursors)

    @searcher = new Searcher
      editor: @emacsEditor.editor
      startPosition: @startCursors[0].head
      # TODO: Escape text, add proper regexp support.
      regex: new RegExp(text, if caseSensitive then '' else 'i')
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

    @searcher?.start()

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
    @searcher?.stop()
    @searcher = null
    @results?.clear()
    @results = null
    @startCursors = null
