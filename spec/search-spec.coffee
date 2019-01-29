{Point, Range} = require 'atom'
EmacsEditor = require '../lib/emacs-editor'
Search = require '../lib/search'
SearchResults = require '../lib/search-results'
TestEditor = require './test-editor'

makeRange = (fromRow, fromColumn, toRow, toColumn) ->
  new Range(new Point(fromRow, fromColumn), new Point(toRow, toColumn))

describe 'Search', ->
  beforeEach ->
    waitsForPromise =>
      atom.workspace.open().then (editor) =>
        @editor = editor
        @testEditor = new TestEditor(editor)
        @emacsEditor = EmacsEditor.for(editor)
        @searchResults = SearchResults.for(@emacsEditor)

  describe 'start', ->
    isFinished = (callbacks) ->
      callbacks.length > 0 and callbacks[callbacks.length - 1][0] == 'finished'

    it "searches forward from the start position for a forward search", ->
      @testEditor.setState("abc x [0]abc\nabcx\nabc \n abcabc")
      callbacks = []
      search = new Search
        emacsEditor: @emacsEditor
        startPosition: new Point(0, 6)
        direction: 'forward'
        regex: 'abc'
        onMatch: (range) -> callbacks.push(['match', range])
        onWrapped: -> callbacks.push(['wrapped'])
        onFinished: -> callbacks.push(['finished'])
        blockLines: 2
      search.start()
      until isFinished(callbacks)
        advanceClock(1)
      expect(callbacks[0]).toEqual(['match', Range.fromObject([[0, 6], [0, 9]])])
      expect(callbacks[1]).toEqual(['match', Range.fromObject([[1, 0], [1, 3]])])
      expect(callbacks[2]).toEqual(['match', Range.fromObject([[2, 0], [2, 3]])])
      expect(callbacks[3]).toEqual(['match', Range.fromObject([[3, 1], [3, 4]])])
      expect(callbacks[4]).toEqual(['match', Range.fromObject([[3, 4], [3, 7]])])
      expect(callbacks[5]).toEqual(['wrapped'])
      expect(callbacks[6]).toEqual(['match', Range.fromObject([[0, 0], [0, 3]])])
      expect(callbacks[7]).toEqual(['finished'])

    it "searches backward from the start position for a backward search", ->
      @testEditor.setState("abc x abc\nabcx\nabc[0] \n abcabc")
      callbacks = []
      search = new Search
        emacsEditor: @emacsEditor
        startPosition: new Point(2, 3)
        direction: 'backward'
        regex: 'abc'
        onMatch: (range) -> callbacks.push(['match', range])
        onWrapped: -> callbacks.push(['wrapped'])
        onFinished: -> callbacks.push(['finished'])
        blockLines: 2
      search.start()
      until isFinished(callbacks)
        advanceClock(1)
      expect(callbacks[0]).toEqual(['match', Range.fromObject([[2, 0], [2, 3]])])
      expect(callbacks[1]).toEqual(['match', Range.fromObject([[1, 0], [1, 3]])])
      expect(callbacks[2]).toEqual(['match', Range.fromObject([[0, 6], [0, 9]])])
      expect(callbacks[3]).toEqual(['match', Range.fromObject([[0, 0], [0, 3]])])
      expect(callbacks[4]).toEqual(['wrapped'])
      expect(callbacks[5]).toEqual(['match', Range.fromObject([[3, 4], [3, 7]])])
      expect(callbacks[6]).toEqual(['match', Range.fromObject([[3, 1], [3, 4]])])
      expect(callbacks[7]).toEqual(['finished'])

    it "does not return overlapping matches", ->
      @testEditor.setState("[0]bananana")
      callbacks = []
      search = new Search
        emacsEditor: @emacsEditor
        startPosition: new Point(0, 0)
        direction: 'forward'
        regex: 'ana'
        onMatch: (range) -> callbacks.push(['match', range])
        onWrapped: -> callbacks.push(['wrapped'])
        onFinished: -> callbacks.push(['finished'])
      search.start()
      until isFinished(callbacks)
        advanceClock(1)
      expect(callbacks[0]).toEqual(['match', Range.fromObject([[0, 1], [0, 4]])])
      expect(callbacks[1]).toEqual(['match', Range.fromObject([[0, 5], [0, 8]])])
      expect(callbacks[2]).toEqual(['wrapped'])
      expect(callbacks[3]).toEqual(['finished'])
