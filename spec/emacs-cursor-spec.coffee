EmacsCursor = require '../lib/emacs-cursor'
KillRing = require '../lib/kill-ring'
TestEditor = require './test-editor'

rangeCoordinates = (range) ->
  if range
    [range.start.row, range.start.column, range.end.row, range.end.column]
  else
    range

describe "EmacsCursor", ->
  beforeEach ->
    waitsForPromise =>
      atom.workspace.open().then (editor) =>
        @editor = editor
        @testEditor = new TestEditor(editor)
        @emacsCursor = EmacsCursor.for(editor.getLastCursor())

  describe "destroy", ->
    beforeEach ->
      @testEditor.setState("[0].")
      @emacsCursor = EmacsCursor.for(@editor.getCursors()[0])
      @startingMarkerCount = @editor.getMarkers().length

    it "cleans up markers set by the mark", ->
      @emacsCursor.mark().set().activate()
      expect(@editor.getMarkers().length).toBeGreaterThan(@startingMarkerCount)

      @emacsCursor.destroy()
      expect(@editor.getMarkers().length).toEqual(@startingMarkerCount)

    it "cleans up the yank marker", ->
      @emacsCursor.killRing().push('x')
      @emacsCursor.yank()
      expect(@editor.getMarkers().length).toBeGreaterThan(@startingMarkerCount)

      @emacsCursor.destroy()
      expect(@editor.getMarkers().length).toEqual(@startingMarkerCount)

  describe "mark", ->
    it "returns a mark for the cursor", ->
      @testEditor.setState("a[0]b[1]c")
      [emacsCursor0, emacsCursor1] = (EmacsCursor.for(c) for c in @editor.getCursors())
      expect(emacsCursor0.mark().cursor).toBe(emacsCursor0.cursor)
      expect(emacsCursor1.mark().cursor).toBe(emacsCursor1.cursor)

    it "returns the same Mark each time for a cursor", ->
      a = @emacsCursor.mark()
      b = @emacsCursor.mark()
      expect(a).toBe(b)

  describe "killRing", ->
    beforeEach ->
      @testEditor.setState("[0].")
      @emacsCursor = EmacsCursor.for(@editor.getCursors()[0])

    describe "when the editor has a single cursor", ->
      it "returns the global kill ring", ->
        expect(@emacsCursor.killRing()).toBe(KillRing.global)

    describe "when the editor has multiple cursors", ->
      beforeEach ->
        @testEditor.setState("[0].[1]")
        [@emacsCursor0, @emacsCursor1] = (EmacsCursor.for(c) for c in @editor.getCursors())

      it "returns a kill ring for the cursor", ->
        killRing0 = @emacsCursor0.killRing()
        killRing1 = @emacsCursor1.killRing()
        expect(killRing0.constructor).toBe(KillRing)
        expect(killRing1.constructor).toBe(KillRing)
        expect(killRing0).not.toBe(killRing1)

      it "returns the same KillRing each time for a cursor", ->
        a = @emacsCursor0.killRing()
        b = @emacsCursor0.killRing()
        expect(a).toBe(b)

  describe "locateBackward", ->
    it "returns the range of the previous match if found", ->
      @testEditor.setState("xx xx [0] xx xx")
      range = @emacsCursor.locateBackward(/x+/)
      expect(rangeCoordinates(range)).toEqual([0, 3, 0, 5])
      expect(@testEditor.getState()).toEqual("xx xx [0] xx xx")

    it "returns null if no match is found", ->
      @testEditor.setState("[0]")
      range = @emacsCursor.locateBackward(/x+/)
      expect(range).toBe(null)
      expect(@testEditor.getState()).toEqual("[0]")

  describe "locateForward", ->
    it "returns the range of the next match if found", ->
      @testEditor.setState("xx xx [0] xx xx")
      range = @emacsCursor.locateForward(/x+/)
      expect(rangeCoordinates(range)).toEqual([0, 7, 0, 9])
      expect(@testEditor.getState()).toEqual("xx xx [0] xx xx")

    it "returns null if no match is found", ->
      @testEditor.setState("[0]")
      range = @emacsCursor.locateForward(/x+/)
      expect(range).toBe(null)
      expect(@testEditor.getState()).toEqual("[0]")

  describe "locateWordCharacterBackward", ->
    it "returns the range of the previous word character if found", ->
      @testEditor.setState(" xx  [0]")
      range = @emacsCursor.locateWordCharacterBackward()
      expect(rangeCoordinates(range)).toEqual([0, 2, 0, 3])
      expect(@testEditor.getState()).toEqual(" xx  [0]")

    it "returns null if there are no word characters behind", ->
      @testEditor.setState("  [0]")
      range = @emacsCursor.locateWordCharacterBackward()
      expect(range).toBe(null)
      expect(@testEditor.getState()).toEqual("  [0]")

  describe "locateWordCharacterForward", ->
    it "returns the range of the next word character if found", ->
      @testEditor.setState("[0]  xx ")
      range = @emacsCursor.locateWordCharacterForward()
      expect(rangeCoordinates(range)).toEqual([0, 2, 0, 3])
      expect(@testEditor.getState()).toEqual("[0]  xx ")

    it "returns null if there are no word characters ahead", ->
      @testEditor.setState("[0]  ")
      range = @emacsCursor.locateWordCharacterForward()
      expect(range).toBe(null)
      expect(@testEditor.getState()).toEqual("[0]  ")

  describe "locateNonWordCharacterBackward", ->
    it "returns the range of the previous nonword character if found", ->
      @testEditor.setState("x  xx[0]")
      range = @emacsCursor.locateNonWordCharacterBackward()
      expect(rangeCoordinates(range)).toEqual([0, 2, 0, 3])
      expect(@testEditor.getState()).toEqual("x  xx[0]")

    it "returns null if there are no nonword characters behind", ->
      @testEditor.setState("xx[0]")
      range = @emacsCursor.locateNonWordCharacterBackward()
      expect(range).toBe(null)
      expect(@testEditor.getState()).toEqual("xx[0]")

  describe "locateNonWordCharacterForward", ->
    it "returns the range of the next nonword character if found", ->
      @testEditor.setState("[0]xx  x")
      range = @emacsCursor.locateNonWordCharacterForward()
      expect(rangeCoordinates(range)).toEqual([0, 2, 0, 3])
      expect(@testEditor.getState()).toEqual("[0]xx  x")

    it "returns null if there are no nonword characters ahead", ->
      @testEditor.setState("[0]xx")
      range = @emacsCursor.locateNonWordCharacterForward()
      expect(range).toBe(null)
      expect(@testEditor.getState()).toEqual("[0]xx")

  describe "goToMatchStartBackward", ->
    it "moves to the start of the previous match and returns true if a match is found", ->
      @testEditor.setState("xx xx [0] xx xx")
      result = @emacsCursor.goToMatchStartBackward(/x+/)
      expect(result).toBe(true)
      expect(@testEditor.getState()).toEqual("xx [0]xx  xx xx")

    it "does not move and returns false if no match is found", ->
      @testEditor.setState("xx xx [0] xx xx")
      result = @emacsCursor.goToMatchStartBackward(/y+/)
      expect(result).toBe(false)
      expect(@testEditor.getState()).toEqual("xx xx [0] xx xx")

  describe "goToMatchStartForward", ->
    it "moves to the start of the next match and returns true if a match is found", ->
      @testEditor.setState("xx xx [0] xx xx")
      result = @emacsCursor.goToMatchStartForward(/x+/)
      expect(result).toBe(true)
      expect(@testEditor.getState()).toEqual("xx xx  [0]xx xx")

    it "does not move and returns false if no match is found", ->
      @testEditor.setState("xx xx [0] xx xx")
      result = @emacsCursor.goToMatchStartForward(/y+/)
      expect(result).toBe(false)
      expect(@testEditor.getState()).toEqual("xx xx [0] xx xx")

  describe "goToMatchEndBackward", ->
    it "moves to the end of the previous match and returns true if a match is found", ->
      @testEditor.setState("xx xx [0] xx xx")
      result = @emacsCursor.goToMatchEndBackward(/x+/)
      expect(result).toBe(true)
      expect(@testEditor.getState()).toEqual("xx xx[0]  xx xx")

    it "does not move and returns false if no match is found", ->
      @testEditor.setState("xx xx [0] xx xx")
      result = @emacsCursor.goToMatchEndBackward(/y+/)
      expect(result).toBe(false)
      expect(@testEditor.getState()).toEqual("xx xx [0] xx xx")

  describe "goToMatchEndForward", ->
    it "moves to the end of the next match and returns true if a match is found", ->
      @testEditor.setState("xx xx [0] xx xx")
      result = @emacsCursor.goToMatchEndForward(/x+/)
      expect(result).toBe(true)
      expect(@testEditor.getState()).toEqual("xx xx  xx[0] xx")

    it "does not move and returns false if no match is found", ->
      @testEditor.setState("xx xx [0] xx xx")
      result = @emacsCursor.goToMatchEndForward(/y+/)
      expect(result).toBe(false)
      expect(@testEditor.getState()).toEqual("xx xx [0] xx xx")

  describe "skipCharactersBackward", ->
    it "moves backward over the given characters", ->
      @testEditor.setState("x..x..[0]")
      @emacsCursor.skipCharactersBackward('.')
      expect(@testEditor.getState()).toEqual("x..x[0]..")

    it "does not move if the previous character is not in the list", ->
      @testEditor.setState("..x[0]")
      @emacsCursor.skipCharactersBackward('.')
      expect(@testEditor.getState()).toEqual("..x[0]")

    it "moves to the beginning of the buffer if all prior characters are in the list", ->
      @testEditor.setState("..[0]")
      @emacsCursor.skipCharactersBackward('.')
      expect(@testEditor.getState()).toEqual("[0]..")

  describe "skipCharactersForward", ->
    it "moves forward over the given characters", ->
      @testEditor.setState("[0]..x..x")
      @emacsCursor.skipCharactersForward('.')
      expect(@testEditor.getState()).toEqual("..[0]x..x")

    it "does not move if the next character is not in the list", ->
      @testEditor.setState("[0]x..")
      @emacsCursor.skipCharactersForward('.')
      expect(@testEditor.getState()).toEqual("[0]x..")

    it "moves to the end of the buffer if all following characters are in the list", ->
      @testEditor.setState("[0]..")
      @emacsCursor.skipCharactersForward('.')
      expect(@testEditor.getState()).toEqual("..[0]")

  describe "skipWordCharactersBackward", ->
    it "moves over any word characters backward", ->
      @testEditor.setState("abc abc[0]abc abc")
      @emacsCursor.skipWordCharactersBackward()
      expect(@testEditor.getState()).toEqual("abc [0]abcabc abc")

    it "does not move if the previous character is not a word character", ->
      @testEditor.setState("abc abc [0]")
      @emacsCursor.skipWordCharactersBackward()
      expect(@testEditor.getState()).toEqual("abc abc [0]")

    it "moves to the beginning of the buffer if all prior characters are word characters", ->
      @testEditor.setState("abc[0]")
      @emacsCursor.skipWordCharactersBackward()
      expect(@testEditor.getState()).toEqual("[0]abc")

  describe "skipWordCharactersForward", ->
    it "moves over any word characters forward", ->
      @testEditor.setState("abc abc[0]abc abc")
      @emacsCursor.skipWordCharactersForward()
      expect(@testEditor.getState()).toEqual("abc abcabc[0] abc")

    it "does not move if the next character is not a word character", ->
      @testEditor.setState("[0] abc abc")
      @emacsCursor.skipWordCharactersForward()
      expect(@testEditor.getState()).toEqual("[0] abc abc")

    it "moves to the end of the buffer if all following characters are word characters", ->
      @testEditor.setState("[0]abc")
      @emacsCursor.skipWordCharactersForward()
      expect(@testEditor.getState()).toEqual("abc[0]")

  describe "skipNonWordCharactersBackward", ->
    it "moves over any nonword characters backward", ->
      @testEditor.setState("   x   [0]   x   ")
      @emacsCursor.skipNonWordCharactersBackward()
      expect(@testEditor.getState()).toEqual("   x[0]      x   ")

    it "does not move if the previous character is a word character", ->
      @testEditor.setState("   x   x[0]")
      @emacsCursor.skipNonWordCharactersBackward()
      expect(@testEditor.getState()).toEqual("   x   x[0]")

    it "moves to the beginning of the buffer if all prior characters are nonword characters", ->
      @testEditor.setState("   [0]")
      @emacsCursor.skipNonWordCharactersBackward()
      expect(@testEditor.getState()).toEqual("[0]   ")

  describe "skipNonWordCharactersForward", ->
    it "moves over any word characters forward", ->
      @testEditor.setState("   x   [0]   x   ")
      @emacsCursor.skipNonWordCharactersForward()
      expect(@testEditor.getState()).toEqual("   x      [0]x   ")

    it "does not move if the next character is a word character", ->
      @testEditor.setState("[0]x   x   ")
      @emacsCursor.skipNonWordCharactersForward()
      expect(@testEditor.getState()).toEqual("[0]x   x   ")

    it "moves to the end of the buffer if all following characters are nonword characters", ->
      @testEditor.setState("[0]   ")
      @emacsCursor.skipNonWordCharactersForward()
      expect(@testEditor.getState()).toEqual("   [0]")

  describe "skipBackwardUntil", ->
    it "moves backward over the given characters", ->
      @testEditor.setState("x..x..[0]")
      @emacsCursor.skipBackwardUntil(/[^\.]/)
      expect(@testEditor.getState()).toEqual("x..x[0]..")

    it "does not move if the previous character is not in the list", ->
      @testEditor.setState("..x[0]")
      @emacsCursor.skipBackwardUntil(/[^\.]/)
      expect(@testEditor.getState()).toEqual("..x[0]")

    it "moves to the beginning of the buffer if all prior characters are in the list", ->
      @testEditor.setState("..[0]")
      @emacsCursor.skipBackwardUntil(/[^\.]/)
      expect(@testEditor.getState()).toEqual("[0]..")

  describe "skipForwardUntil", ->
    it "moves forward over the given characters", ->
      @testEditor.setState("[0]..x..x")
      @emacsCursor.skipForwardUntil(/[^\.]/)
      expect(@testEditor.getState()).toEqual("..[0]x..x")

    it "does not move if the next character is not in the list", ->
      @testEditor.setState("[0]x..")
      @emacsCursor.skipForwardUntil(/[^\.]/)
      expect(@testEditor.getState()).toEqual("[0]x..")

    it "moves to the end of the buffer if all following characters are in the list", ->
      @testEditor.setState("[0]..")
      @emacsCursor.skipForwardUntil(/[^\.]/)
      expect(@testEditor.getState()).toEqual("..[0]")

  describe "nextCharacter", ->
    it "returns the line separator if at the end of a line", ->
      @testEditor.setState("ab[0]\ncd")
      expect(@emacsCursor.nextCharacter()).toEqual('\n')

    it "return null if at the end of the buffer", ->
      @testEditor.setState("ab[0]")
      expect(@emacsCursor.nextCharacter()).toBe(null)

    it "returns the character to the right of the cursor otherwise", ->
      @testEditor.setState("a[0]b\ncd")
      expect(@emacsCursor.nextCharacter()).toEqual('b')

  describe "previousCharacter", ->
    it "returns the line separator if at the end of a line", ->
      @testEditor.setState("ab[0]\ncd")
      expect(@emacsCursor.nextCharacter()).toEqual('\n')

    it "return null if at the end of the buffer", ->
      @testEditor.setState("ab[0]")
      expect(@emacsCursor.nextCharacter()).toBe(null)

    it "returns the character to the right of the cursor otherwise", ->
      @testEditor.setState("a[0]b\ncd")
      expect(@emacsCursor.nextCharacter()).toEqual('b')

  describe "skipSexpForward", ->
    it "skips over the current symbol when inside one", ->
      @testEditor.setState("a[0]bc de")
      @emacsCursor.skipSexpForward()
      expect(@testEditor.getState()).toEqual("abc[0] de")

    it "includes all symbol characters in the symbol", ->
      @testEditor.setState("a[0]b_1c de")
      @emacsCursor.skipSexpForward()
      expect(@testEditor.getState()).toEqual("ab_1c[0] de")

    it "moves over any non-sexp chars before the symbol", ->
      @testEditor.setState("[0] .-! ab")
      @emacsCursor.skipSexpForward()
      expect(@testEditor.getState()).toEqual(" .-! ab[0]")

    it "moves to the end of the buffer if there is nothing after the symbol", ->
      @testEditor.setState("a[0]bc")
      @emacsCursor.skipSexpForward()
      expect(@testEditor.getState()).toEqual("abc[0]")

    it "skips over balanced parentheses if before an open parenthesis", ->
      @testEditor.setState("a[0](b)c")
      @emacsCursor.skipSexpForward()
      expect(@testEditor.getState()).toEqual("a(b)[0]c")

    it "moves over any non-sexp chars before the opening parenthesis", ->
      @testEditor.setState("[0] .-! (x)")
      @emacsCursor.skipSexpForward()
      expect(@testEditor.getState()).toEqual(" .-! (x)[0]")

    it "is not tricked by nested parentheses", ->
      @testEditor.setState("a[0]((b c)(\n))d")
      @emacsCursor.skipSexpForward()
      expect(@testEditor.getState()).toEqual("a((b c)(\n))[0]d")

    it "is not tricked by backslash-escaped parentheses", ->
      @testEditor.setState("a[0](b\\)c)d")
      @emacsCursor.skipSexpForward()
      expect(@testEditor.getState()).toEqual("a(b\\)c)[0]d")

    it "is not tricked by unmatched parentheses", ->
      @testEditor.setState("a[0](b]c)d")
      @emacsCursor.skipSexpForward()
      expect(@testEditor.getState()).toEqual("a(b]c)[0]d")

    it "skips over balanced quotes (assuming it starts outside the quotes)", ->
      @testEditor.setState('a[0]"b c"d')
      @emacsCursor.skipSexpForward()
      expect(@testEditor.getState()).toEqual('a"b c"[0]d')

    it "moves over any non-sexp chars before the opening quote", ->
      @testEditor.setState("[0] .-! 'x'")
      @emacsCursor.skipSexpForward()
      expect(@testEditor.getState()).toEqual(" .-! 'x'[0]")

    it "is not tricked by nested quotes of another type", ->
      @testEditor.setState("a[0]'b\"c'd")
      @emacsCursor.skipSexpForward()
      expect(@testEditor.getState()).toEqual("a'b\"c'[0]d")

    it "does not move if it can't find a matching parenthesis", ->
      @testEditor.setState("a[0](b")
      @emacsCursor.skipSexpForward()
      expect(@testEditor.getState()).toEqual("a[0](b")

    it "does not move if at the end of the buffer", ->
      @testEditor.setState("a[0]")
      @emacsCursor.skipSexpForward()
      expect(@testEditor.getState()).toEqual("a[0]")

    it "does not move if before a closing parenthesis", ->
      @testEditor.setState("(a [0]) b")
      @emacsCursor.skipSexpForward()
      expect(@testEditor.getState()).toEqual("(a [0]) b")

  describe "skipSexpBackward", ->
    it "skips over the current symbol when inside one", ->
      @testEditor.setState("ab cd[0]e")
      @emacsCursor.skipSexpBackward()
      expect(@testEditor.getState()).toEqual("ab [0]cde")

    it "includes all symbol characters in the symbol", ->
      @testEditor.setState("ab c_1d[0]e")
      @emacsCursor.skipSexpBackward()
      expect(@testEditor.getState()).toEqual("ab [0]c_1de")

    it "moves over any non-sexp chars after the symbol", ->
      @testEditor.setState("ab .-! [0]")
      @emacsCursor.skipSexpBackward()
      expect(@testEditor.getState()).toEqual("[0]ab .-! ")

    it "moves to the beginning of the buffer if there is nothing before the symbol", ->
      @testEditor.setState("ab[0]c")
      @emacsCursor.skipSexpBackward()
      expect(@testEditor.getState()).toEqual("[0]abc")

    it "skips over balanced parentheses if before an open parenthesis", ->
      @testEditor.setState("a(b)[0]c")
      @emacsCursor.skipSexpBackward()
      expect(@testEditor.getState()).toEqual("a[0](b)c")

    it "moves over any non-sexp chars after the closing parenthesis", ->
      @testEditor.setState("(x) .-! [0]")
      @emacsCursor.skipSexpBackward()
      expect(@testEditor.getState()).toEqual("[0](x) .-! ")

    it "is not tricked by nested parentheses", ->
      @testEditor.setState("a((b c)(\n))[0]d")
      @emacsCursor.skipSexpBackward()
      expect(@testEditor.getState()).toEqual("a[0]((b c)(\n))d")

    it "is not tricked by backslash-escaped parentheses", ->
      @testEditor.setState("a(b\\)c)[0]d")
      @emacsCursor.skipSexpBackward()
      expect(@testEditor.getState()).toEqual("a[0](b\\)c)d")

    it "is not tricked by unmatched parentheses", ->
      @testEditor.setState("a(b[c)[0]d")
      @emacsCursor.skipSexpBackward()
      expect(@testEditor.getState()).toEqual("a[0](b[c)d")

    it "skips over balanced quotes (assuming it starts outside the quotes)", ->
      @testEditor.setState('a"b c"[0]d')
      @emacsCursor.skipSexpBackward()
      expect(@testEditor.getState()).toEqual('a[0]"b c"d')

    it "moves over any non-sexp chars after the closing quote", ->
      @testEditor.setState("'x' .-! [0]")
      @emacsCursor.skipSexpBackward()
      expect(@testEditor.getState()).toEqual("[0]'x' .-! ")

    it "is not tricked by nested quotes of another type", ->
      @testEditor.setState("a'b\"c'[0]d")
      @emacsCursor.skipSexpBackward()
      expect(@testEditor.getState()).toEqual("a[0]'b\"c'd")

    it "does not move if it can't find a matching parenthesis", ->
      @testEditor.setState("a)[0]b")
      @emacsCursor.skipSexpBackward()
      expect(@testEditor.getState()).toEqual("a)[0]b")

    it "does not move if at the beginning of the buffer", ->
      @testEditor.setState("[0]a")
      @emacsCursor.skipSexpBackward()
      expect(@testEditor.getState()).toEqual("[0]a")

    it "does not move if after an opening parenthesis", ->
      @testEditor.setState("a ([0] b)")
      @emacsCursor.skipSexpBackward()
      expect(@testEditor.getState()).toEqual("a ([0] b)")

  describe "skipListForward", ->
    it "skips over the next list ahead", ->
      @testEditor.setState("a[0]b (c d) e")
      @emacsCursor.skipListForward()
      expect(@testEditor.getState()).toEqual("ab (c d)[0] e")

    it "does not move if there is no complete list ahead", ->
      @testEditor.setState("a[0] (b")
      @emacsCursor.skipListForward()
      expect(@testEditor.getState()).toEqual("a[0] (b")

    it "does not move if at the end of the buffer", ->
      @testEditor.setState("a[0]")
      @emacsCursor.skipListForward()
      expect(@testEditor.getState()).toEqual("a[0]")

  describe "skipListBackward", ->
    it "skips over the previous list", ->
      @testEditor.setState("a (b c) d[0]e")
      @emacsCursor.skipListBackward()
      expect(@testEditor.getState()).toEqual("a [0](b c) de")

    it "does not move if there is no previous complete list", ->
      @testEditor.setState("a) [0]b")
      @emacsCursor.skipListBackward()
      expect(@testEditor.getState()).toEqual("a) [0]b")

    it "does not move if at the beginning of the buffer", ->
      @testEditor.setState("[0]a")
      @emacsCursor.skipListBackward()
      expect(@testEditor.getState()).toEqual("[0]a")

  describe "markSexp", ->
    it "selects the next sexp if the selection is not active", ->
      @testEditor.setState("a[0] (b c) d")
      @emacsCursor.markSexp()
      expect(@testEditor.getState()).toEqual("a[0] (b c)(0) d")

    it "extends the selection over the next sexp if the selection is active", ->
      @testEditor.setState("a[0] (b c)(0) (d e) f")
      @emacsCursor.markSexp()
      expect(@testEditor.getState()).toEqual("a[0] (b c) (d e)(0) f")

    it "extends to the end of the buffer if there is no following sexp", ->
      @testEditor.setState("a[0] (b c)(0) ")
      @emacsCursor.markSexp()
      expect(@testEditor.getState()).toEqual("a[0] (b c) (0)")

    it "does nothing if the selection is extended to the end of the buffer", ->
      @testEditor.setState("a[0] (b c)(0)")
      @emacsCursor.markSexp()
      expect(@testEditor.getState()).toEqual("a[0] (b c)(0)")
