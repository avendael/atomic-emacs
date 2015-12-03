{AtomicEmacs} = require '../lib/atomic-emacs'
Mark = require '../lib/mark'
EditorState = require './editor-state'

describe "AtomicEmacs", ->
  beforeEach ->
    waitsForPromise =>
      atom.workspace.open().then (editor) =>
        @editor = editor
        @event = target: => {getModel: => @editor}
        @atomicEmacs = new AtomicEmacs()
        @atomicEmacs.editor = (_) => @editor

  describe "atomic-emacs:upcase-word-or-region", ->
    describe "when there is no selection", ->
      it "upcases the word after each cursor (if any)", ->
        EditorState.set(@editor, "[0]Aa bb\ncc[1] dd ee[2]\nff [3]")
        @atomicEmacs.upcaseWordOrRegion(@event)
        expect(EditorState.get(@editor)).toEqual("AA[0] bb\ncc DD[1] ee\nFF[2] [3]")

      it "merges any cursors that coincide", ->
        EditorState.set(@editor, "[0]aa[1]")
        @atomicEmacs.upcaseWordOrRegion(@event)
        expect(EditorState.get(@editor)).toEqual("AA[0]")

    describe "when there are selections", ->
      it "upcases each word in each selection", ->
        EditorState.set(@editor, "aa (0)bb cc[0] dd\nee f[1]ffgg(1)g")
        @atomicEmacs.upcaseWordOrRegion(@event)
        expect(EditorState.get(@editor)).toEqual("aa (0)BB CC[0] dd\nee f[1]FFGG(1)g")

  describe "atomic-emacs:downcase-word-or-region", ->
    describe "when there is no selection", ->
      it "downcases the word after each cursor (if any)", ->
        EditorState.set(@editor, "[0]aA BB\nCC[1] DD EE[2]\nFF [3]")
        @atomicEmacs.downcaseWordOrRegion(@event)
        expect(EditorState.get(@editor)).toEqual("aa[0] BB\nCC dd[1] EE\nff[2] [3]")

      it "merges any cursors that coincide", ->
        EditorState.set(@editor, "[0]AA[1]")
        @atomicEmacs.downcaseWordOrRegion(@event)
        expect(EditorState.get(@editor)).toEqual("aa[0]")

    describe "when there are selections", ->
      it "downcases each word in each selection", ->
        EditorState.set(@editor, "AA (0)BB CC[0] DD\nEE F[1]FFGG(1)G")
        @atomicEmacs.downcaseWordOrRegion(@event)
        expect(EditorState.get(@editor)).toEqual("AA (0)bb cc[0] DD\nEE F[1]ffgg(1)G")

  describe "atomic-emacs:capitalize-word-or-region", ->
    describe "when there is no selection", ->
      it "capitalizes the word after each cursor (if any)", ->
        EditorState.set(@editor, "[0]aA bb\ncc[1] dd ee[2]\nff [3]")
        @atomicEmacs.capitalizeWordOrRegion(@event)
        expect(EditorState.get(@editor)).toEqual("Aa[0] bb\ncc Dd[1] ee\nFf[2] [3]")

      it "merges any cursors that coincide", ->
        EditorState.set(@editor, "[0]aa[1]")
        @atomicEmacs.capitalizeWordOrRegion(@event)
        expect(EditorState.get(@editor)).toEqual("Aa[0]")

    describe "when there are selections", ->
      it "capitalizes each word in each selection", ->
        EditorState.set(@editor, "aa (0)bb CC[0] dd\nee f[1]FFGG(1)G")
        @atomicEmacs.capitalizeWordOrRegion(@event)
        expect(EditorState.get(@editor)).toEqual("aa (0)Bb Cc[0] dd\nee f[1]Ffgg(1)G")

  describe "atomic-emacs:transpose-chars", ->
    it "transposes the current character with the one after it", ->
      EditorState.set(@editor, "ab[0]cd")
      @atomicEmacs.transposeChars(@event)
      expect(EditorState.get(@editor)).toEqual("acb[0]d")

    it "transposes the last two characters of the line at the end of a line", ->
      EditorState.set(@editor, "abc[0]\ndef")
      @atomicEmacs.transposeChars(@event)
      expect(EditorState.get(@editor)).toEqual("acb[0]\ndef")

    it "transposes the first character with the newline at the start of a line", ->
      EditorState.set(@editor, "abc\n[0]def")
      @atomicEmacs.transposeChars(@event)
      expect(EditorState.get(@editor)).toEqual("abcd\n[0]ef")

    it "does nothing at the beginning of the buffer", ->
      EditorState.set(@editor, "[0]abcd")
      @atomicEmacs.transposeChars(@event)
      expect(EditorState.get(@editor)).toEqual("[0]abcd")

    it "transposes the last two characters at the end of the buffer", ->
      EditorState.set(@editor, "abcd[0]")
      @atomicEmacs.transposeChars(@event)
      expect(EditorState.get(@editor)).toEqual("abdc[0]")

  describe "atomic-emacs:transpose-words", ->
    it "transposes the current word with the one after it", ->
      EditorState.set(@editor, "aaa b[0]bb .\tccc ddd")
      @atomicEmacs.transposeWords(@event)
      expect(EditorState.get(@editor)).toEqual("aaa ccc .\tbbb[0] ddd")

    it "transposes the previous and next words if at the end of a word", ->
      EditorState.set(@editor, "aaa bbb[0] .\tccc ddd")
      @atomicEmacs.transposeWords(@event)
      expect(EditorState.get(@editor)).toEqual("aaa ccc .\tbbb[0] ddd")

    it "transposes the previous and next words if at the beginning of a word", ->
      EditorState.set(@editor, "aaa bbb .\t[0]ccc ddd")
      @atomicEmacs.transposeWords(@event)
      expect(EditorState.get(@editor)).toEqual("aaa ccc .\tbbb[0] ddd")

    it "transposes the previous and next words if in between words", ->
      EditorState.set(@editor, "aaa bbb .[0]\tccc ddd")
      @atomicEmacs.transposeWords(@event)
      expect(EditorState.get(@editor)).toEqual("aaa ccc .\tbbb[0] ddd")

    it "moves to the start of the last word if in the last word", ->
      # Emacs leaves point at the start of the word, but that seems unintuitive.
      EditorState.set(@editor, "aaa bbb .\tcc[0]c ")
      @atomicEmacs.transposeWords(@event)
      expect(EditorState.get(@editor)).toEqual("aaa bbb .\tccc[0] ")

    it "transposes the last two words if at the start of the last word", ->
      EditorState.set(@editor, "aaa bbb .\t[0]ccc")
      @atomicEmacs.transposeWords(@event)
      expect(EditorState.get(@editor)).toEqual("aaa ccc .\tbbb[0]")

    it "transposes the first two words if at the start of the buffer", ->
      EditorState.set(@editor, "[0]aaa .\tbbb ccc")
      @atomicEmacs.transposeWords(@event)
      expect(EditorState.get(@editor)).toEqual("bbb .\taaa[0] ccc")

    it "moves to the start of the word if it's the only word in the buffer", ->
      # Emacs leaves point at the start of the word, but that seems unintuitive.
      EditorState.set(@editor, " \taaa [0]\t")
      @atomicEmacs.transposeWords(@event)
      expect(EditorState.get(@editor)).toEqual(" \taaa[0] \t")

  describe "atomic-emacs:transpose-lines", ->
    it "transposes this line with the previous one, and moves to the next line", ->
      EditorState.set(@editor, "aaa\nb[0]bb\nccc\n")
      @atomicEmacs.transposeLines(@event)
      expect(EditorState.get(@editor)).toEqual("bbb\naaa\n[0]ccc\n")

    it "pretends it's on the second line if it's on the first", ->
      EditorState.set(@editor, "a[0]aa\nbbb\nccc\n")
      @atomicEmacs.transposeLines(@event)
      expect(EditorState.get(@editor)).toEqual("bbb\naaa\n[0]ccc\n")

    it "creates a newline at end of file if necessary", ->
      EditorState.set(@editor, "aaa\nb[0]bb")
      @atomicEmacs.transposeLines(@event)
      expect(EditorState.get(@editor)).toEqual("bbb\naaa\n[0]")

    it "still transposes if at the end of the buffer after a trailing newline", ->
      EditorState.set(@editor, "aaa\nbbb\n[0]")
      @atomicEmacs.transposeLines(@event)
      expect(EditorState.get(@editor)).toEqual("aaa\n\nbbb\n[0]")

    it "inserts a blank line at the top if there's only one line with a trailing newline", ->
      EditorState.set(@editor, "a[0]aa\n")
      @atomicEmacs.transposeLines(@event)
      expect(EditorState.get(@editor)).toEqual("\naaa\n[0]")

    it "inserts a blank line at the top if there's only one line with no trailing newline", ->
      EditorState.set(@editor, "a[0]aa")
      @atomicEmacs.transposeLines(@event)
      expect(EditorState.get(@editor)).toEqual("\naaa\n[0]")

  describe "atomic-emacs:delete-horizontal-space", ->
    it "deletes all horizontal space around each cursor", ->
      EditorState.set(@editor, "a [0]\tb c [1]\td")
      @atomicEmacs.deleteHorizontalSpace(@event)
      expect(EditorState.get(@editor)).toEqual("a[0]b c[1]d")

    it "deletes all horizontal space to the beginning of the buffer if in leading space", ->
      EditorState.set(@editor, " [0]\ta")
      @atomicEmacs.deleteHorizontalSpace(@event)
      expect(EditorState.get(@editor)).toEqual("[0]a")

    it "deletes all horizontal space to the end of the buffer if in trailing space", ->
      EditorState.set(@editor, "a [0]\t")
      @atomicEmacs.deleteHorizontalSpace(@event)
      expect(EditorState.get(@editor)).toEqual("a[0]")

    it "deletes all text if the buffer only contains horizontal spaces", ->
      EditorState.set(@editor, " [0]\t")
      @atomicEmacs.deleteHorizontalSpace(@event)
      expect(EditorState.get(@editor)).toEqual("[0]")

    it "does not modify the buffer if there is no horizontal space around the cursor", ->
      EditorState.set(@editor, "a[0]b")
      @atomicEmacs.deleteHorizontalSpace(@event)
      expect(EditorState.get(@editor)).toEqual("a[0]b")

  describe "atomic-emacs:kill-word", ->
    it "deletes from the cursor to the end of the word if inside a word", ->
      EditorState.set(@editor, "aaa b[0]bb ccc")
      @atomicEmacs.killWord(@event)
      expect(EditorState.get(@editor)).toEqual("aaa b[0] ccc")

    it "deletes the word in front of the cursor if at the beginning of a word", ->
      EditorState.set(@editor, "aaa [0]bbb ccc")
      @atomicEmacs.killWord(@event)
      expect(EditorState.get(@editor)).toEqual("aaa [0] ccc")

    it "deletes the next word if at the end of a word", ->
      EditorState.set(@editor, "aaa[0] bbb ccc")
      @atomicEmacs.killWord(@event)
      expect(EditorState.get(@editor)).toEqual("aaa[0] ccc")

    it "deletes the next word if between words", ->
      EditorState.set(@editor, "aaa [0] bbb ccc")
      @atomicEmacs.killWord(@event)
      expect(EditorState.get(@editor)).toEqual("aaa [0] ccc")

    it "does nothing if at the end of the buffer", ->
      EditorState.set(@editor, "aaa bbb ccc[0]")
      @atomicEmacs.killWord(@event)
      expect(EditorState.get(@editor)).toEqual("aaa bbb ccc[0]")

    it "deletes the trailing space in front of the cursor if at the end of the buffer", ->
      EditorState.set(@editor, "aaa bbb ccc [0] ")
      @atomicEmacs.killWord(@event)
      expect(EditorState.get(@editor)).toEqual("aaa bbb ccc [0]")

    it "deletes any selected text", ->
      EditorState.set(@editor, "aaa b(0)b[0]b ccc")
      @atomicEmacs.killWord(@event)
      expect(EditorState.get(@editor)).toEqual("aaa b[0]b ccc")

    it "operates on multiple cursors", ->
      EditorState.set(@editor, "aaa b[0]bb c[1]cc ddd")
      @atomicEmacs.killWord(@event)
      expect(EditorState.get(@editor)).toEqual("aaa b[0] c[1] ddd")

  describe "atomic-emacs:backward-kill-word", ->
    it "deletes from the cursor to the beginning of the word if inside a word", ->
      EditorState.set(@editor, "aaa bb[0]b ccc")
      @atomicEmacs.backwardKillWord(@event)
      expect(EditorState.get(@editor)).toEqual("aaa [0]b ccc")

    it "deletes the word behind the cursor if at the end of a word", ->
      EditorState.set(@editor, "aaa bbb[0] ccc")
      @atomicEmacs.backwardKillWord(@event)
      expect(EditorState.get(@editor)).toEqual("aaa [0] ccc")

    it "deletes the previous word if at the beginning of a word", ->
      EditorState.set(@editor, "aaa bbb [0]ccc")
      @atomicEmacs.backwardKillWord(@event)
      expect(EditorState.get(@editor)).toEqual("aaa [0]ccc")

    it "deletes the previous word if between words", ->
      EditorState.set(@editor, "aaa bbb [0] ccc")
      @atomicEmacs.backwardKillWord(@event)
      expect(EditorState.get(@editor)).toEqual("aaa [0] ccc")

    it "does nothing if at the beginning of the buffer", ->
      EditorState.set(@editor, "[0]aaa bbb ccc")
      @atomicEmacs.backwardKillWord(@event)
      expect(EditorState.get(@editor)).toEqual("[0]aaa bbb ccc")

    it "deletes the leading space behind the cursor if at the beginning of the buffer", ->
      EditorState.set(@editor, " [0] aaa bbb ccc")
      @atomicEmacs.backwardKillWord(@event)
      expect(EditorState.get(@editor)).toEqual("[0] aaa bbb ccc")

    it "deletes any selected text", ->
      EditorState.set(@editor, "aaa b(0)b[0]b ccc")
      @atomicEmacs.backwardKillWord(@event)
      expect(EditorState.get(@editor)).toEqual("aaa b[0]b ccc")

    it "operates on multiple cursors", ->
      EditorState.set(@editor, "aaa bb[0]b cc[1]c ddd")
      @atomicEmacs.backwardKillWord(@event)
      expect(EditorState.get(@editor)).toEqual("aaa [0]b [1]c ddd")

  describe "atomic-emacs:just-one-space", ->
    it "replaces all horizontal space around each cursor with one space", ->
      EditorState.set(@editor, "a [0]\tb c [1]\td")
      @atomicEmacs.justOneSpace(@event)
      expect(EditorState.get(@editor)).toEqual("a [0]b c [1]d")

    it "replaces all horizontal space at the beginning of the buffer with one space if in leading space", ->
      EditorState.set(@editor, " [0]\ta")
      @atomicEmacs.justOneSpace(@event)
      expect(EditorState.get(@editor)).toEqual(" [0]a")

    it "replaces all horizontal space at the end of the buffer with one space if in trailing space", ->
      EditorState.set(@editor, "a [0]\t")
      @atomicEmacs.justOneSpace(@event)
      expect(EditorState.get(@editor)).toEqual("a [0]")

    it "replaces all text with one space if the buffer only contains horizontal spaces", ->
      EditorState.set(@editor, " [0]\t")
      @atomicEmacs.justOneSpace(@event)
      expect(EditorState.get(@editor)).toEqual(" [0]")

    it "does not modify the buffer if there is already exactly one space at around the cursor", ->
      EditorState.set(@editor, "a[0]b")
      @atomicEmacs.justOneSpace(@event)
      expect(EditorState.get(@editor)).toEqual("a [0]b")

  describe "atomic_emacs:set-mark", ->
    it "sets and activates the mark of all cursors", ->
      EditorState.set(@editor, "[0].[1]")
      [cursor0, cursor1] = @editor.getCursors()
      @atomicEmacs.setMark(@event)

      expect(Mark.for(cursor0).isActive()).toBe(true)
      point = Mark.for(cursor0).getBufferPosition()
      expect([point.row, point.column]).toEqual([0, 0])

      expect(Mark.for(cursor1).isActive()).toBe(true)
      point = Mark.for(cursor1).getBufferPosition()
      expect([point.row, point.column]).toEqual([0, 1])

  describe "atomic-emacs:keyboard-quit", ->
    it "deactivates all marks", ->
      EditorState.set(@editor, "[0].[1]")
      [mark0, mark1] = (Mark.for(c) for c in @editor.getCursors())
      m.activate() for m in [mark0, mark1]
      @atomicEmacs.keyboardQuit(@event)
      expect(mark0.isActive()).toBe(false)

  describe "atomic-emacs:backward-char", ->
    it "moves the cursor backward one character", ->
      EditorState.set(@editor, "x[0]")
      @atomicEmacs.backwardChar(@event)
      expect(EditorState.get(@editor)).toEqual("[0]x")

    it "does nothing at the start of the buffer", ->
      EditorState.set(@editor, "[0]x")
      @atomicEmacs.backwardChar(@event)
      expect(EditorState.get(@editor)).toEqual("[0]x")

    it "extends an active selection if the mark is set", ->
      EditorState.set(@editor, "ab[0]c")
      @atomicEmacs.setMark(@event)
      @atomicEmacs.backwardChar(@event)
      expect(EditorState.get(@editor)).toEqual("a[0]b(0)c")
      @atomicEmacs.backwardChar(@event)
      expect(EditorState.get(@editor)).toEqual("[0]ab(0)c")

    it "aborts key binding if flag is set", ->
      atom.config.set('atomic-emacs.useNativeNavigationKeys', true)
      EditorState.set(@editor, "x[0]")
      event = jasmine.createSpyObj 'event', ['abortKeyBinding']
      @atomicEmacs.backwardChar(event)

      expect(event.abortKeyBinding).toHaveBeenCalled()
      expect(EditorState.get(@editor)).toEqual("x[0]")

  describe "atomic-emacs:close-other-panes", ->
    it "should close all inactive panes", ->
      pane1 = atom.workspace.getActivePane()
      pane2 = pane1.splitRight()
      pane3 = pane2.splitRight()
      pane2.activate()
      @atomicEmacs.closeOtherPanes()
      expect(pane1.isDestroyed()).toEqual(true)
      expect(pane2.isDestroyed()).toEqual(false)
      expect(pane3.isDestroyed()).toEqual(true)

  describe "atomic-emacs:forward-char", ->
    it "moves the cursor forward one character", ->
      EditorState.set(@editor, "[0]x")
      @atomicEmacs.forwardChar(@event)
      expect(EditorState.get(@editor)).toEqual("x[0]")

    it "does nothing at the end of the buffer", ->
      EditorState.set(@editor, "x[0]")
      @atomicEmacs.forwardChar(@event)
      expect(EditorState.get(@editor)).toEqual("x[0]")

    it "extends an active selection if the mark is set", ->
      EditorState.set(@editor, "a[0]bc")
      @atomicEmacs.setMark(@event)
      @atomicEmacs.forwardChar(@event)
      expect(EditorState.get(@editor)).toEqual("a(0)b[0]c")
      @atomicEmacs.forwardChar(@event)
      expect(EditorState.get(@editor)).toEqual("a(0)bc[0]")

    it "aborts key binding if flag is set", ->
      atom.config.set('atomic-emacs.useNativeNavigationKeys', true)
      EditorState.set(@editor, "x[0]")
      event = jasmine.createSpyObj 'event', ['abortKeyBinding']
      @atomicEmacs.forwardChar(event)

      expect(event.abortKeyBinding).toHaveBeenCalled()
      expect(EditorState.get(@editor)).toEqual("x[0]")

  describe "atomic-emacs:backward-word", ->
    it "moves all cursors to the beginning of the current word if in a word", ->
      EditorState.set(@editor, "aa b[0]b c[1]c")
      @atomicEmacs.backwardWord(@event)
      expect(EditorState.get(@editor)).toEqual("aa [0]bb [1]cc")

    it "moves to the beginning of the previous word if between words", ->
      EditorState.set(@editor, "aa bb [0] cc")
      @atomicEmacs.backwardWord(@event)
      expect(EditorState.get(@editor)).toEqual("aa [0]bb  cc")

    it "moves to the beginning of the previous word if at the start of a word", ->
      EditorState.set(@editor, "aa bb [0]cc")
      @atomicEmacs.backwardWord(@event)
      expect(EditorState.get(@editor)).toEqual("aa [0]bb cc")

    it "moves to the beginning of the buffer if at the start of the first word", ->
      EditorState.set(@editor, " [0]aa bb")
      @atomicEmacs.backwardWord(@event)
      expect(EditorState.get(@editor)).toEqual("[0] aa bb")

    it "moves to the beginning of the buffer if before the start of the first word", ->
      EditorState.set(@editor, " [0] aa bb")
      @atomicEmacs.backwardWord(@event)
      expect(EditorState.get(@editor)).toEqual("[0]  aa bb")

  describe "atomic-emacs:forward-word", ->
    it "moves all cursors to the end of the current word if in a word", ->
      EditorState.set(@editor, "a[0]a b[1]b cc")
      @atomicEmacs.forwardWord(@event)
      expect(EditorState.get(@editor)).toEqual("aa[0] bb[1] cc")

    it "moves to the end of the next word if between words", ->
      EditorState.set(@editor, "aa [0] bb cc")
      @atomicEmacs.forwardWord(@event)
      expect(EditorState.get(@editor)).toEqual("aa  bb[0] cc")

    it "moves to the end of the next word if at the end of a word", ->
      EditorState.set(@editor, "aa[0] bb cc")
      @atomicEmacs.forwardWord(@event)
      expect(EditorState.get(@editor)).toEqual("aa bb[0] cc")

    it "moves to the end of the buffer if at the end of the last word", ->
      EditorState.set(@editor, "aa bb[0] ")
      @atomicEmacs.forwardWord(@event)
      expect(EditorState.get(@editor)).toEqual("aa bb [0]")

    it "moves to the end of the buffer if past the end of the last word", ->
      EditorState.set(@editor, "aa bb [0] ")
      @atomicEmacs.forwardWord(@event)
      expect(EditorState.get(@editor)).toEqual("aa bb  [0]")

  describe "atomic-emacs:forward-sexp", ->
    it "moves all cursors forward one symbolic expression", ->
      EditorState.set(@editor, "[0]  aa\n[1](bb cc)\n")
      @atomicEmacs.forwardSexp(@event)
      expect(EditorState.get(@editor)).toEqual("  aa[0]\n(bb cc)[1]\n")

    it "merges cursors that coincide", ->
      EditorState.set(@editor, "[0] [1]aa")
      @atomicEmacs.forwardSexp(@event)
      expect(EditorState.get(@editor)).toEqual(" aa[0]")

  describe "atomic-emacs:backward-sexp", ->
    it "moves all cursors backward one symbolic expression", ->
      EditorState.set(@editor, "aa [0]\n(bb cc)[1]\n")
      @atomicEmacs.backwardSexp(@event)
      expect(EditorState.get(@editor)).toEqual("[0]aa \n[1](bb cc)\n")

    it "merges cursors that coincide", ->
      EditorState.set(@editor, "aa[0] [1]")
      @atomicEmacs.backwardSexp(@event)
      expect(EditorState.get(@editor)).toEqual("[0]aa ")

  describe "atomic-emacs:back-to-indentation", ->
    it "moves cursors forward to the first character if in leading space", ->
      EditorState.set(@editor, "[0]  aa\n [1] bb\n")
      @atomicEmacs.backToIndentation(@event)
      expect(EditorState.get(@editor)).toEqual("  [0]aa\n  [1]bb\n")

    it "moves cursors back to the first character if past it", ->
      EditorState.set(@editor, "  a[0]a\n  bb[1]\n")
      @atomicEmacs.backToIndentation(@event)
      expect(EditorState.get(@editor)).toEqual("  [0]aa\n  [1]bb\n")

    it "leaves cursors alone if already there", ->
      EditorState.set(@editor, "  [0]aa\n[1]  bb\n")
      @atomicEmacs.backToIndentation(@event)
      expect(EditorState.get(@editor)).toEqual("  [0]aa\n  [1]bb\n")

    it "moves cursors to the end of their lines if they only contain spaces", ->
      EditorState.set(@editor, " [0] \n  [1]\n")
      @atomicEmacs.backToIndentation(@event)
      expect(EditorState.get(@editor)).toEqual("  [0]\n  [1]\n")

    it "merges cursors after moving", ->
      EditorState.set(@editor, "  a[0]a[1]\n")
      @atomicEmacs.backToIndentation(@event)
      expect(EditorState.get(@editor)).toEqual("  [0]aa\n")

  describe "atomic-emacs:previous-line", ->
    it "moves the cursor up one line", ->
      EditorState.set(@editor, "ab\na[0]b\n")
      @atomicEmacs.previousLine(@event)
      expect(EditorState.get(@editor)).toEqual("a[0]b\nab\n")

    it "goes to the start of the line if already at the top of the buffer", ->
      EditorState.set(@editor, "x[0]")
      @atomicEmacs.previousLine(@event)
      expect(EditorState.get(@editor)).toEqual("[0]x")

    it "extends an active selection if the mark is set", ->
      EditorState.set(@editor, "ab\nab\na[0]b\n")
      @atomicEmacs.setMark(@event)
      @atomicEmacs.previousLine(@event)
      expect(EditorState.get(@editor)).toEqual("ab\na[0]b\na(0)b\n")
      @atomicEmacs.previousLine(@event)
      expect(EditorState.get(@editor)).toEqual("a[0]b\nab\na(0)b\n")

    it "aborts key binding if flag is set", ->
      atom.config.set('atomic-emacs.useNativeNavigationKeys', true)
      EditorState.set(@editor, "x[0]")
      event = jasmine.createSpyObj 'event', ['abortKeyBinding']
      @atomicEmacs.previousLine(event)

      expect(event.abortKeyBinding).toHaveBeenCalled()
      expect(EditorState.get(@editor)).toEqual("x[0]")

  describe "atomic-emacs:next-line", ->
    it "moves the cursor down one line", ->
      EditorState.set(@editor, "a[0]b\nab\n")
      @atomicEmacs.nextLine(@event)
      expect(EditorState.get(@editor)).toEqual("ab\na[0]b\n")

    it "goes to the end of the line if already at the bottom of the buffer", ->
      EditorState.set(@editor, "[0]x")
      @atomicEmacs.nextLine(@event)
      expect(EditorState.get(@editor)).toEqual("x[0]")

    it "extends an active selection if the mark is set", ->
      EditorState.set(@editor, "a[0]b\nab\nab\n")
      @atomicEmacs.setMark(@event)
      @atomicEmacs.nextLine(@event)
      expect(EditorState.get(@editor)).toEqual("a(0)b\na[0]b\nab\n")
      @atomicEmacs.nextLine(@event)
      expect(EditorState.get(@editor)).toEqual("a(0)b\nab\na[0]b\n")

    it "aborts key binding if flag is set", ->
      atom.config.set('atomic-emacs.useNativeNavigationKeys', true)
      EditorState.set(@editor, "a[0]b\nab\nab\n")
      event = jasmine.createSpyObj 'event', ['abortKeyBinding']
      @atomicEmacs.nextLine(event)

      expect(event.abortKeyBinding).toHaveBeenCalled()
      expect(EditorState.get(@editor)).toEqual("a[0]b\nab\nab\n")

  describe "atomic-emacs:backward-paragraph", ->
    it "moves back to an empty line", ->
      EditorState.set(@editor, "a\n\nb\nc\n[0]d")
      @atomicEmacs.backwardParagraph(@event)
      expect(EditorState.get(@editor)).toEqual("a\n[0]\nb\nc\nd")

    it "moves back to the beginning of a line with only whitespace", ->
      EditorState.set(@editor, "a\n \t\nb\nc\nd[0]")
      @atomicEmacs.backwardParagraph(@event)
      expect(EditorState.get(@editor)).toEqual("a\n[0] \t\nb\nc\nd")

    it "stops if it reaches the beginning of the buffer", ->
      EditorState.set(@editor, "a\nb\n[0]c")
      @atomicEmacs.backwardParagraph(@event)
      expect(EditorState.get(@editor)).toEqual("[0]a\nb\nc")

    it "does not stop on its own line", ->
      EditorState.set(@editor, "a\n\nb\nc\n[0]\n")
      @atomicEmacs.backwardParagraph(@event)
      expect(EditorState.get(@editor)).toEqual("a\n[0]\nb\nc\n\n")

    it "moves to the beginning of the line if on the first line", ->
      EditorState.set(@editor, "a[0]a\n")
      @atomicEmacs.backwardParagraph(@event)
      expect(EditorState.get(@editor)).toEqual("[0]aa\n")

    it "moves all cursors, and merges cursors that coincide", ->
      EditorState.set(@editor, "a\n\nb\nc\n[0]\nd\n[1]e\n[2]")
      @atomicEmacs.backwardParagraph(@event)
      expect(EditorState.get(@editor)).toEqual("a\n[0]\nb\nc\n[1]\nd\ne\n")

  describe "atomic-emacs:forward-paragraph", ->
    it "moves forward to an empty line", ->
      EditorState.set(@editor, "a\n[0]b\nc\n\nd")
      @atomicEmacs.forwardParagraph(@event)
      expect(EditorState.get(@editor)).toEqual("a\nb\nc\n[0]\nd")

    it "moves forward to the beginning of a line with only whitespace", ->
      EditorState.set(@editor, "a\n[0]b\nc\n \t\nd")
      @atomicEmacs.forwardParagraph(@event)
      expect(EditorState.get(@editor)).toEqual("a\nb\nc\n[0] \t\nd")

    it "stops if it reaches the end of the buffer", ->
      EditorState.set(@editor, "a\n[0]b\nc")
      @atomicEmacs.forwardParagraph(@event)
      expect(EditorState.get(@editor)).toEqual("a\nb\nc[0]")

    it "does not stop on its own line", ->
      EditorState.set(@editor, "a\n[0]\nb\nc\n\nd")
      @atomicEmacs.forwardParagraph(@event)
      expect(EditorState.get(@editor)).toEqual("a\n\nb\nc\n[0]\nd")

    it "moves to the end of the line if on the last line", ->
      EditorState.set(@editor, "a[0]a")
      @atomicEmacs.forwardParagraph(@event)
      expect(EditorState.get(@editor)).toEqual("aa[0]")

    it "moves all cursors, and merges cursors that coincide", ->
      EditorState.set(@editor, "a\n[0]\nb\nc\n[1]\nd\n[2]e\n")
      @atomicEmacs.forwardParagraph(@event)
      expect(EditorState.get(@editor)).toEqual("a\n\nb\nc\n[0]\nd\ne\n[1]")

  describe "atomic-emacs:exchange-point-and-mark", ->
    it "exchanges all cursors with their marks", ->
      EditorState.set(@editor, "[0]..[1].")
      for cursor in @editor.getCursors()
        Mark.for(cursor)
        cursor.moveRight()
      @atomicEmacs.exchangePointAndMark(@event)
      expect(EditorState.get(@editor)).toEqual("[0].(0).[1].(1)")

  describe "atomic-emacs:delete-indentation", ->
    it "joins the current line with the previous one if at the start of the line", ->
      EditorState.set(@editor, "aa \n[0] bb\ncc")
      @atomicEmacs.deleteIndentation()
      expect(EditorState.get(@editor)).toEqual("aa[0] bb\ncc")

    it "does exactly the same thing if at the end of the line", ->
      EditorState.set(@editor, "aa \n bb[0]\ncc")
      @atomicEmacs.deleteIndentation()
      expect(EditorState.get(@editor)).toEqual("aa[0] bb\ncc")

    it "joins the two empty lines if they're both blank", ->
      EditorState.set(@editor, "aa\n\n[0]\nbb")
      @atomicEmacs.deleteIndentation()
      expect(EditorState.get(@editor)).toEqual("aa\n[0]\nbb")
