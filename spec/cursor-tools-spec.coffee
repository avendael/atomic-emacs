{WorkspaceView} = require 'atom'
EditorState = require './editor-state'
CursorTools = require '../lib/cursor-tools'

rangeCoordinates = (range) ->
  if range
    [range.start.row, range.start.column, range.end.row, range.end.column]
  else
    range

describe "CursorTools", ->
  beforeEach ->
    atom.workspaceView = new WorkspaceView
    @editor = atom.project.openSync()
    @cursorTools = new CursorTools(@editor.getCursor())

  describe "locateBackward", ->
    it "returns the range of the previous match if found", ->
      EditorState.set(@editor, "xx xx [0] xx xx")
      range = @cursorTools.locateBackward(/x+/)
      expect(rangeCoordinates(range)).toEqual([0, 3, 0, 5])
      expect(EditorState.get(@editor)).toEqual("xx xx [0] xx xx")

    it "returns null if no match is found", ->
      EditorState.set(@editor, "[0]")
      range = @cursorTools.locateBackward(/x+/)
      expect(range).toBe(null)
      expect(EditorState.get(@editor)).toEqual("[0]")

  describe "locateForward", ->
    it "returns the range of the next match if found", ->
      EditorState.set(@editor, "xx xx [0] xx xx")
      range = @cursorTools.locateForward(/x+/)
      expect(rangeCoordinates(range)).toEqual([0, 7, 0, 9])
      expect(EditorState.get(@editor)).toEqual("xx xx [0] xx xx")

    it "returns null if no match is found", ->
      EditorState.set(@editor, "[0]")
      range = @cursorTools.locateForward(/x+/)
      expect(range).toBe(null)
      expect(EditorState.get(@editor)).toEqual("[0]")

  describe "locateWordCharacterBackward", ->
    it "returns the range of the previous word character if found", ->
      EditorState.set(@editor, " xx  [0]")
      range = @cursorTools.locateWordCharacterBackward()
      expect(rangeCoordinates(range)).toEqual([0, 2, 0, 3])
      expect(EditorState.get(@editor)).toEqual(" xx  [0]")

    it "returns null if there are no word characters behind", ->
      EditorState.set(@editor, "  [0]")
      range = @cursorTools.locateWordCharacterBackward()
      expect(range).toBe(null)
      expect(EditorState.get(@editor)).toEqual("  [0]")

  describe "locateWordCharacterForward", ->
    it "returns the range of the next word character if found", ->
      EditorState.set(@editor, "[0]  xx ")
      range = @cursorTools.locateWordCharacterForward()
      expect(rangeCoordinates(range)).toEqual([0, 2, 0, 3])
      expect(EditorState.get(@editor)).toEqual("[0]  xx ")

    it "returns null if there are no word characters ahead", ->
      EditorState.set(@editor, "[0]  ")
      range = @cursorTools.locateWordCharacterForward()
      expect(range).toBe(null)
      expect(EditorState.get(@editor)).toEqual("[0]  ")

  describe "locateNonWordCharacterBackward", ->
    it "returns the range of the previous nonword character if found", ->
      EditorState.set(@editor, "x  xx[0]")
      range = @cursorTools.locateNonWordCharacterBackward()
      expect(rangeCoordinates(range)).toEqual([0, 2, 0, 3])
      expect(EditorState.get(@editor)).toEqual("x  xx[0]")

    it "returns null if there are no nonword characters behind", ->
      EditorState.set(@editor, "xx[0]")
      range = @cursorTools.locateNonWordCharacterBackward()
      expect(range).toBe(null)
      expect(EditorState.get(@editor)).toEqual("xx[0]")

  describe "locateNonWordCharacterForward", ->
    it "returns the range of the next nonword character if found", ->
      EditorState.set(@editor, "[0]xx  x")
      range = @cursorTools.locateNonWordCharacterForward()
      expect(rangeCoordinates(range)).toEqual([0, 2, 0, 3])
      expect(EditorState.get(@editor)).toEqual("[0]xx  x")

    it "returns null if there are no nonword characters ahead", ->
      EditorState.set(@editor, "[0]xx")
      range = @cursorTools.locateNonWordCharacterForward()
      expect(range).toBe(null)
      expect(EditorState.get(@editor)).toEqual("[0]xx")

  describe "goToMatchStartBackward", ->
    it "moves to the start of the previous match and returns true if a match is found", ->
      EditorState.set(@editor, "xx xx [0] xx xx")
      result = @cursorTools.goToMatchStartBackward(/x+/)
      expect(result).toBe(true)
      expect(EditorState.get(@editor)).toEqual("xx [0]xx  xx xx")

    it "does not move and returns false if no match is found", ->
      EditorState.set(@editor, "xx xx [0] xx xx")
      result = @cursorTools.goToMatchStartBackward(/y+/)
      expect(result).toBe(false)
      expect(EditorState.get(@editor)).toEqual("xx xx [0] xx xx")

  describe "goToMatchStartForward", ->
    it "moves to the start of the next match and returns true if a match is found", ->
      EditorState.set(@editor, "xx xx [0] xx xx")
      result = @cursorTools.goToMatchStartForward(/x+/)
      expect(result).toBe(true)
      expect(EditorState.get(@editor)).toEqual("xx xx  [0]xx xx")

    it "does not move and returns false if no match is found", ->
      EditorState.set(@editor, "xx xx [0] xx xx")
      result = @cursorTools.goToMatchStartForward(/y+/)
      expect(result).toBe(false)
      expect(EditorState.get(@editor)).toEqual("xx xx [0] xx xx")

  describe "goToMatchEndBackward", ->
    it "moves to the end of the previous match and returns true if a match is found", ->
      EditorState.set(@editor, "xx xx [0] xx xx")
      result = @cursorTools.goToMatchEndBackward(/x+/)
      expect(result).toBe(true)
      expect(EditorState.get(@editor)).toEqual("xx xx[0]  xx xx")

    it "does not move and returns false if no match is found", ->
      EditorState.set(@editor, "xx xx [0] xx xx")
      result = @cursorTools.goToMatchEndBackward(/y+/)
      expect(result).toBe(false)
      expect(EditorState.get(@editor)).toEqual("xx xx [0] xx xx")

  describe "goToMatchEndForward", ->
    it "moves to the end of the next match and returns true if a match is found", ->
      EditorState.set(@editor, "xx xx [0] xx xx")
      result = @cursorTools.goToMatchEndForward(/x+/)
      expect(result).toBe(true)
      expect(EditorState.get(@editor)).toEqual("xx xx  xx[0] xx")

    it "does not move and returns false if no match is found", ->
      EditorState.set(@editor, "xx xx [0] xx xx")
      result = @cursorTools.goToMatchEndForward(/y+/)
      expect(result).toBe(false)
      expect(EditorState.get(@editor)).toEqual("xx xx [0] xx xx")

  describe "skipCharactersBackward", ->
    it "moves backward over the given characters", ->
      EditorState.set(@editor, "x..x..[0]")
      @cursorTools.skipCharactersBackward('.')
      expect(EditorState.get(@editor)).toEqual("x..x[0]..")

    it "does not move if the previous character is not in the list", ->
      EditorState.set(@editor, "..x[0]")
      @cursorTools.skipCharactersBackward('.')
      expect(EditorState.get(@editor)).toEqual("..x[0]")

    it "moves to the beginning of the buffer if all prior characters are in the list", ->
      EditorState.set(@editor, "..[0]")
      @cursorTools.skipCharactersBackward('.')
      expect(EditorState.get(@editor)).toEqual("[0]..")

  describe "skipCharactersForward", ->
    it "moves forward over the given characters", ->
      EditorState.set(@editor, "[0]..x..x")
      @cursorTools.skipCharactersForward('.')
      expect(EditorState.get(@editor)).toEqual("..[0]x..x")

    it "does not move if the next character is not in the list", ->
      EditorState.set(@editor, "[0]x..")
      @cursorTools.skipCharactersForward('.')
      expect(EditorState.get(@editor)).toEqual("[0]x..")

    it "moves to the end of the buffer if all following characters are in the list", ->
      EditorState.set(@editor, "[0]..")
      @cursorTools.skipCharactersForward('.')
      expect(EditorState.get(@editor)).toEqual("..[0]")

  describe "skipWordCharactersBackward", ->
    it "moves over any word characters backward", ->
      EditorState.set(@editor, "abc abc[0]abc abc")
      @cursorTools.skipWordCharactersBackward()
      expect(EditorState.get(@editor)).toEqual("abc [0]abcabc abc")

    it "does not move if the previous character is not a word character", ->
      EditorState.set(@editor, "abc abc [0]")
      @cursorTools.skipWordCharactersBackward()
      expect(EditorState.get(@editor)).toEqual("abc abc [0]")

    it "moves to the beginning of the buffer if all prior characters are word characters", ->
      EditorState.set(@editor, "abc[0]")
      @cursorTools.skipWordCharactersBackward()
      expect(EditorState.get(@editor)).toEqual("[0]abc")

  describe "skipWordCharactersForward", ->
    it "moves over any word characters forward", ->
      EditorState.set(@editor, "abc abc[0]abc abc")
      @cursorTools.skipWordCharactersForward()
      expect(EditorState.get(@editor)).toEqual("abc abcabc[0] abc")

    it "does not move if the next character is not a word character", ->
      EditorState.set(@editor, "[0] abc abc")
      @cursorTools.skipWordCharactersForward()
      expect(EditorState.get(@editor)).toEqual("[0] abc abc")

    it "moves to the end of the buffer if all following characters are word characters", ->
      EditorState.set(@editor, "[0]abc")
      @cursorTools.skipWordCharactersForward()
      expect(EditorState.get(@editor)).toEqual("abc[0]")

  describe "skipNonWordCharactersBackward", ->
    it "moves over any nonword characters backward", ->
      EditorState.set(@editor, "   x   [0]   x   ")
      @cursorTools.skipNonWordCharactersBackward()
      expect(EditorState.get(@editor)).toEqual("   x[0]      x   ")

    it "does not move if the previous character is a word character", ->
      EditorState.set(@editor, "   x   x[0]")
      @cursorTools.skipNonWordCharactersBackward()
      expect(EditorState.get(@editor)).toEqual("   x   x[0]")

    it "moves to the beginning of the buffer if all prior characters are nonword characters", ->
      EditorState.set(@editor, "   [0]")
      @cursorTools.skipNonWordCharactersBackward()
      expect(EditorState.get(@editor)).toEqual("[0]   ")

  describe "skipNonWordCharactersForward", ->
    it "moves over any word characters forward", ->
      EditorState.set(@editor, "   x   [0]   x   ")
      @cursorTools.skipNonWordCharactersForward()
      expect(EditorState.get(@editor)).toEqual("   x      [0]x   ")

    it "does not move if the next character is a word character", ->
      EditorState.set(@editor, "[0]x   x   ")
      @cursorTools.skipNonWordCharactersForward()
      expect(EditorState.get(@editor)).toEqual("[0]x   x   ")

    it "moves to the end of the buffer if all following characters are nonword characters", ->
      EditorState.set(@editor, "[0]   ")
      @cursorTools.skipNonWordCharactersForward()
      expect(EditorState.get(@editor)).toEqual("   [0]")

  describe "skipBackwardUntil", ->
    it "moves backward over the given characters", ->
      EditorState.set(@editor, "x..x..[0]")
      @cursorTools.skipBackwardUntil(/[^\.]/)
      expect(EditorState.get(@editor)).toEqual("x..x[0]..")

    it "does not move if the previous character is not in the list", ->
      EditorState.set(@editor, "..x[0]")
      @cursorTools.skipBackwardUntil(/[^\.]/)
      expect(EditorState.get(@editor)).toEqual("..x[0]")

    it "moves to the beginning of the buffer if all prior characters are in the list", ->
      EditorState.set(@editor, "..[0]")
      @cursorTools.skipBackwardUntil(/[^\.]/)
      expect(EditorState.get(@editor)).toEqual("[0]..")

  describe "skipForwardUntil", ->
    it "moves forward over the given characters", ->
      EditorState.set(@editor, "[0]..x..x")
      @cursorTools.skipForwardUntil(/[^\.]/)
      expect(EditorState.get(@editor)).toEqual("..[0]x..x")

    it "does not move if the next character is not in the list", ->
      EditorState.set(@editor, "[0]x..")
      @cursorTools.skipForwardUntil(/[^\.]/)
      expect(EditorState.get(@editor)).toEqual("[0]x..")

    it "moves to the end of the buffer if all following characters are in the list", ->
      EditorState.set(@editor, "[0]..")
      @cursorTools.skipForwardUntil(/[^\.]/)
      expect(EditorState.get(@editor)).toEqual("..[0]")

  describe "extractWord", ->
    it "removes and returns the word the cursor is in", ->
      EditorState.set(@editor, "aa bb[0]cc dd")
      word = @cursorTools.extractWord()
      expect(word).toEqual("bbcc")
      expect(EditorState.get(@editor)).toEqual("aa [0] dd")

    it "removes and returns the word the cursor is at the start of", ->
      EditorState.set(@editor, "aa [0]bb cc")
      word = @cursorTools.extractWord()
      expect(word).toEqual("bb")
      expect(EditorState.get(@editor)).toEqual("aa [0] cc")

    it "removes and returns the word the cursor is at the end of", ->
      EditorState.set(@editor, "aa bb[0] cc")
      word = @cursorTools.extractWord()
      expect(word).toEqual("bb")
      expect(EditorState.get(@editor)).toEqual("aa [0] cc")

    it "returns an empty string and removes nothing if the cursor is not in a word", ->
      EditorState.set(@editor, "aa [0] bb")
      word = @cursorTools.extractWord()
      expect(word).toEqual("")
      expect(EditorState.get(@editor)).toEqual("aa [0] bb")

    it "returns an empty string and removes nothing if not in a word at the start of the buffer", ->
      EditorState.set(@editor, "[0] aa")
      word = @cursorTools.extractWord()
      expect(word).toEqual("")
      expect(EditorState.get(@editor)).toEqual("[0] aa")

    it "returns an empty string and removes nothing if not in a word at the end of the buffer", ->
      EditorState.set(@editor, "aa [0]")
      word = @cursorTools.extractWord()
      expect(word).toEqual("")
      expect(EditorState.get(@editor)).toEqual("aa [0]")

    it "returns and removes the only word in a buffer if inside it", ->
      EditorState.set(@editor, "a[0]b")
      word = @cursorTools.extractWord()
      expect(word).toEqual("ab")
      expect(EditorState.get(@editor)).toEqual("[0]")
