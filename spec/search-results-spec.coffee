{Point, Range} = require 'atom'
EmacsEditor = require '../lib/emacs-editor'
SearchResults = require '../lib/search-results'
TestEditor = require './test-editor'

markerCoordinates = (marker) ->
  if marker
    range = marker.getBufferRange()
    [range.start.row, range.start.column, range.end.row, range.end.column]
  else
    marker

makeRange = (fromRow, fromColumn, toRow, toColumn) ->
  new Range(new Point(fromRow, fromColumn), new Point(toRow, toColumn))

describe "SearchResults", ->
  beforeEach ->
    waitsForPromise =>
      atom.workspace.open().then (editor) =>
        @editor = editor
        @testEditor = new TestEditor(editor)
        @emacsEditor = EmacsEditor.for(editor)
        @searchResults = SearchResults.for(@emacsEditor)

  describe "numMatches", ->
    beforeEach ->
      @testEditor.setState("[0]abcd")

    it "returns the number of matches added", ->
      expect(@searchResults.numMatches()).toEqual(0)
      @searchResults.add(makeRange(0, 1, 0, 2))
      @searchResults.add(makeRange(0, 2, 0, 3))
      expect(@searchResults.numMatches()).toEqual(2)

    it "is reset when cleared", ->
      expect(@searchResults.numMatches()).toEqual(0)
      @searchResults.add(makeRange(0, 1, 0, 2))
      expect(@searchResults.numMatches()).toEqual(1)

      @searchResults.clear()

      expect(@searchResults.numMatches()).toEqual(0)
      @searchResults.add(makeRange(0, 2, 0, 3))
      expect(@searchResults.numMatches()).toEqual(1)

  describe "numMatchesBefore", ->
    it "returns the number of matches before the given point", ->
      @testEditor.setState("[0]abcdefgh")
      @searchResults.add(makeRange(0, 1, 0, 2))
      @searchResults.add(makeRange(0, 3, 0, 4))
      @searchResults.add(makeRange(0, 4, 0, 5))
      expect(@searchResults.numMatchesBefore(new Point(0, 0))).toEqual(0)
      expect(@searchResults.numMatchesBefore(new Point(0, 1))).toEqual(1)
      expect(@searchResults.numMatchesBefore(new Point(0, 2))).toEqual(1)
      expect(@searchResults.numMatchesBefore(new Point(0, 3))).toEqual(2)
      expect(@searchResults.numMatchesBefore(new Point(0, 4))).toEqual(3)
      expect(@searchResults.numMatchesBefore(new Point(0, 5))).toEqual(3)

  describe "findResultAfter", ->
    it "returns the result after the given point", ->
      @testEditor.setState("[0]abcdefgh")
      @searchResults.add(makeRange(0, 1, 0, 2))
      @searchResults.add(makeRange(0, 2, 0, 3))
      @searchResults.add(makeRange(0, 4, 0, 5))
      expect(markerCoordinates(@searchResults.findResultAfter(new Point(0, 0)))).toEqual([0, 1, 0, 2])
      expect(markerCoordinates(@searchResults.findResultAfter(new Point(0, 1)))).toEqual([0, 1, 0, 2])
      expect(markerCoordinates(@searchResults.findResultAfter(new Point(0, 2)))).toEqual([0, 2, 0, 3])
      expect(markerCoordinates(@searchResults.findResultAfter(new Point(0, 3)))).toEqual([0, 4, 0, 5])
      expect(markerCoordinates(@searchResults.findResultAfter(new Point(0, 4)))).toEqual([0, 4, 0, 5])
      expect(markerCoordinates(@searchResults.findResultAfter(new Point(0, 5)))).toEqual(null)

    it "returns null if the given point is at the end of the buffer", ->
      @testEditor.setState("[0]x")
      @searchResults.add(makeRange(0, 0, 0, 1))
      expect(markerCoordinates(@searchResults.findResultAfter(@editor.getEofBufferPosition()))).toEqual(null)

  describe "findResultBefore", ->
    it "returns the result before the given point", ->
      @testEditor.setState("[0]abcdefgh")
      @searchResults.add(makeRange(0, 1, 0, 2))
      @searchResults.add(makeRange(0, 3, 0, 4))
      @searchResults.add(makeRange(0, 4, 0, 5))
      expect(markerCoordinates(@searchResults.findResultBefore(new Point(0, 0)))).toEqual(null)
      expect(markerCoordinates(@searchResults.findResultBefore(new Point(0, 1)))).toEqual(null)
      expect(markerCoordinates(@searchResults.findResultBefore(new Point(0, 2)))).toEqual([0, 1, 0, 2])
      expect(markerCoordinates(@searchResults.findResultBefore(new Point(0, 3)))).toEqual([0, 1, 0, 2])
      expect(markerCoordinates(@searchResults.findResultBefore(new Point(0, 4)))).toEqual([0, 3, 0, 4])
      expect(markerCoordinates(@searchResults.findResultBefore(new Point(0, 5)))).toEqual([0, 4, 0, 5])

    it "returns null if the given point is the beginning of the buffer", ->
      @testEditor.setState("[0]x")
      @searchResults.add(makeRange(0, 0, 0, 1))
      expect(markerCoordinates(@searchResults.findResultBefore(new Point(0, 0)))).toEqual(null)

  describe "setCurrent", ->
    it "clears existing current markers and decorates the given markers as current", ->
      @testEditor.setState("[0]abcdefgh")
      marker1 = @searchResults.add(makeRange(0, 1, 0, 2))
      marker2 = @searchResults.add(makeRange(0, 3, 0, 4))
      marker3 = @searchResults.add(makeRange(0, 4, 0, 5))

      @searchResults.setCurrent([marker3])
      currentMarkers = @editor.getDecorations(class: 'atomic-emacs-current-result').map (d) ->
        d.getMarker().bufferMarker
      expect(currentMarkers).toEqual([marker3])

      @searchResults.setCurrent([marker1, marker2])
      currentMarkers = @editor.getDecorations(class: 'atomic-emacs-current-result').map (d) ->
        d.getMarker().bufferMarker
      expect(currentMarkers).toEqual([marker1, marker2])
