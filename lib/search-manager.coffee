{Point, Range} = require 'atom'
Search = require './search'
SearchResults = require './search-results'
SearchView = require './search-view'
Utils = require './utils'

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

  start: (@emacsEditor, {direction}) ->
    @searchView ?= new SearchView(this)
    @searchView.start({direction})
    @startCursors = @emacsEditor.saveCursors()

  exit: ->
    @searchView.exit()
    @emacsEditor.editor.element.focus()

  cancel: ->
    @searchView.cancel()
    @emacsEditor.editor.element.focus()

  repeat: (direction) ->
    if @searchView.isEmpty()
      @searchView.repeatLastQuery(direction)
      return

    if @results?
      @_advanceCursors(direction)

  toggleCaseSensitivity: ->
    @searchView.toggleCaseSensitivity()

  toggleIsRegExp: ->
    @searchView.toggleIsRegExp()

  yankWordOrCharacter: ->
    if @emacsEditor.editor.hasMultipleCursors()
      # TODO: display this in the SearchView
      atom.notifications.addInfo "Can't yank into search when using multiple cursors"

    emacsCursor = @emacsEditor.getEmacsCursors()[0]
    range = @_wordOrCharacterRangeFrom(emacsCursor)
    text = @emacsEditor.editor.getTextInBufferRange(range)
    @searchView.append(text)

  _wordOrCharacterRangeFrom: (emacsCursor) ->
    eob = @emacsEditor.editor.getBuffer().getEndPosition()
    point = emacsCursor.cursor.getBufferPosition()
    alphanumPattern = /[a-z0-9]/i

    nextChar = @_charAhead(point, 0)

    doWord = alphanumPattern.test(nextChar) or alphanumPattern.test(@_charAhead(point, 1))
    target =
      if doWord
        range = emacsCursor.locateForward(alphanumPattern)
        if range
          range = @emacsEditor.locateForwardFrom(range.start, /[^a-z0-9]/i)
        if range then range.start else eob
      else
        if /[ \t]/.test(nextChar)
          range = emacsCursor.locateForward(/[^ \t]/)
          if range then range.start else eob
        else
          @emacsEditor.positionAfter(point) or eob
    new Range(point, target)

  _charAhead: (point, zeroOrOne) ->
    if zeroOrOne == 1
      point = @emacsEditor.positionAfter(point)
    pointPlus1 = @emacsEditor.positionAfter(point)
    @emacsEditor.editor.getTextInBufferRange([point, pointPlus1])

  changed: (text, {caseSensitive, isRegExp, direction}) ->
    @results?.clear()
    @search?.stop()

    @results = SearchResults.for(@emacsEditor.editor)
    @results.clear()
    @searchView.resetProgress()

    return if text == ''

    caseSensitive = caseSensitive or (not isRegExp and /[A-Z]/.test(text))

    sortedCursors = @startCursors.sort (a, b) ->
      headComparison = a.head.compare(b.head)

    wrapped = false
    moved = false
    canMove = =>
      if direction == 'forward'
        lastCursorPosition = sortedCursors[sortedCursors.length - 1].head
        @results.findResultAfter(lastCursorPosition)
      else
        firstCursorPosition = sortedCursors[0].head
        @results.findResultBefore(firstCursorPosition)

    @search = new Search
      editor: @emacsEditor.editor
      startPosition: sortedCursors[0].head
      direction: direction
      regex: new RegExp(
        if isRegExp then text else Utils.escapeForRegExp(text)
        if caseSensitive then '' else 'i'
      )
      onMatch: (range) =>
        return if not @results?
        @results.add(range, wrapped)
        @searchView.setTotal(@results.numMatches())
        if not moved and (canMove() or wrapped)
          @_advanceCursors(direction)
          moved = true
      onWrapped: ->
        wrapped = true
      onFinished: =>
        return if not @results?
        if @results.numMatches() == 0
          @emacsEditor.restoreCursors(@startCursors)
        else if not moved
          @_advanceCursors(direction)
        @searchView.scanningDone()

    @search?.start()

  _advanceCursors: (direction) ->
    # TODO: Store request and fire it when we can.
    return if not @results?
    return if @results.numMatches() == 0

    markers = []
    if direction == 'forward'
      @emacsEditor.moveEmacsCursors (emacsCursor) =>
        marker = @results.findResultAfter(emacsCursor.cursor.getBufferPosition())
        if marker == null
          @searchView.showWrapIcon(direction)
          marker = @results.findResultAfter(new Point(0, 0))
        emacsCursor.cursor.setBufferPosition(marker.getEndBufferPosition())
        markers.push(marker)
    else
      @emacsEditor.moveEmacsCursors (emacsCursor) =>
        marker = @results.findResultBefore(emacsCursor.cursor.getBufferPosition())
        if marker == null
          @searchView.showWrapIcon(direction)
          marker = @results.findResultBefore(@emacsEditor.editor.getBuffer().getEndPosition())
        emacsCursor.cursor.setBufferPosition(marker.getStartBufferPosition())
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
