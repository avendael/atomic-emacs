{Point} = require 'atom'
EmacsEditor = require '../lib/emacs-editor'
TestEditor = require './test-editor'

rangeCoordinates = (range) ->
  if range
    [range.start.row, range.start.column, range.end.row, range.end.column]
  else
    range

describe "EmacsEditor", ->
  beforeEach ->
    waitsForPromise =>
      atom.workspace.open().then (editor) =>
        @editor = editor
        @testEditor = new TestEditor(editor)
        @emacsEditor = EmacsEditor.for(editor)

  describe "saveCursors", ->
    it "returns each cursor's head and tail", ->
      @testEditor.setState("a[0]b(0)c\nd(1)e[1]f")
      result = @emacsEditor.saveCursors()
      expect(result.length).toEqual(2)
      expect(result[0].head.isEqual(new Point(0, 1))).toBe(true)
      expect(result[0].tail.isEqual(new Point(0, 2))).toBe(true)
      expect(result[1].head.isEqual(new Point(1, 2))).toBe(true)
      expect(result[1].tail.isEqual(new Point(1, 1))).toBe(true)

    it "returns whether each cursor's mark was active", ->
      @testEditor.setState("a[0]b(0)c\nd(1)e[1]f")
      @emacsEditor.getEmacsCursors().map (c) -> c.mark().set().activate()
      result = @emacsEditor.saveCursors()
      expect(result.map (c) -> c.markActive).toEqual([true, true])

  describe "restoreCursors", ->
    it "restores state saved by saveCursors", ->
      @testEditor.setState("a[0]b(0)c\nd(1)e[1]f")
      cursors = @emacsEditor.saveCursors()

      @testEditor.setState('[0]abc\ndef')
      @emacsEditor.restoreCursors(cursors)
      expect(@testEditor.getState()).toEqual("a[0]b(0)c\nd(1)e[1]f")

  describe "positionAfter", ->
    beforeEach ->
      @testEditor.setState("abc\ndef")

    it "returns the position to the right if there is one", ->
      result = @emacsEditor.positionAfter(new Point(0, 1))
      expect(result.isEqual(new Point(0, 2))).toBe(true)

    it "returns end of line if before the last character in the line", ->
      result = @emacsEditor.positionAfter(new Point(0, 2))
      expect(result.isEqual(new Point(0, 3))).toBe(true)

    it "returns the first position on the next line if at end of line", ->
      result = @emacsEditor.positionAfter(new Point(0, 3))
      expect(result.isEqual(new Point(1, 0))).toBe(true)

    it "returns null if at end of buffer", ->
      result = @emacsEditor.positionAfter(new Point(1, 3))
      expect(result).toBe(null)

  describe "positionBefore", ->
    beforeEach ->
      @testEditor.setState("abc\ndef")

    it "returns the position tot he left if there is one", ->
      result = @emacsEditor.positionBefore(new Point(1, 2))
      expect(result.isEqual(new Point(1, 1))).toBe(true)

    it "returns beginning of line if after the first character in the line", ->
      result = @emacsEditor.positionBefore(new Point(1, 1))
      expect(result.isEqual(new Point(1, 0))).toBe(true)

    it "returns the last position on the previous line if at beginning of line", ->
      result = @emacsEditor.positionBefore(new Point(1, 0))
      expect(result.isEqual(new Point(0, 3))).toBe(true)

    it "returns null if at beginning of buffer", ->
      result = @emacsEditor.positionBefore(new Point(0, 0))
      expect(result).toBe(null)

  describe "characterAfter", ->
    beforeEach ->
      @testEditor.setState("abc\ndef")

    it "returns the character to the right if there is one", ->
      result = @emacsEditor.characterAfter(new Point(0, 1))
      expect(result).toEqual('b')

    it "returns the last character if before the last character in the line", ->
      result = @emacsEditor.characterAfter(new Point(0, 2))
      expect(result).toEqual('c')

    it "returns a newline if at end of line", ->
      result = @emacsEditor.characterAfter(new Point(0, 3))
      expect(result).toEqual('\n')

    it "returns the first character if at beginning of line", ->
      result = @emacsEditor.characterAfter(new Point(1, 0))
      expect(result).toEqual('d')

    it "returns null if at end of buffer", ->
      result = @emacsEditor.characterAfter(new Point(1, 3))
      expect(result).toBe(null)

  describe "characterBefore", ->
    beforeEach ->
      @testEditor.setState("abc\ndef")

    it "returns the character to the left if there is one", ->
      result = @emacsEditor.characterBefore(new Point(1, 2))
      expect(result).toEqual('e')

    it "returns the first character if after the first character in the line", ->
      result = @emacsEditor.characterBefore(new Point(1, 1))
      expect(result).toEqual('d')

    it "returns a newline if at beginning of line", ->
      result = @emacsEditor.characterBefore(new Point(1, 0))
      expect(result).toEqual('\n')

    it "returns the last character if at end of line", ->
      result = @emacsEditor.characterBefore(new Point(0, 3))
      expect(result).toEqual('c')

    it "returns null if at beginning of buffer", ->
      result = @emacsEditor.characterBefore(new Point(0, 0))
      expect(result).toBe(null)

  describe "locateBackwardFrom", ->
    it "returns the range of the previous match from the given point", ->
      @testEditor.setState("abcde\nfghij")
      range = @emacsEditor.locateBackwardFrom(new Point(1, 4), /b.d/)
      expect(rangeCoordinates(range)).toEqual([0, 1, 0, 4])

    it "returns null if there is no such match", ->
      @testEditor.setState("abcde\nfghij")
      range = @emacsEditor.locateBackwardFrom(new Point(0, 3), /b.d/)
      expect(range).toBe(null)

  describe "locateForwardFrom", ->
    it "returns the range of the next match from the given point", ->
      @testEditor.setState("abcde\nfghij")
      range = @emacsEditor.locateForwardFrom(new Point(0, 1), /g.i/)
      expect(rangeCoordinates(range)).toEqual([1, 1, 1, 4])

    it "returns null if there is no such match", ->
      @testEditor.setState("abcde\nfghij")
      range = @emacsEditor.locateForwardFrom(new Point(1, 2), /b.d/)
      expect(range).toBe(null)
