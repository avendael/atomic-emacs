{Point, Range} = require 'atom'
Utils = require './utils'

# Handles the search through the buffer from a given starting point, in a given
# direction, wrapping back around to the starting point. Each call to proceed()
# advances up to a limited distance, calling the onMatch callback at most once,
# and return true until the starting point has been reached again. Once that
# happens, proceed() will return false, and will never call the onMatch callback
# anymore.
module.exports =
class Search
  constructor: ({@editor, @startPosition, @direction, @regex, @onMatch, @onWrapped, @onFinished}) ->
    @blockLines = 100

    @buffer = @editor.getBuffer()
    eob = @buffer.getEndPosition()
    [@bufferLimit, @bufferReverseLimit] =
      if @direction == 'forward' then [eob, Utils.BOB] else [Utils.BOB, eob]

    # TODO: Don't assume regex can't span lines. need a configurable overlap?
    @_startBlock(@startPosition)

    @wrapped = false
    @finished = false
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

    if @direction == 'forward'
      @editor.scanInBufferRange @regex, new Range(@currentPosition, @currentLimit), ({range}) =>
        found = true
        @onMatch(range)
        # If range is empty, advance one char to ensure finite progress.
        if range.isEmpty()
          @currentPosition = @buffer.positionForCharacterIndex(@buffer.characterIndexForPosition(range.end) + 1)
        else
          @currentPosition = range.end
        stop()
    else
      @editor.backwardsScanInBufferRange @regex, new Range(@currentLimit, @currentPosition), ({range}) =>
        found = true
        @onMatch(range)
        # If range is empty, advance one char to ensure finite progress.
        if range.isEmpty()
          @currentPosition = @buffer.positionForCharacterIndex(@buffer.characterIndexForPosition(range.start) - 1)
        else
          @currentPosition = range.start
        stop()

    if not found
      if @wrapped and @currentLimit.isEqual(@startPosition)
        @finished = true
        @onFinished()
        return false
      else if not @wrapped and @currentLimit.isEqual(@bufferLimit)
        @wrapped = true
        @onWrapped()
        @_startBlock(@bufferReverseLimit)
      else
        @_startBlock(@currentLimit)

    true

  _startBlock: (blockStart) ->
    @currentPosition = blockStart
    @currentLimit = @_nextLimit(blockStart)

  _nextLimit: (point) ->
    if @direction == 'forward'
      guess = new Point(point.row + @blockLines, 0)
      limit = if @wrapped then @startPosition else @bufferLimit
      if guess.isGreaterThan(limit) then limit else guess
    else
      guess = new Point(point.row - @blockLines, 0)
      limit = if @wrapped then @startPosition else @bufferLimit
      if guess.isLessThan(limit) then limit else guess
