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
    eof = @editor.getEofBufferPosition()
    line = Math.min(point.row + @blockLines, eof.row)
    new Point(line, 0)

class SearchResults
  @for: (editor) ->
    editor._atomicEmacsSearchResults ?= new SearchResults(editor)

  constructor: (@editor) ->
    @markerLayer = @editor.addMarkerLayer()
    @editor.decorateMarkerLayer @markerLayer,
      type: 'highlight'
      class: 'atomic-emacs-search-result'
    @isEmpty = true

  clear: ->
    @markerLayer.clear()
    @isEmpty = true

  add: (range) ->
    @isEmpty = false
    @markerLayer.bufferMarkerLayer.markRange(range)

  findResultAfter: (point) ->
    # TODO: scan in blocks
    markers = @markerLayer.findMarkers
      startsInRange: new Range(point, @editor.getBuffer().getEndPosition())
    markers[0] or null

module.exports =
class Search
  constructor: ->
    @panel = null
    @searchEditor = null
    @emacsEditor = null
    @searcher = null
    @results = null

  start: (@emacsEditor, @direction) ->
    @searchView ?= new SearchView(this)
    @searchView.start()

    @startPositions = @emacsEditor.editor.getCursorsOrderedByBufferPosition().map (cursor) ->
      cursor: cursor
      position: cursor.getBufferPosition()

  exit: ->
    @searchView.exit()
    @emacsEditor.editor.element.focus()

  cancel: ->
    @searchView.cancel()
    @emacsEditor.editor.element.focus()

  repeatFoward: ->
    if @results?
      @_advanceCursors()
    else
      # TODO: repeat last query

  changed: (text) ->
    @results?.clear()
    @searcher?.stop()

    @results = SearchResults.for(@emacsEditor.editor)
    @results.clear()

    wrapped = false
    moved = false
    lastCursorPosition = @startPositions[@startPositions.length - 1].position

    @searcher = new Searcher
      editor: @emacsEditor.editor
      startPosition: @startPositions[0].position
      # TODO: Escape text, add proper regexp support.
      regex: new RegExp(text)
      onMatch: (range) =>
        @results?.add(range, wrapped)
        if not moved and (@results.findResultAfter(lastCursorPosition) or wrapped)
          moved = true
          @_advanceCursors()
      onWrapped: ->
        wrapped = true
      onFinished: =>
        if not @results.isEmpty()
          moved = true
          @_advanceCursors()

    @searcher?.start()

  _advanceCursors: ->
    # TODO: Store request and fire it when we can.
    return if not @results?
    @emacsEditor.moveEmacsCursors (emacsCursor) =>
      marker = @results.findResultAfter(emacsCursor.cursor.getBufferPosition()) or
        @results.findResultAfter(new Point(0, 0))
      emacsCursor.cursor.setBufferPosition(marker.getEndBufferPosition())

  matchFound: (range) =>
    # TODO: Add progress message.


  exited: ->
    @_deactivate()

  canceled: ->
    console.log 'TODO: search canceled'
    @_deactivate()
    # TODO: restore original cursors & selections

  _deactivate: ->
    @searcher = null
    @results.clear()
    @results = null
