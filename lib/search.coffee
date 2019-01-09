{Point, Range} = require 'atom'
SearchView = require './search-view'

# Handles the search through the buffer from a given starting point, in a given
# direction, wrapping back around to the starting point. Each call to proceed()
# advances up to a limited distance, calling the onMatch callback at most once,
# and return true until the starting point has been reached again. Once that
# happens, proceed() will return false, and will never call the onMatch callback
# anymore.
class Searcher
  constructor: ({@editor, @startPosition, @regex, @onMatch}) ->
    @blockLines = 100
    @wrapped = false
    @finished = false

    # TODO: Don't assume regex can't span lines. need a configurable overlap?
    @_startBlock(@startPosition)
    @buffer = @editor.getBuffer()
    @eob = @buffer.getEndPosition()

  # Proceed with the scan until either a match, or the end of the current range
  # is reached. Return true if the search isn't finished yet, false otherwise.
  proceed: ->
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
        return false
      else if not @wrapped and @currentEnd.isEqual(@eob)
        @wrapped = true
        @currentPosition =
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

module.exports =
class Search
  constructor: ->
    @panel = null
    @searchEditor = null
    @emacsEditor = null
    @searcher = null

  start: (@emacsEditor, @direction) ->
    @searchView ?= new SearchView(this)
    @searchView.start()

  exit: ->
    @searchView.exit()
    @emacsEditor.editor.element.focus()

  cancel: ->
    @searchView.cancel()
    @emacsEditor.editor.element.focus()

  changed: (text) ->
    # TODO: Support multiple cursors.
    console.log "TODO: searching for: #{text}"
    cursor = @emacsEditor.editor.getCursors()[0]
    @searcher = new Searcher
      editor: @emacsEditor.editor,
      startPosition: cursor.getBufferPosition()
      # TODO: Escape text, add proper regexp support.
      regex: new RegExp(text)
      onMatch: (range) => @matchFound(range)
    searcherTask = =>
      if @searcher.proceed()
        setTimeout(searcherTask, 0)
    setTimeout(searcherTask, 0)

  matchFound: (range) =>
    console.log "TODO: match found: #{range}"

  exited: ->

  canceled: ->
    console.log 'TODO: search canceled'
