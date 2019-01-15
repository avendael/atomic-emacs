{Point, Range} = require 'atom'

module.exports =
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
