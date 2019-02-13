{Point, Range} = require 'atom'
Utils = require './utils'

module.exports =
class SearchResults
  @for: (emacsEditor) ->
    emacsEditor._atomicEmacsSearchResults ?= new SearchResults(emacsEditor)

  constructor: (@emacsEditor) ->
    @editor = @emacsEditor.editor
    @markerLayer = @editor.addMarkerLayer()
    @editor.decorateMarkerLayer @markerLayer,
      type: 'highlight'
      class: 'atomic-emacs-search-result'
    @_numMatches = 0
    @currentDecorations = []

  clear: ->
    @_clearDecorations()
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
    markers = @markerLayer.findMarkers
      startsInRange: new Range(point, @editor.getBuffer().getEndPosition())
    markers[0] or null

  findResultBefore: (point) ->
    if point.isEqual(Utils.BOB)
      return null

    markers = @markerLayer.findMarkers
      startsInRange: new Range(new Point(0, 0), @emacsEditor.positionBefore(point))
    markers[markers.length - 1] or null

  setCurrent: (markers) ->
    @_clearDecorations()

    @currentDecorations = markers.map (marker) =>
      @editor.decorateMarker marker,
        type: 'highlight'
        class: 'atomic-emacs-current-result'

  getCurrent: ->
    @currentDecorations.map (d) -> d.getMarker()

  _clearDecorations: ->
    @currentDecorations.forEach (decoration) ->
      decoration.destroy()
