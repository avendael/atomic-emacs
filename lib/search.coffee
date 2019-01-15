{Point, Range} = require 'atom'

# Handles the search through the buffer from a given starting point, in a given
# direction, wrapping back around to the starting point. Each call to proceed()
# advances up to a limited distance, calling the onMatch callback at most once,
# and return true until the starting point has been reached again. Once that
# happens, proceed() will return false, and will never call the onMatch callback
# anymore.
module.exports =
class Search
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
