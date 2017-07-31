{EmacsCursor, EmacsEditor, KillRing, State, activate, deactivate} =
  require '../lib/atomic-emacs'

TestEditor = require './test-editor'

describe "AtomicEmacs", ->
  beforeEach activate
  afterEach deactivate

  beforeEach ->
    waitsForPromise =>
      atom.workspace.open().then (@editor) =>
        atom.config.set 'atomic-emacs.killToClipboard', true
        @emacsEditor = new EmacsEditor(@editor)
        @testEditor = new TestEditor(@editor)
        @editorView = atom.views.getView(@editor)
        @getKillRing = (i) => EmacsCursor.for(@editor.getCursors()[i]).getLocalKillRing()

  describe "atomic-emacs:backward-char", ->
    it "moves the cursor backward one character", ->
      @testEditor.setState("x[0]")
      atom.commands.dispatch @editorView, 'atomic-emacs:backward-char'
      expect(@testEditor.getState()).toEqual("[0]x")

    it "does nothing at the start of the buffer", ->
      @testEditor.setState("[0]x")
      atom.commands.dispatch @editorView, 'atomic-emacs:backward-char'
      expect(@testEditor.getState()).toEqual("[0]x")

    it "extends an active selection if the mark is set", ->
      @testEditor.setState("ab[0]c")
      atom.commands.dispatch @editorView, 'atomic-emacs:set-mark'
      atom.commands.dispatch @editorView, 'atomic-emacs:backward-char'
      expect(@testEditor.getState()).toEqual("a[0]b(0)c")
      atom.commands.dispatch @editorView, 'atomic-emacs:backward-char'
      expect(@testEditor.getState()).toEqual("[0]ab(0)c")

    it "does not deactivate an active selection if at BOB", ->
      @testEditor.setState("a[0]bc")
      atom.commands.dispatch @editorView, 'atomic-emacs:set-mark'
      atom.commands.dispatch @editorView, 'atomic-emacs:backward-char'
      atom.commands.dispatch @editorView, 'atomic-emacs:backward-char'
      expect(@testEditor.getState()).toEqual("[0]a(0)bc")

  describe "atomic-emacs:forward-char", ->
    it "moves the cursor forward one character", ->
      @testEditor.setState("[0]x")
      atom.commands.dispatch @editorView, 'atomic-emacs:forward-char'
      expect(@testEditor.getState()).toEqual("x[0]")

    it "does nothing at the end of the buffer", ->
      @testEditor.setState("x[0]")
      atom.commands.dispatch @editorView, 'atomic-emacs:forward-char'
      expect(@testEditor.getState()).toEqual("x[0]")

    it "extends an active selection if the mark is set", ->
      @testEditor.setState("a[0]bc")
      atom.commands.dispatch @editorView, 'atomic-emacs:set-mark'
      atom.commands.dispatch @editorView, 'atomic-emacs:forward-char'
      expect(@testEditor.getState()).toEqual("a(0)b[0]c")
      atom.commands.dispatch @editorView, 'atomic-emacs:forward-char'
      expect(@testEditor.getState()).toEqual("a(0)bc[0]")

    it "does not deactivate an active selection if at EOB", ->
      @testEditor.setState("ab[0]c")
      atom.commands.dispatch @editorView, 'atomic-emacs:set-mark'
      atom.commands.dispatch @editorView, 'atomic-emacs:forward-char'
      atom.commands.dispatch @editorView, 'atomic-emacs:forward-char'
      expect(@testEditor.getState()).toEqual("ab(0)c[0]")

  describe "atomic-emacs:backward-word", ->
    it "moves all cursors to the beginning of the current word if in a word", ->
      @testEditor.setState("aa b[0]b c[1]c")
      atom.commands.dispatch @editorView, 'atomic-emacs:backward-word'
      expect(@testEditor.getState()).toEqual("aa [0]bb [1]cc")

    it "moves to the beginning of the previous word if between words", ->
      @testEditor.setState("aa bb [0] cc")
      atom.commands.dispatch @editorView, 'atomic-emacs:backward-word'
      expect(@testEditor.getState()).toEqual("aa [0]bb  cc")

    it "moves to the beginning of the previous word if at the start of a word", ->
      @testEditor.setState("aa bb [0]cc")
      atom.commands.dispatch @editorView, 'atomic-emacs:backward-word'
      expect(@testEditor.getState()).toEqual("aa [0]bb cc")

    it "moves to the beginning of the buffer if at the start of the first word", ->
      @testEditor.setState(" [0]aa bb")
      atom.commands.dispatch @editorView, 'atomic-emacs:backward-word'
      expect(@testEditor.getState()).toEqual("[0] aa bb")

    it "moves to the beginning of the buffer if before the start of the first word", ->
      @testEditor.setState(" [0] aa bb")
      atom.commands.dispatch @editorView, 'atomic-emacs:backward-word'
      expect(@testEditor.getState()).toEqual("[0]  aa bb")

  describe "atomic-emacs:forward-word", ->
    it "moves all cursors to the end of the current word if in a word", ->
      @testEditor.setState("a[0]a b[1]b cc")
      atom.commands.dispatch @editorView, 'atomic-emacs:forward-word'
      expect(@testEditor.getState()).toEqual("aa[0] bb[1] cc")

    it "moves to the end of the next word if between words", ->
      @testEditor.setState("aa [0] bb cc")
      atom.commands.dispatch @editorView, 'atomic-emacs:forward-word'
      expect(@testEditor.getState()).toEqual("aa  bb[0] cc")

    it "moves to the end of the next word if at the end of a word", ->
      @testEditor.setState("aa[0] bb cc")
      atom.commands.dispatch @editorView, 'atomic-emacs:forward-word'
      expect(@testEditor.getState()).toEqual("aa bb[0] cc")

    it "moves to the end of the buffer if at the end of the last word", ->
      @testEditor.setState("aa bb[0] ")
      atom.commands.dispatch @editorView, 'atomic-emacs:forward-word'
      expect(@testEditor.getState()).toEqual("aa bb [0]")

    it "moves to the end of the buffer if past the end of the last word", ->
      @testEditor.setState("aa bb [0] ")
      atom.commands.dispatch @editorView, 'atomic-emacs:forward-word'
      expect(@testEditor.getState()).toEqual("aa bb  [0]")

  describe "atomic-emacs:backward-sexp", ->
    it "moves all cursors backward one symbolic expression", ->
      @testEditor.setState("(aa bb)\naa [0]\n(bb cc)[1]\n")
      atom.commands.dispatch @editorView, 'atomic-emacs:backward-sexp'
      expect(@testEditor.getState()).toEqual("(aa bb)\n[0]aa \n[1](bb cc)\n")

    it "merges cursors that coincide", ->
      @testEditor.setState("aa[0] [1]")
      atom.commands.dispatch @editorView, 'atomic-emacs:backward-sexp'
      expect(@testEditor.getState()).toEqual("[0]aa ")

  describe "atomic-emacs:forward-sexp", ->
    it "moves all cursors forward one symbolic expression", ->
      @testEditor.setState("[0]aa\n[1](bb cc)\n")
      atom.commands.dispatch @editorView, 'atomic-emacs:forward-sexp'
      expect(@testEditor.getState()).toEqual("aa[0]\n(bb cc)[1]\n")

    it "merges cursors that coincide", ->
      @testEditor.setState("[0] [1]aa")
      atom.commands.dispatch @editorView, 'atomic-emacs:forward-sexp'
      expect(@testEditor.getState()).toEqual(" aa[0]")

  describe "atomic-emacs:backward-list", ->
    it "moves all cursors backward one list expression", ->
      @testEditor.setState("(aa {bb})\naa [0]\n(bb cc)[1]\n")
      atom.commands.dispatch @editorView, 'atomic-emacs:backward-list'
      expect(@testEditor.getState()).toEqual("[0](aa {bb})\naa \n[1](bb cc)\n")

    it "merges cursors that coincide", ->
      @testEditor.setState("(a)[0] [1]")
      atom.commands.dispatch @editorView, 'atomic-emacs:backward-list'
      expect(@testEditor.getState()).toEqual("[0](a) ")

  describe "atomic-emacs:forward-list", ->
    it "moves all cursors forward one list expression", ->
      @testEditor.setState("[0]a{a}\n[1](bb cc)\n")
      atom.commands.dispatch @editorView, 'atomic-emacs:forward-list'
      expect(@testEditor.getState()).toEqual("a{a}[0]\n(bb cc)[1]\n")

    it "merges cursors that coincide", ->
      @testEditor.setState("[0] (a)[1]")
      atom.commands.dispatch @editorView, 'atomic-emacs:forward-list'
      expect(@testEditor.getState()).toEqual(" (a)[0]")

  describe "atomic-emacs:previous-line", ->
    it "moves the cursor up one line", ->
      @testEditor.setState("ab\na[0]b\n")
      atom.commands.dispatch @editorView, 'atomic-emacs:previous-line'
      expect(@testEditor.getState()).toEqual("a[0]b\nab\n")

    it "goes to the start of the line if already at the top of the buffer", ->
      @testEditor.setState("x[0]")
      atom.commands.dispatch @editorView, 'atomic-emacs:previous-line'
      expect(@testEditor.getState()).toEqual("[0]x")

    it "extends an active selection if the mark is set", ->
      @testEditor.setState("ab\nab\na[0]b\n")
      atom.commands.dispatch @editorView, 'atomic-emacs:set-mark'
      atom.commands.dispatch @editorView, 'atomic-emacs:previous-line'
      expect(@testEditor.getState()).toEqual("ab\na[0]b\na(0)b\n")
      atom.commands.dispatch @editorView, 'atomic-emacs:previous-line'
      expect(@testEditor.getState()).toEqual("a[0]b\nab\na(0)b\n")

    it "does not deactivate an active selection if at BOB", ->
      @testEditor.setState("ab\na[0]b\n")
      atom.commands.dispatch @editorView, 'atomic-emacs:set-mark'
      atom.commands.dispatch @editorView, 'atomic-emacs:previous-line'
      atom.commands.dispatch @editorView, 'atomic-emacs:previous-line'
      expect(@testEditor.getState()).toEqual("[0]ab\na(0)b\n")

  describe "atomic-emacs:next-line", ->
    it "moves the cursor down one line", ->
      @testEditor.setState("a[0]b\nab\n")
      atom.commands.dispatch @editorView, 'atomic-emacs:next-line'
      expect(@testEditor.getState()).toEqual("ab\na[0]b\n")

    it "goes to the end of the line if already at the bottom of the buffer", ->
      @testEditor.setState("[0]x")
      atom.commands.dispatch @editorView, 'atomic-emacs:next-line'
      expect(@testEditor.getState()).toEqual("x[0]")

    it "extends an active selection if the mark is set", ->
      @testEditor.setState("a[0]b\nab\nab\n")
      atom.commands.dispatch @editorView, 'atomic-emacs:set-mark'
      atom.commands.dispatch @editorView, 'atomic-emacs:next-line'
      expect(@testEditor.getState()).toEqual("a(0)b\na[0]b\nab\n")
      atom.commands.dispatch @editorView, 'atomic-emacs:next-line'
      expect(@testEditor.getState()).toEqual("a(0)b\nab\na[0]b\n")

    it "does not deactivate an active selection if at EOB", ->
      @testEditor.setState("a[0]b\nab\n")
      atom.commands.dispatch @editorView, 'atomic-emacs:set-mark'
      atom.commands.dispatch @editorView, 'atomic-emacs:next-line'
      atom.commands.dispatch @editorView, 'atomic-emacs:next-line'
      expect(@testEditor.getState()).toEqual("a(0)b\nab\n[0]")

  describe "atomic-emacs:backward-paragraph", ->
    it "moves back to an empty line", ->
      @testEditor.setState("a\n\nb\nc\n[0]d")
      atom.commands.dispatch @editorView, 'atomic-emacs:backward-paragraph'
      expect(@testEditor.getState()).toEqual("a\n[0]\nb\nc\nd")

    it "moves back to the beginning of a line with only whitespace", ->
      @testEditor.setState("a\n \t\nb\nc\nd[0]")
      atom.commands.dispatch @editorView, 'atomic-emacs:backward-paragraph'
      expect(@testEditor.getState()).toEqual("a\n[0] \t\nb\nc\nd")

    it "stops if it reaches the beginning of the buffer", ->
      @testEditor.setState("a\nb\n[0]c")
      atom.commands.dispatch @editorView, 'atomic-emacs:backward-paragraph'
      expect(@testEditor.getState()).toEqual("[0]a\nb\nc")

    it "does not stop on its own line", ->
      @testEditor.setState("a\n\nb\nc\n[0]\n")
      atom.commands.dispatch @editorView, 'atomic-emacs:backward-paragraph'
      expect(@testEditor.getState()).toEqual("a\n[0]\nb\nc\n\n")

    it "moves to the beginning of the line if on the first line", ->
      @testEditor.setState("a[0]a\n")
      atom.commands.dispatch @editorView, 'atomic-emacs:backward-paragraph'
      expect(@testEditor.getState()).toEqual("[0]aa\n")

    it "moves all cursors, and merges cursors that coincide", ->
      @testEditor.setState("a\n\nb\nc\n[0]\nd\n[1]e\n[2]")
      atom.commands.dispatch @editorView, 'atomic-emacs:backward-paragraph'
      expect(@testEditor.getState()).toEqual("a\n[0]\nb\nc\n[1]\nd\ne\n")

  describe "atomic-emacs:forward-paragraph", ->
    it "moves forward to an empty line", ->
      @testEditor.setState("a\n[0]b\nc\n\nd")
      atom.commands.dispatch @editorView, 'atomic-emacs:forward-paragraph'
      expect(@testEditor.getState()).toEqual("a\nb\nc\n[0]\nd")

    it "moves forward to the beginning of a line with only whitespace", ->
      @testEditor.setState("a\n[0]b\nc\n \t\nd")
      atom.commands.dispatch @editorView, 'atomic-emacs:forward-paragraph'
      expect(@testEditor.getState()).toEqual("a\nb\nc\n[0] \t\nd")

    it "stops if it reaches the end of the buffer", ->
      @testEditor.setState("a\n[0]b\nc")
      atom.commands.dispatch @editorView, 'atomic-emacs:forward-paragraph'
      expect(@testEditor.getState()).toEqual("a\nb\nc[0]")

    it "does not stop on its own line", ->
      @testEditor.setState("a\n[0]\nb\nc\n\nd")
      atom.commands.dispatch @editorView, 'atomic-emacs:forward-paragraph'
      expect(@testEditor.getState()).toEqual("a\n\nb\nc\n[0]\nd")

    it "moves to the end of the line if on the last line", ->
      @testEditor.setState("a[0]a")
      atom.commands.dispatch @editorView, 'atomic-emacs:forward-paragraph'
      expect(@testEditor.getState()).toEqual("aa[0]")

    it "moves all cursors, and merges cursors that coincide", ->
      @testEditor.setState("a\n[0]\nb\nc\n[1]\nd\n[2]e\n")
      atom.commands.dispatch @editorView, 'atomic-emacs:forward-paragraph'
      expect(@testEditor.getState()).toEqual("a\n\nb\nc\n[0]\nd\ne\n[1]")

  describe "atomic-emacs:back-to-indentation", ->
    it "moves cursors forward to the first character if in leading space", ->
      @testEditor.setState("[0]  aa\n [1] bb\n")
      atom.commands.dispatch @editorView, 'atomic-emacs:back-to-indentation'
      expect(@testEditor.getState()).toEqual("  [0]aa\n  [1]bb\n")

    it "moves cursors back to the first character if past it", ->
      @testEditor.setState("  a[0]a\n  bb[1]\n")
      atom.commands.dispatch @editorView, 'atomic-emacs:back-to-indentation'
      expect(@testEditor.getState()).toEqual("  [0]aa\n  [1]bb\n")

    it "leaves cursors alone if already there", ->
      @testEditor.setState("  [0]aa\n[1]  bb\n")
      atom.commands.dispatch @editorView, 'atomic-emacs:back-to-indentation'
      expect(@testEditor.getState()).toEqual("  [0]aa\n  [1]bb\n")

    it "moves cursors to the end of their lines if they only contain spaces", ->
      @testEditor.setState(" [0] \n  [1]\n")
      atom.commands.dispatch @editorView, 'atomic-emacs:back-to-indentation'
      expect(@testEditor.getState()).toEqual("  [0]\n  [1]\n")

    it "merges cursors after moving", ->
      @testEditor.setState("  a[0]a[1]\n")
      atom.commands.dispatch @editorView, 'atomic-emacs:back-to-indentation'
      expect(@testEditor.getState()).toEqual("  [0]aa\n")

  describe "atomic-emacs:backward-kill-word", ->
    it "deletes from the cursor to the beginning of the word if inside a word", ->
      @testEditor.setState("aaa bb[0]b ccc")
      atom.commands.dispatch @editorView, 'atomic-emacs:backward-kill-word'
      expect(@testEditor.getState()).toEqual("aaa [0]b ccc")

    it "deletes the word behind the cursor if at the end of a word", ->
      @testEditor.setState("aaa bbb[0] ccc")
      atom.commands.dispatch @editorView, 'atomic-emacs:backward-kill-word'
      expect(@testEditor.getState()).toEqual("aaa [0] ccc")

    it "deletes the previous word if at the beginning of a word", ->
      @testEditor.setState("aaa bbb [0]ccc")
      atom.commands.dispatch @editorView, 'atomic-emacs:backward-kill-word'
      expect(@testEditor.getState()).toEqual("aaa [0]ccc")

    it "deletes the previous word if between words", ->
      @testEditor.setState("aaa bbb [0] ccc")
      atom.commands.dispatch @editorView, 'atomic-emacs:backward-kill-word'
      expect(@testEditor.getState()).toEqual("aaa [0] ccc")

    it "does nothing if at the beginning of the buffer", ->
      @testEditor.setState("[0]aaa bbb ccc")
      atom.commands.dispatch @editorView, 'atomic-emacs:backward-kill-word'
      expect(@testEditor.getState()).toEqual("[0]aaa bbb ccc")

    it "deletes the leading space behind the cursor if at the beginning of the buffer", ->
      @testEditor.setState(" [0] aaa bbb ccc")
      atom.commands.dispatch @editorView, 'atomic-emacs:backward-kill-word'
      expect(@testEditor.getState()).toEqual("[0] aaa bbb ccc")

    it "deletes any selected text", ->
      @testEditor.setState("aaa b(0)b[0]b ccc")
      atom.commands.dispatch @editorView, 'atomic-emacs:backward-kill-word'
      expect(@testEditor.getState()).toEqual("aaa b[0]b ccc")

    it "operates on multiple cursors", ->
      @testEditor.setState("aaa bb[0]b cc[1]c ddd")
      atom.commands.dispatch @editorView, 'atomic-emacs:backward-kill-word'
      expect(@testEditor.getState()).toEqual("aaa [0]b [1]c ddd")

    describe "when there is a single cursor", ->
      beforeEach ->
        @testEditor.setState("a(0)b[0]c")

      it "kills to the global kill ring", ->
        atom.commands.dispatch @editorView, 'atomic-emacs:backward-kill-word'
        expect(KillRing.global.getEntries()).toEqual(['b'])

      it "puts the kill on the clipboard", ->
        atom.commands.dispatch @editorView, 'atomic-emacs:backward-kill-word'
        expect(atom.clipboard.read()).toEqual('b')

      describe "When atomic-emacs.killToClipboard is off", ->
        beforeEach ->
          atom.config.set 'atomic-emacs.killToClipboard', false

        it "doesn't put the kill on the clipboard", ->
          atom.commands.dispatch @editorView, 'atomic-emacs:backward-kill-word'
          expect(atom.clipboard.read()).toEqual('initial clipboard content')

    describe "when there are multiple cursors", ->
      beforeEach ->
        @testEditor.setState("a(0)b[0]c d(1)e[1]f")

      it "kills to a cursor-local kill ring", ->
        atom.commands.dispatch @editorView, 'atomic-emacs:backward-kill-word'
        expect(@getKillRing(0).getEntries()).toEqual(['b'])
        expect(@getKillRing(1).getEntries()).toEqual(['e'])

      it "puts all kills on the global kill ring & clipboard", ->
        atom.commands.dispatch @editorView, 'atomic-emacs:backward-kill-word'
        expect(KillRing.global.getEntries()).toEqual(['b\ne\n'])
        expect(atom.clipboard.read()).toEqual("b\ne\n")

      describe "When atomic-emacs.killToClipboard is off", ->
        beforeEach ->
          atom.config.set 'atomic-emacs.killToClipboard', false

        it "doesn't put the kill clipboard separated by newlines", ->
          atom.commands.dispatch @editorView, 'atomic-emacs:backward-kill-word'
          expect(atom.clipboard.read()).toEqual('initial clipboard content')

      it "merges cursors", ->
        @testEditor.setState("a[1]b[0]c")
        atom.commands.dispatch @editorView, 'atomic-emacs:backward-kill-word'
        expect(@testEditor.getState()).toEqual("[0]c")

    it "prepends to the last kill ring entry if killing", ->
      @testEditor.setState("a[0]b")
      KillRing.global.setEntries(['x'])
      State.killing = true
      atom.commands.dispatch @editorView, 'atomic-emacs:backward-kill-word'
      expect(KillRing.global.getEntries()).toEqual(['ax'])

    it "sets the killing flag", ->
      atom.commands.dispatch @editorView, 'atomic-emacs:backward-kill-word'
      expect(State.killing).toBe(true)

    it "results in combining successive kills into a single kill ring entry", ->
      @testEditor.setState("aaa bbb ccc[0]")
      atom.commands.dispatch @editorView, 'atomic-emacs:backward-kill-word'
      atom.commands.dispatch @editorView, 'atomic-emacs:backward-kill-word'
      expect(KillRing.global.getEntries()).toEqual(['bbb ccc'])

  describe "atomic-emacs:kill-word", ->
    it "deletes from the cursor to the end of the word if inside a word", ->
      @testEditor.setState("aaa b[0]bb ccc")
      atom.commands.dispatch @editorView, 'atomic-emacs:kill-word'
      expect(@testEditor.getState()).toEqual("aaa b[0] ccc")

    it "deletes the word in front of the cursor if at the beginning of a word", ->
      @testEditor.setState("aaa [0]bbb ccc")
      atom.commands.dispatch @editorView, 'atomic-emacs:kill-word'
      expect(@testEditor.getState()).toEqual("aaa [0] ccc")

    it "deletes the next word if at the end of a word", ->
      @testEditor.setState("aaa[0] bbb ccc")
      atom.commands.dispatch @editorView, 'atomic-emacs:kill-word'
      expect(@testEditor.getState()).toEqual("aaa[0] ccc")

    it "deletes the next word if between words", ->
      @testEditor.setState("aaa [0] bbb ccc")
      atom.commands.dispatch @editorView, 'atomic-emacs:kill-word'
      expect(@testEditor.getState()).toEqual("aaa [0] ccc")

    it "does nothing if at the end of the buffer", ->
      @testEditor.setState("aaa bbb ccc[0]")
      atom.commands.dispatch @editorView, 'atomic-emacs:kill-word'
      expect(@testEditor.getState()).toEqual("aaa bbb ccc[0]")

    it "deletes the trailing space in front of the cursor if at the end of the buffer", ->
      @testEditor.setState("aaa bbb ccc [0] ")
      atom.commands.dispatch @editorView, 'atomic-emacs:kill-word'
      expect(@testEditor.getState()).toEqual("aaa bbb ccc [0]")

    it "deletes any selected text", ->
      @testEditor.setState("aaa b(0)b[0]b ccc")
      atom.commands.dispatch @editorView, 'atomic-emacs:kill-word'
      expect(@testEditor.getState()).toEqual("aaa b[0]b ccc")

    it "operates on multiple cursors", ->
      @testEditor.setState("aaa b[0]bb c[1]cc ddd")
      atom.commands.dispatch @editorView, 'atomic-emacs:kill-word'
      expect(@testEditor.getState()).toEqual("aaa b[0] c[1] ddd")

    describe "when there is a single cursor", ->
      beforeEach ->
        @testEditor.setState("a[0]b(0)c")

      it "kills to the global kill ring", ->
        atom.commands.dispatch @editorView, 'atomic-emacs:kill-word'
        expect(KillRing.global.getEntries()).toEqual(['b'])

      it "puts the kill on the clipboard", ->
        atom.commands.dispatch @editorView, 'atomic-emacs:kill-word'
        expect(atom.clipboard.read()).toEqual('b')

      describe "When atomic-emacs.killToClipboard is off", ->
        beforeEach ->
          atom.config.set 'atomic-emacs.killToClipboard', false

        it "doesn't put the kill on the clipboard", ->
          atom.commands.dispatch @editorView, 'atomic-emacs:kill-word'
          expect(atom.clipboard.read()).toEqual('initial clipboard content')

    describe "when there are multiple cursors", ->
      beforeEach ->
        @testEditor.setState("a[0]b(0)c d[1]e(1)f")

      it "kills to a cursor-local kill ring", ->
        atom.commands.dispatch @editorView, 'atomic-emacs:kill-word'
        expect(@getKillRing(0).getEntries()).toEqual(['b'])
        expect(@getKillRing(1).getEntries()).toEqual(['e'])

      it "puts all kills on the global kill ring & clipboard", ->
        atom.commands.dispatch @editorView, 'atomic-emacs:kill-word'
        expect(KillRing.global.getEntries()).toEqual(['b\ne\n'])
        expect(atom.clipboard.read()).toEqual("b\ne\n")

      describe "When atomic-emacs.killToClipboard is off", ->
        beforeEach ->
          atom.config.set 'atomic-emacs.killToClipboard', false

        it "doesn't put the kill on the clipboard separated by newlines", ->
          atom.commands.dispatch @editorView, 'atomic-emacs:kill-word'
          expect(atom.clipboard.read()).toEqual('initial clipboard content')

      it "merges cursors", ->
        @testEditor.setState("a[0]b[1]c")
        atom.commands.dispatch @editorView, 'atomic-emacs:kill-word'
        expect(@testEditor.getState()).toEqual("a[0]")

    it "appends to the last kill ring entry if killing", ->
      @testEditor.setState("a[0]b")
      KillRing.global.setEntries(['x'])
      State.killing = true
      atom.commands.dispatch @editorView, 'atomic-emacs:kill-word'
      expect(KillRing.global.getEntries()).toEqual(['xb'])

    it "sets the killing flag", ->
      atom.commands.dispatch @editorView, 'atomic-emacs:kill-word'
      expect(State.killing).toBe(true)

    it "results in combining successive kills into a single kill ring entry", ->
      @testEditor.setState("[0]aaa bbb ccc")
      atom.commands.dispatch @editorView, 'atomic-emacs:kill-word'
      atom.commands.dispatch @editorView, 'atomic-emacs:kill-word'
      expect(KillRing.global.getEntries()).toEqual(['aaa bbb'])

  describe "atomic-emacs:kill-line", ->
    beforeEach ->
      atom.config.set 'atomic-emacs.killWholeLine', false

    it "deletes from the cursor to the end of the line if there is text to the right", ->
      @testEditor.setState("aaa b[0]bb\nccc")
      atom.commands.dispatch @editorView, 'atomic-emacs:kill-line'
      expect(@testEditor.getState()).toEqual("aaa b[0]\nccc")

    it "deletes the rest of this line if there is only whitespace to the right", ->
      @testEditor.setState("aaa [0] \t\n bbb")
      atom.commands.dispatch @editorView, 'atomic-emacs:kill-line'
      expect(@testEditor.getState()).toEqual("aaa [0] bbb")

    it "deletes the next newline if there is nothing to the right", ->
      @testEditor.setState("aaa [0]\n bbb")
      atom.commands.dispatch @editorView, 'atomic-emacs:kill-line'
      expect(@testEditor.getState()).toEqual("aaa [0] bbb")

    it "deletes nothing if at the end of the buffer", ->
      @testEditor.setState("aaa[0]")
      atom.commands.dispatch @editorView, 'atomic-emacs:kill-line'
      expect(@testEditor.getState()).toEqual("aaa[0]")

    it "deletes any selected text", ->
      @testEditor.setState("aaa b(0)b[0]b ccc")
      atom.commands.dispatch @editorView, 'atomic-emacs:kill-line'
      expect(@testEditor.getState()).toEqual("aaa b[0]b ccc")

    it "deletes on the head position", ->
      @testEditor.setState("aaa \n[0]bbb\nccc")
      atom.commands.dispatch @editorView, 'atomic-emacs:kill-line'
      expect(@testEditor.getState()).toEqual("aaa \n[0]\nccc")

    it "operates on multiple cursors", ->
      @testEditor.setState("aaa b[0]bb\nc[1]cc ddd")
      atom.commands.dispatch @editorView, 'atomic-emacs:kill-line'
      expect(@testEditor.getState()).toEqual("aaa b[0]\nc[1]")

  describe "atomic-emacs:kill-line when killWholeLine option is on", ->
    beforeEach ->
      atom.config.set 'atomic-emacs.killWholeLine', true

    it "deletes from the cursor to the end of the line if there is text to the right", ->
      @testEditor.setState("aaa b[0]bb\nccc")
      atom.commands.dispatch @editorView, 'atomic-emacs:kill-line'
      expect(@testEditor.getState()).toEqual("aaa b[0]\nccc")

    it "deletes the rest of this line if there is only whitespace to the right", ->
      @testEditor.setState("aaa [0] \t\n bbb")
      atom.commands.dispatch @editorView, 'atomic-emacs:kill-line'
      expect(@testEditor.getState()).toEqual("aaa [0] bbb")

    it "deletes the next newline if there is nothing to the right", ->
      @testEditor.setState("aaa [0]\n bbb")
      atom.commands.dispatch @editorView, 'atomic-emacs:kill-line'
      expect(@testEditor.getState()).toEqual("aaa [0] bbb")

    it "deletes nothing if at the end of the buffer", ->
      @testEditor.setState("aaa[0]")
      atom.commands.dispatch @editorView, 'atomic-emacs:kill-line'
      expect(@testEditor.getState()).toEqual("aaa[0]")

    it "deletes any selected text", ->
      @testEditor.setState("aaa b(0)b[0]b ccc")
      atom.commands.dispatch @editorView, 'atomic-emacs:kill-line'
      expect(@testEditor.getState()).toEqual("aaa b[0]b ccc")

    it "deletes on the head position", ->
      @testEditor.setState("aaa \n[0]bbb\nccc")
      atom.commands.dispatch @editorView, 'atomic-emacs:kill-line'
      expect(@testEditor.getState()).toEqual("aaa \n[0]ccc")

    it "operates on multiple cursors", ->
      @testEditor.setState("aaa b[0]bb\nc[1]cc ddd")
      atom.commands.dispatch @editorView, 'atomic-emacs:kill-line'
      expect(@testEditor.getState()).toEqual("aaa b[0]\nc[1]")

    describe "when there is a single cursor", ->
      beforeEach ->
        @testEditor.setState("a[0]bc")

      it "kills to the global kill ring", ->
        atom.commands.dispatch @editorView, 'atomic-emacs:kill-line'
        expect(KillRing.global.getEntries()).toEqual(['bc'])

      it "puts the kill on the clipboard", ->
        atom.commands.dispatch @editorView, 'atomic-emacs:kill-line'
        expect(atom.clipboard.read()).toEqual('bc')

      describe "When atomic-emacs.killToClipboard is off", ->
        beforeEach ->
          atom.config.set 'atomic-emacs.killToClipboard', false

        it "doesn't put the kill on the clipboard", ->
          atom.commands.dispatch @editorView, 'atomic-emacs:kill-word'
          expect(atom.clipboard.read()).toEqual('initial clipboard content')

    describe "when there are multiple cursors", ->
      beforeEach ->
        @testEditor.setState("a[0]bc\n d[1]ef")

      it "kills to a cursor-local kill ring", ->
        atom.commands.dispatch @editorView, 'atomic-emacs:kill-line'
        expect(@getKillRing(0).getEntries()).toEqual(['bc'])
        expect(@getKillRing(1).getEntries()).toEqual(['ef'])

      it "puts all kills on the global kill ring & clipboard", ->
        atom.commands.dispatch @editorView, 'atomic-emacs:kill-line'
        expect(KillRing.global.getEntries()).toEqual(['bc\nef\n'])
        expect(atom.clipboard.read()).toEqual("bc\nef\n")

      describe "When atomic-emacs.killToClipboard is off", ->
        beforeEach ->
          atom.config.set 'atomic-emacs.killToClipboard', false

        it "doesn't put the kill on the clipboard separated by newlines", ->
          atom.commands.dispatch @editorView, 'atomic-emacs:kill-line'
          expect(atom.clipboard.read()).toEqual('initial clipboard content')

      it "merges cursors", ->
        @testEditor.setState("a[0]b\n[1]c")
        atom.commands.dispatch @editorView, 'atomic-emacs:kill-line'
        atom.commands.dispatch @editorView, 'atomic-emacs:kill-line'
        expect(@testEditor.getState()).toEqual("a[0]")

    it "appends to the last kill ring entry if killing", ->
      @testEditor.setState("a[0]b")
      KillRing.global.setEntries(['x'])
      State.killing = true
      atom.commands.dispatch @editorView, 'atomic-emacs:kill-line'
      expect(KillRing.global.getEntries()).toEqual(['xb'])

    it "sets the killing flag", ->
      atom.commands.dispatch @editorView, 'atomic-emacs:kill-line'
      expect(State.killing).toBe(true)

    it "results in combining successive kills into a single kill ring entry", ->
      @testEditor.setState("aaa[0] bbb\nccc ddd")
      atom.commands.dispatch @editorView, 'atomic-emacs:kill-line'
      atom.commands.dispatch @editorView, 'atomic-emacs:kill-line'
      atom.commands.dispatch @editorView, 'atomic-emacs:kill-line'
      expect(KillRing.global.getEntries()).toEqual([" bbb\nccc ddd"])

  describe "atomic-emacs:kill-region", ->
    it "deletes the selected regions", ->
      @testEditor.setState("a(0)b[0]c d[1]e(1)f")
      atom.commands.dispatch @editorView, 'atomic-emacs:kill-region'
      expect(@testEditor.getState()).toEqual("a[0]c d[1]f")

    describe "when there is a single cursor", ->
      beforeEach ->
        @testEditor.setState("a(0)b[0]c")

      it "kills to the global kill ring", ->
        atom.commands.dispatch @editorView, 'atomic-emacs:kill-region'
        expect(KillRing.global.getEntries()).toEqual(['b'])

      it "puts the kill on the clipboard", ->
        atom.commands.dispatch @editorView, 'atomic-emacs:kill-region'
        expect(atom.clipboard.read()).toEqual('b')

      describe "When atomic-emacs.killToClipboard is off", ->
        beforeEach ->
          atom.config.set 'atomic-emacs.killToClipboard', false

        it "doesn't put the kill on the clipboard", ->
          atom.commands.dispatch @editorView, 'atomic-emacs:kill-region'
          expect(atom.clipboard.read()).toEqual('initial clipboard content')

    describe "when there are multiple cursors", ->
      beforeEach ->
        @testEditor.setState("a(0)b[0]c d[1]e(1)f")

      it "kills to a cursor-local kill ring", ->
        atom.commands.dispatch @editorView, 'atomic-emacs:kill-region'
        expect(@getKillRing(0).getEntries()).toEqual(['b'])
        expect(@getKillRing(1).getEntries()).toEqual(['e'])

      it "puts all kills on the global kill ring & clipboard", ->
        atom.commands.dispatch @editorView, 'atomic-emacs:kill-region'
        expect(KillRing.global.getEntries()).toEqual(['b\ne\n'])
        expect(atom.clipboard.read()).toEqual("b\ne\n")

      describe "When atomic-emacs.killToClipboard is off", ->
        beforeEach ->
          atom.config.set 'atomic-emacs.killToClipboard', false

        it "doesn't put the kill on the clipboard separated by newlines", ->
          atom.commands.dispatch @editorView, 'atomic-emacs:kill-region'
          expect(atom.clipboard.read()).toEqual('initial clipboard content')

      it "merges cursors", ->
        @testEditor.setState("a(0)a[0](1)b[1]b")
        atom.commands.dispatch @editorView, 'atomic-emacs:kill-region'
        expect(@testEditor.getState()).toEqual("a[0]b")

    it "pushes blanks if selections are empty", ->
      @testEditor.setState("a(0)[0]b")
      atom.commands.dispatch @editorView, 'atomic-emacs:kill-region'
      expect(@testEditor.getState()).toEqual("a[0]b")
      expect(KillRing.global.getEntries()).toEqual([''])

    it "appends to the last kill ring entry if killing", ->
      @testEditor.setState("a[0]b(0)")
      KillRing.global.setEntries(['x'])
      State.killing = true
      atom.commands.dispatch @editorView, 'atomic-emacs:kill-region'
      expect(KillRing.global.getEntries()).toEqual(['xb'])

    it "sets the killing flag", ->
      atom.commands.dispatch @editorView, 'atomic-emacs:kill-region'
      expect(State.killing).toBe(true)

    it "results in combining successive kills into a single kill ring entry", ->
      @testEditor.setState("a[0]b(0)c")
      atom.commands.dispatch @editorView, 'atomic-emacs:kill-region'
      atom.commands.dispatch @editorView, 'atomic-emacs:kill-word'
      expect(KillRing.global.getEntries()).toEqual(['bc'])

  describe "atomic-emacs:copy-region-as-kill", ->
    it "clears the selection without deleting text", ->
      @testEditor.setState("aaa b(0)b[0]b ccc")
      atom.commands.dispatch @editorView, 'atomic-emacs:copy-region-as-kill'
      expect(@testEditor.getState()).toEqual("aaa bb[0]b ccc")

    it "operates on multiple cursors", ->
      @testEditor.setState("a(0)b[0]c d[1]e(1)f")
      atom.commands.dispatch @editorView, 'atomic-emacs:copy-region-as-kill'
      expect(@testEditor.getState()).toEqual("ab[0]c d[1]ef")
      entries = (EmacsCursor.for(c).killRing().getEntries() for c in @editor.getCursors())
      expect(entries).toEqual([['b'], ['e']])

    it "pushes blanks if selections are empty", ->
      @testEditor.setState("a(0)[0]b")
      atom.commands.dispatch @editorView, 'atomic-emacs:copy-region-as-kill'
      cursor = @editor.getCursors()[0]
      expect(EmacsCursor.for(cursor).killRing().getEntries()).toEqual([''])
      expect(@testEditor.getState()).toEqual("a[0]b")

    describe "when there is a single cursor", ->
      beforeEach ->
        @testEditor.setState("a(0)b[0]c")

      it "kills to the global kill ring", ->
        atom.commands.dispatch @editorView, 'atomic-emacs:copy-region-as-kill'
        expect(KillRing.global.getEntries()).toEqual(['b'])

      it "puts the kill on the clipboard", ->
        atom.commands.dispatch @editorView, 'atomic-emacs:copy-region-as-kill'
        expect(atom.clipboard.read()).toEqual('b')

      describe "When atomic-emacs.killToClipboard is off", ->
        beforeEach ->
          atom.config.set 'atomic-emacs.killToClipboard', false

        it "doesn't put the kill on the clipboard", ->
          atom.commands.dispatch @editorView, 'atomic-emacs:copy-region-as-kill'
          expect(atom.clipboard.read()).toEqual('initial clipboard content')

    describe "when there are multiple cursors", ->
      beforeEach ->
        @testEditor.setState("a(0)b[0]c d[1]e(1)f")

      it "kills to a cursor-local kill ring", ->
        atom.commands.dispatch @editorView, 'atomic-emacs:copy-region-as-kill'
        expect(@getKillRing(0).getEntries()).toEqual(['b'])
        expect(@getKillRing(1).getEntries()).toEqual(['e'])

      it "puts all kills on the global kill ring & clipboard", ->
        atom.commands.dispatch @editorView, 'atomic-emacs:copy-region-as-kill'
        expect(KillRing.global.getEntries()).toEqual(['b\ne\n'])
        expect(atom.clipboard.read()).toEqual("b\ne\n")

      describe "When atomic-emacs.killToClipboard is off", ->
        beforeEach ->
          atom.config.set 'atomic-emacs.killToClipboard', false

        it "doesn't put the kill on the clipboard separated by newlines", ->
          atom.commands.dispatch @editorView, 'atomic-emacs:copy-region-as-kill'
          expect(atom.clipboard.read()).toEqual('initial clipboard content')

    it "appends to the last kill ring entry if killing", ->
      @testEditor.setState("a[0]b(0)")
      KillRing.global.setEntries(['x'])
      State.killing = true
      atom.commands.dispatch @editorView, 'atomic-emacs:copy-region-as-kill'
      expect(KillRing.global.getEntries()).toEqual(['xb'])

    it "does not set the killing flag", ->
      @testEditor.setState("a[0]b(0)")
      atom.commands.dispatch @editorView, 'atomic-emacs:copy-region-as-kill'
      expect(State.killing).toBe(false)

    it "does not result in combining successive kills into a single kill ring entry", ->
      @testEditor.setState("a[0]b(0)c")
      atom.commands.dispatch @editorView, 'atomic-emacs:copy-region-as-kill'
      atom.commands.dispatch @editorView, 'atomic-emacs:kill-word'
      expect(KillRing.global.getEntries()).toEqual(['b', 'bc'])

  describe "atomic-emacs:append-next-kill", ->
    it "sets the killing flag", ->
      @testEditor.setState("a[0]b")
      atom.commands.dispatch @editorView, 'atomic-emacs:append-next-kill'
      expect(State.killing).toBe(true)

    it "results in combining a subsequent kill with the current entry", ->
      @testEditor.setState("a[0]b(0)")
      KillRing.global.setEntries(['x'])
      atom.commands.dispatch @editorView, 'atomic-emacs:append-next-kill'
      atom.commands.dispatch @editorView, 'atomic-emacs:kill-region'
      expect(KillRing.global.getEntries()).toEqual(['xb'])

  describe "atomic-emacs:yank", ->
    describe "when there is a single cursor", ->
      beforeEach ->
        @testEditor.setState("x[0]y")

      it "does nothing if the global kill ring is empty", ->
        atom.commands.dispatch @editorView, 'atomic-emacs:yank'
        expect(@testEditor.getState()).toEqual("x[0]y")

      it "inserts the current entry of the global kill ring", ->
        KillRing.global.setEntries(['a', 'b', 'c']).rotate(-1)
        atom.commands.dispatch @editorView, 'atomic-emacs:yank'
        expect(@testEditor.getState()).toEqual("xb[0]y")

      it "inserts the entry again if a successive yank is performed", ->
        KillRing.global.setEntries(['a', 'b', 'c']).rotate(-1)
        atom.commands.dispatch @editorView, 'atomic-emacs:yank'
        atom.commands.dispatch @editorView, 'atomic-emacs:yank'
        expect(@testEditor.getState()).toEqual("xbb[0]y")

    describe "when there are multiple cursors", ->
      beforeEach ->
        @testEditor.setState("x[0]y\nz[1]w")

      it "does nothing if local kill rings are empty", ->
        atom.commands.dispatch @editorView, 'atomic-emacs:yank'
        expect(@testEditor.getState()).toEqual("x[0]y\nz[1]w")

      it "inserts the current entry of each cursor's kill ring", ->
        @getKillRing(0).setEntries(['a', 'b', 'c']).rotate(-1)
        @getKillRing(1).setEntries(['d', 'e', 'f']).rotate(-1)
        atom.commands.dispatch @editorView, 'atomic-emacs:yank'
        expect(@testEditor.getState()).toEqual("xb[0]y\nze[1]w")

      it "inserts the entry again if a successive yank is performed", ->
        @getKillRing(0).setEntries(['a', 'b', 'c']).rotate(-1)
        @getKillRing(1).setEntries(['d', 'e', 'f']).rotate(-1)
        atom.commands.dispatch @editorView, 'atomic-emacs:yank'
        atom.commands.dispatch @editorView, 'atomic-emacs:yank'
        expect(@testEditor.getState()).toEqual("xbb[0]y\nzee[1]w")

    describe "when switching to multiple cursors a second time", ->
      it "does not yank from the old cursor-local kill ring", ->
        @testEditor.setState("[0]x\n[1]y")
        KillRing.global.setEntries(['.'])
        @getKillRing(0).setEntries(['0'])
        @getKillRing(1).setEntries(['1'])

        @editor.getCursors()[1].destroy()
        @editor.addCursor(@editor.markBufferPosition([1, 0]))

        atom.commands.dispatch @editorView, 'atomic-emacs:yank'
        expect(@testEditor.getState()).toEqual(".[0]x\n.[1]y")

    describe "when there is a selection present", ->
      it "replaces the selected text and moves to the end of it", ->
        @testEditor.setState("(0)a[0]b")
        KillRing.global.setEntries(['c'])
        atom.commands.dispatch @editorView, 'atomic-emacs:yank'
        expect(@testEditor.getState()).toEqual("c[0]b")

      it "does the same if the selection is reversed", ->
        @testEditor.setState("[0]a(0)b")
        KillRing.global.setEntries(['c'])
        atom.commands.dispatch @editorView, 'atomic-emacs:yank'
        expect(@testEditor.getState()).toEqual("c[0]b")

  describe "atomic-emacs:yank-pop", ->
    describe "when performed immediately after a yank", ->
      beforeEach ->
        @testEditor.setState("[0]")

      it "replaces the yanked text with successive kill ring entries", ->
        KillRing.global.setEntries(['ab', 'cd', 'ef'])
        atom.commands.dispatch @editorView, 'atomic-emacs:yank'

        expect(@testEditor.getState()).toEqual("ef[0]")
        atom.commands.dispatch @editorView, 'atomic-emacs:yank-pop'
        expect(@testEditor.getState()).toEqual("cd[0]")
        atom.commands.dispatch @editorView, 'atomic-emacs:yank-pop'
        expect(@testEditor.getState()).toEqual("ab[0]")

      it "does nothing if the kill ring is empty", ->
        atom.commands.dispatch @editorView, 'atomic-emacs:yank'

        atom.commands.dispatch @editorView, 'atomic-emacs:yank-pop'
        expect(@testEditor.getState()).toEqual("[0]")

    describe "when not performed immediately after a yank", ->
      beforeEach ->
        @testEditor.setState("[0]")
        expect(@testEditor.getState()).toEqual("[0]")

      it "does nothing if the kill ring is empty", ->
        atom.commands.dispatch @editorView, 'atomic-emacs:yank-pop'
        expect(@testEditor.getState()).toEqual("[0]")

      it "does nothing if the kill ring is not empty", ->
        KillRing.global.setEntries(['ab', 'cd', 'ef'])
        atom.commands.dispatch @editorView, 'atomic-emacs:yank-pop'
        expect(@testEditor.getState()).toEqual("[0]")

    describe "when there are multiple cursors", ->
      beforeEach ->
        @testEditor.setState("x[0]y z[1]w")

      it "uses cursor-local kill rings", ->
        @getKillRing(0).setEntries(['ab', 'cd', 'ef'])
        @getKillRing(1).setEntries(['gh', 'ij', 'kl'])
        atom.commands.dispatch @editorView, 'atomic-emacs:yank'
        expect(@testEditor.getState()).toEqual("xef[0]y zkl[1]w")

        atom.commands.dispatch @editorView, 'atomic-emacs:yank-pop'
        expect(@testEditor.getState()).toEqual("xcd[0]y zij[1]w")
        atom.commands.dispatch @editorView, 'atomic-emacs:yank-pop'
        expect(@testEditor.getState()).toEqual("xab[0]y zgh[1]w")

      it "does nothing if the cursor-local kill rings are empty", ->
        atom.commands.dispatch @editorView, 'atomic-emacs:yank'
        expect(@testEditor.getState()).toEqual("x[0]y z[1]w")

        atom.commands.dispatch @editorView, 'atomic-emacs:yank-pop'
        expect(@testEditor.getState()).toEqual("x[0]y z[1]w")

    it "rotates a replaced selection", ->
      @testEditor.setState("(0)a[0]")
      KillRing.global.setEntries(['b', 'c', 'd']).rotate(-1)
      atom.commands.dispatch @editorView, 'atomic-emacs:yank'
      atom.commands.dispatch @editorView, 'atomic-emacs:yank-pop'
      expect(@testEditor.getState()).toEqual("b[0]")

  describe "atomic-emacs:yank-shift", ->
    describe "when performed immediately after a yank", ->
      beforeEach ->
        @testEditor.setState("[0]")

      it "replaces the yanked text with successive kill ring entries", ->
        KillRing.global.setEntries(['ab', 'cd', 'ef']).rotate(-2)
        atom.commands.dispatch @editorView, 'atomic-emacs:yank'

        expect(@testEditor.getState()).toEqual("ab[0]")
        atom.commands.dispatch @editorView, 'atomic-emacs:yank-shift'
        expect(@testEditor.getState()).toEqual("cd[0]")
        atom.commands.dispatch @editorView, 'atomic-emacs:yank-shift'
        expect(@testEditor.getState()).toEqual("ef[0]")

      it "does nothing if the kill ring is empty", ->
        atom.commands.dispatch @editorView, 'atomic-emacs:yank'

        atom.commands.dispatch @editorView, 'atomic-emacs:yank-shift'
        expect(@testEditor.getState()).toEqual("[0]")

    describe "when not performed immediately after a yank", ->
      beforeEach ->
        @testEditor.setState("[0]")
        expect(@testEditor.getState()).toEqual("[0]")

      it "does nothing if the kill ring is empty", ->
        atom.commands.dispatch @editorView, 'atomic-emacs:yank-shift'
        expect(@testEditor.getState()).toEqual("[0]")

      it "does nothing if the kill ring is not empty", ->
        KillRing.global.setEntries(['ab', 'cd', 'ef']).rotate(-2)
        atom.commands.dispatch @editorView, 'atomic-emacs:yank-shift'
        expect(@testEditor.getState()).toEqual("[0]")

    describe "when there are multiple cursors", ->
      beforeEach ->
        @testEditor.setState("x[0]y z[1]w")

      it "uses cursor-local kill rings", ->
        @getKillRing(0).setEntries(['ab', 'cd', 'ef']).rotate(-2)
        @getKillRing(1).setEntries(['gh', 'ij', 'kl']).rotate(-2)
        atom.commands.dispatch @editorView, 'atomic-emacs:yank'
        expect(@testEditor.getState()).toEqual("xab[0]y zgh[1]w")

        atom.commands.dispatch @editorView, 'atomic-emacs:yank-shift'
        expect(@testEditor.getState()).toEqual("xcd[0]y zij[1]w")
        atom.commands.dispatch @editorView, 'atomic-emacs:yank-shift'
        expect(@testEditor.getState()).toEqual("xef[0]y zkl[1]w")

      it "does nothing if the cursor-local kill rings are empty", ->
        atom.commands.dispatch @editorView, 'atomic-emacs:yank'
        expect(@testEditor.getState()).toEqual("x[0]y z[1]w")

        atom.commands.dispatch @editorView, 'atomic-emacs:yank-shift'
        expect(@testEditor.getState()).toEqual("x[0]y z[1]w")

    it "rotates a replaced selection", ->
      @testEditor.setState("(0)a[0]")
      KillRing.global.setEntries(['b', 'c', 'd']).rotate(-1)
      atom.commands.dispatch @editorView, 'atomic-emacs:yank'
      atom.commands.dispatch @editorView, 'atomic-emacs:yank-shift'
      expect(@testEditor.getState()).toEqual("d[0]")

  describe "atomic-emacs:delete-horizontal-space", ->
    it "deletes horizontal space around all cursors", ->
      @testEditor.setState("a [0] b\n\t[1]\t")
      atom.commands.dispatch @editorView, 'atomic-emacs:delete-horizontal-space'
      expect(@testEditor.getState()).toEqual("a[0]b\n[1]")

    it "merges cursors that coincide", ->
      @testEditor.setState("[0] [0]")
      atom.commands.dispatch @editorView, 'atomic-emacs:delete-horizontal-space'
      expect(@testEditor.getState()).toEqual("[0]")

    it "creates a single history entry for multiple changes", ->
      @testEditor.setState("a [0] b\nc\t[1]\td")
      atom.commands.dispatch @editorView, 'atomic-emacs:delete-horizontal-space'
      atom.commands.dispatch @editorView, 'core:undo'
      expect(@testEditor.getState()).toEqual("a [0] b\nc\t[1]\td")

    it "deletes all horizontal space to the beginning of the buffer if in leading space", ->
      @testEditor.setState(" [0]\ta")
      atom.commands.dispatch @editorView, 'atomic-emacs:delete-horizontal-space'
      expect(@testEditor.getState()).toEqual("[0]a")

    it "deletes all horizontal space to the end of the buffer if in trailing space", ->
      @testEditor.setState("a [0]\t")
      atom.commands.dispatch @editorView, 'atomic-emacs:delete-horizontal-space'
      expect(@testEditor.getState()).toEqual("a[0]")

    it "deletes all text if the buffer only contains horizontal spaces", ->
      @testEditor.setState(" [0]\t")
      atom.commands.dispatch @editorView, 'atomic-emacs:delete-horizontal-space'
      expect(@testEditor.getState()).toEqual("[0]")

    it "does not modify the buffer if there is no horizontal space around the cursor", ->
      @testEditor.setState("a[0]b")
      atom.commands.dispatch @editorView, 'atomic-emacs:delete-horizontal-space'
      expect(@testEditor.getState()).toEqual("a[0]b")

  describe "atomic-emacs:delete-indentation", ->
    it "joins each cursor's current line with the previous one if at the start of the line", ->
      @testEditor.setState("a \n [0]b\nc \n [1]d")
      atom.commands.dispatch @editorView, 'atomic-emacs:delete-indentation'
      expect(@testEditor.getState()).toEqual("a[0] b\nc[1] d")

    it "does the same thing at the end of the line", ->
      @testEditor.setState("aa \n bb[0]\ncc")
      atom.commands.dispatch @editorView, 'atomic-emacs:delete-indentation'
      expect(@testEditor.getState()).toEqual("aa[0] bb\ncc")

    it "joins the two empty lines if they're both blank", ->
      @testEditor.setState("aa\n\n[0]\nbb")
      atom.commands.dispatch @editorView, 'atomic-emacs:delete-indentation'
      expect(@testEditor.getState()).toEqual("aa\n[0]\nbb")

    it "creates a single history entry for multiple changes", ->
      @testEditor.setState("a \n [0]b\nc \n [1]d")
      atom.commands.dispatch @editorView, 'atomic-emacs:delete-indentation'
      atom.commands.dispatch @editorView, 'core:undo'
      expect(@testEditor.getState()).toEqual("a \n [0]b\nc \n [1]d")

  describe "atomic-emacs:open-line", ->
    it "inserts a newline in front of each cursor", ->
      @testEditor.setState("a[0]b\nc[1]d")
      atom.commands.dispatch @editorView, 'atomic-emacs:open-line'
      expect(@testEditor.getState()).toEqual("a[0]\nb\nc[1]\nd")

    it "works in an empty buffer", ->
      @testEditor.setState("[0]")
      atom.commands.dispatch @editorView, 'atomic-emacs:open-line'
      expect(@testEditor.getState()).toEqual("[0]\n")

    it "creates a single history entry for multiple changes", ->
      @testEditor.setState("a[0]b\nc[1]d")
      atom.commands.dispatch @editorView, 'atomic-emacs:open-line'
      atom.commands.dispatch @editorView, 'core:undo'
      expect(@testEditor.getState()).toEqual("a[0]b\nc[1]d")

  describe "atomic-emacs:just-one-space", ->
    it "replaces horizontal space around each cursor with a single space", ->
      @testEditor.setState("a [0] b\n\t[1]\t")
      atom.commands.dispatch @editorView, 'atomic-emacs:just-one-space'
      expect(@testEditor.getState()).toEqual("a [0]b\n [1]")

    it "merges cursors that coincide", ->
      @testEditor.setState("[0] [0]")
      atom.commands.dispatch @editorView, 'atomic-emacs:just-one-space'
      expect(@testEditor.getState()).toEqual(" [0]")

    it "creates a single history entry for multiple changes", ->
      @testEditor.setState("a [0] b\n\t[1]\t")
      atom.commands.dispatch @editorView, 'atomic-emacs:just-one-space'
      atom.commands.dispatch @editorView, 'core:undo'
      expect(@testEditor.getState()).toEqual("a [0] b\n\t[1]\t")

  describe "atomic-emacs:delete-blank-lines", ->
    it "deletes all surrounding blank lines (leaving one) if on a nonisolated blank line", ->
      @testEditor.setState(" \n [0]\n \nx\n [1]\n \nx\n [2]\n \n \nx\n \n \n [3]\nx\n \n [4]\n \n ")
      atom.commands.dispatch @editorView, 'atomic-emacs:delete-blank-lines'
      expect(@testEditor.getState()).toEqual("[0]\nx\n[1]\nx\n[2]\nx\n[3]\nx\n[4]\n")

    it "deletes that one (unless it's at eof) if on an isolated blank line", ->
      @testEditor.setState(" [0]\nx\n [1]\nx\n [2]")
      atom.commands.dispatch @editorView, 'atomic-emacs:delete-blank-lines'
      expect(@testEditor.getState()).toEqual("[0]x\n[1]x\n[2]")

    it "deletes any immediately following blank lines if on a nonblank line", ->
      @testEditor.setState("a[0]b\nx\na[1]b\n \n \nx\na[2]b\n \n ")
      atom.commands.dispatch @editorView, 'atomic-emacs:delete-blank-lines'
      expect(@testEditor.getState()).toEqual("a[0]b\nx\na[1]b\nx\na[2]b\n")

    it "creates a single history entry for multiple changes", ->
      @testEditor.setState("a\n[0]\n\na\n[1]\n")
      atom.commands.dispatch @editorView, 'atomic-emacs:delete-blank-lines'
      atom.commands.dispatch @editorView, 'core:undo'
      expect(@testEditor.getState()).toEqual("a\n[0]\n\na\n[1]\n")

  describe "atomic-emacs:transpose-chars", ->
    it "transposes the current character with the one after it", ->
      @testEditor.setState("ab[0]cd")
      atom.commands.dispatch @editorView, 'atomic-emacs:transpose-chars'
      expect(@testEditor.getState()).toEqual("acb[0]d")

    it "transposes the last two characters of the line at the end of a line", ->
      @testEditor.setState("abc[0]\ndef")
      atom.commands.dispatch @editorView, 'atomic-emacs:transpose-chars'
      expect(@testEditor.getState()).toEqual("acb[0]\ndef")

    it "transposes the first character with the newline at the start of a line", ->
      @testEditor.setState("abc\n[0]def")
      atom.commands.dispatch @editorView, 'atomic-emacs:transpose-chars'
      expect(@testEditor.getState()).toEqual("abcd\n[0]ef")

    it "does nothing at the beginning of the buffer", ->
      @testEditor.setState("[0]abcd")
      atom.commands.dispatch @editorView, 'atomic-emacs:transpose-chars'
      expect(@testEditor.getState()).toEqual("[0]abcd")

    it "transposes the last two characters at the end of the buffer", ->
      @testEditor.setState("abcd[0]")
      atom.commands.dispatch @editorView, 'atomic-emacs:transpose-chars'
      expect(@testEditor.getState()).toEqual("abdc[0]")

    it "operates on multiple cursors", ->
      @testEditor.setState("ab[0]cd ef[1]gh")
      atom.commands.dispatch @editorView, 'atomic-emacs:transpose-chars'
      expect(@testEditor.getState()).toEqual("acb[0]d egf[1]h")

    it "creates a single history entry for multiple changes", ->
      @testEditor.setState("ab[0]cd ef[1]gh")
      atom.commands.dispatch @editorView, 'atomic-emacs:transpose-chars'
      atom.commands.dispatch @editorView, 'core:undo'
      expect(@testEditor.getState()).toEqual("ab[0]cd ef[1]gh")

    it "does nothing at the end of a one-character buffer", ->
      @testEditor.setState("a[0]")
      atom.commands.dispatch @editorView, 'atomic-emacs:transpose-chars'
      expect(@testEditor.getState()).toEqual("a[0]")

    it "does nothing in an empty buffer", ->
      @testEditor.setState("[0]")
      atom.commands.dispatch @editorView, 'atomic-emacs:transpose-chars'
      expect(@testEditor.getState()).toEqual("[0]")

  describe "atomic-emacs:transpose-words", ->
    it "transposes the current word with the one after it", ->
      @testEditor.setState("aaa b[0]bb .\tccc ddd")
      atom.commands.dispatch @editorView, 'atomic-emacs:transpose-words'
      expect(@testEditor.getState()).toEqual("aaa ccc .\tbbb[0] ddd")

    it "transposes the previous and next words if at the end of a word", ->
      @testEditor.setState("aaa bbb[0] .\tccc ddd")
      atom.commands.dispatch @editorView, 'atomic-emacs:transpose-words'
      expect(@testEditor.getState()).toEqual("aaa ccc .\tbbb[0] ddd")

    it "transposes the previous and next words if at the beginning of a word", ->
      @testEditor.setState("aaa bbb .\t[0]ccc ddd")
      atom.commands.dispatch @editorView, 'atomic-emacs:transpose-words'
      expect(@testEditor.getState()).toEqual("aaa ccc .\tbbb[0] ddd")

    it "transposes the previous and next words if in between words", ->
      @testEditor.setState("aaa bbb .[0]\tccc ddd")
      atom.commands.dispatch @editorView, 'atomic-emacs:transpose-words'
      expect(@testEditor.getState()).toEqual("aaa ccc .\tbbb[0] ddd")

    it "moves to the start of the last word if in the last word", ->
      # Emacs leaves point at the start of the word, but that seems unintuitive.
      @testEditor.setState("aaa bbb .\tcc[0]c ")
      atom.commands.dispatch @editorView, 'atomic-emacs:transpose-words'
      expect(@testEditor.getState()).toEqual("aaa bbb .\tccc[0] ")

    it "transposes the last two words if at the start of the last word", ->
      @testEditor.setState("aaa bbb .\t[0]ccc")
      atom.commands.dispatch @editorView, 'atomic-emacs:transpose-words'
      expect(@testEditor.getState()).toEqual("aaa ccc .\tbbb[0]")

    it "transposes the first two words if at the start of the buffer", ->
      @testEditor.setState("[0]aaa .\tbbb ccc")
      atom.commands.dispatch @editorView, 'atomic-emacs:transpose-words'
      expect(@testEditor.getState()).toEqual("bbb .\taaa[0] ccc")

    it "moves to the start of the word if it's the only word in the buffer", ->
      # Emacs leaves point at the start of the word, but that seems unintuitive.
      @testEditor.setState(" \taaa [0]\t")
      atom.commands.dispatch @editorView, 'atomic-emacs:transpose-words'
      expect(@testEditor.getState()).toEqual(" \taaa[0] \t")

    it "operates on multiple cursors", ->
      @testEditor.setState("aa[0] bb cc[1] dd")
      atom.commands.dispatch @editorView, 'atomic-emacs:transpose-words'
      expect(@testEditor.getState()).toEqual("bb aa[0] dd cc[1]")

    it "creates a single history entry for multiple changes", ->
      @testEditor.setState("aa[0] bb cc[1] dd")
      atom.commands.dispatch @editorView, 'atomic-emacs:transpose-words'
      atom.commands.dispatch @editorView, 'core:undo'
      expect(@testEditor.getState()).toEqual("aa[0] bb cc[1] dd")

  describe "atomic-emacs:transpose-lines", ->
    it "transposes this line with the previous one, and moves to the next line", ->
      @testEditor.setState("aaa\nb[0]bb\nccc\n")
      atom.commands.dispatch @editorView, 'atomic-emacs:transpose-lines'
      expect(@testEditor.getState()).toEqual("bbb\naaa\n[0]ccc\n")

    it "pretends it's on the second line if it's on the first", ->
      @testEditor.setState("a[0]aa\nbbb\nccc\n")
      atom.commands.dispatch @editorView, 'atomic-emacs:transpose-lines'
      expect(@testEditor.getState()).toEqual("bbb\naaa\n[0]ccc\n")

    it "creates a newline at end of file if necessary", ->
      @testEditor.setState("aaa\nb[0]bb")
      atom.commands.dispatch @editorView, 'atomic-emacs:transpose-lines'
      expect(@testEditor.getState()).toEqual("bbb\naaa\n[0]")

    it "still transposes if at the end of the buffer after a trailing newline", ->
      @testEditor.setState("aaa\nbbb\n[0]")
      atom.commands.dispatch @editorView, 'atomic-emacs:transpose-lines'
      expect(@testEditor.getState()).toEqual("aaa\n\nbbb\n[0]")

    it "inserts a blank line at the top if there's only one line with a trailing newline", ->
      @testEditor.setState("a[0]aa\n")
      atom.commands.dispatch @editorView, 'atomic-emacs:transpose-lines'
      expect(@testEditor.getState()).toEqual("\naaa\n[0]")

    it "inserts a blank line at the top if there's only one line with no trailing newline", ->
      @testEditor.setState("a[0]aa")
      atom.commands.dispatch @editorView, 'atomic-emacs:transpose-lines'
      expect(@testEditor.getState()).toEqual("\naaa\n[0]")

    it "operates on multiple cursors", ->
      @testEditor.setState("aa bb\ncc dd[0]\nee ff\ngg hh\n[1]ii jj\n")
      atom.commands.dispatch @editorView, 'atomic-emacs:transpose-lines'
      expect(@testEditor.getState()).toEqual("cc dd\naa bb\n[0]ee ff\nii jj\ngg hh\n[1]")

    it "creates a single history entry for multiple changes", ->
      @testEditor.setState("aa bb\ncc dd[0]\nee ff\ngg hh\n[1]ii jj\n")
      atom.commands.dispatch @editorView, 'atomic-emacs:transpose-lines'
      atom.commands.dispatch @editorView, 'core:undo'
      expect(@testEditor.getState()).toEqual("aa bb\ncc dd[0]\nee ff\ngg hh\n[1]ii jj\n")

  describe "atomic-emacs:downcase-word-or-region", ->
    it "creates a single history entry for multiple changes", ->
      @testEditor.setState("[0]aA BB\nCC[1] DD EE[2]\nFF [3]")
      atom.commands.dispatch @editorView, 'atomic-emacs:downcase-word-or-region'
      atom.commands.dispatch @editorView, 'core:undo'
      expect(@testEditor.getState()).toEqual("[0]aA BB\nCC[1] DD EE[2]\nFF [3]")

    describe "when there is no selection", ->
      it "downcases the word after each cursor (if any)", ->
        @testEditor.setState("[0]aA BB\nCC[1] DD EE[2]\nFF [3]")
        atom.commands.dispatch @editorView, 'atomic-emacs:downcase-word-or-region'
        expect(@testEditor.getState()).toEqual("aa[0] BB\nCC dd[1] EE\nff[2] [3]")

      it "merges any cursors that coincide", ->
        @testEditor.setState("[0]AA[1]")
        atom.commands.dispatch @editorView, 'atomic-emacs:downcase-word-or-region'
        expect(@testEditor.getState()).toEqual("aa[0]")

    describe "when there are selections", ->
      it "downcases each word in each selection", ->
        @testEditor.setState("AA (0)BB CC[0] DD\nEE F[1]FFGG(1)G")
        atom.commands.dispatch @editorView, 'atomic-emacs:downcase-word-or-region'
        expect(@testEditor.getState()).toEqual("AA (0)bb cc[0] DD\nEE F[1]ffgg(1)G")

  describe "atomic-emacs:upcase-word-or-region", ->
    it "creates a single history entry for multiple changes", ->
      @testEditor.setState("[0]Aa bb\ncc[1] dd ee[2]\nff [3]")
      atom.commands.dispatch @editorView, 'atomic-emacs:upcase-word-or-region'
      atom.commands.dispatch @editorView, 'core:undo'
      expect(@testEditor.getState()).toEqual("[0]Aa bb\ncc[1] dd ee[2]\nff [3]")

    describe "when there is no selection", ->
      it "upcases the word after each cursor (if any)", ->
        @testEditor.setState("[0]Aa bb\ncc[1] dd ee[2]\nff [3]")
        atom.commands.dispatch @editorView, 'atomic-emacs:upcase-word-or-region'
        expect(@testEditor.getState()).toEqual("AA[0] bb\ncc DD[1] ee\nFF[2] [3]")

      it "merges any cursors that coincide", ->
        @testEditor.setState("[0]aa[1]")
        atom.commands.dispatch @editorView, 'atomic-emacs:upcase-word-or-region'
        expect(@testEditor.getState()).toEqual("AA[0]")

    describe "when there are selections", ->
      it "upcases each word in each selection", ->
        @testEditor.setState("aa (0)bb cc[0] dd\nee f[1]ffgg(1)g")
        atom.commands.dispatch @editorView, 'atomic-emacs:upcase-word-or-region'
        expect(@testEditor.getState()).toEqual("aa (0)BB CC[0] dd\nee f[1]FFGG(1)g")

  describe "atomic-emacs:capitalize-word-or-region", ->
    it "creates a single history entry for multiple changes", ->
      @testEditor.setState("[0]aA bb\ncc[1] dd ee[2]\nff [3]")
      atom.commands.dispatch @editorView, 'atomic-emacs:capitalize-word-or-region'
      atom.commands.dispatch @editorView, 'core:undo'
      expect(@testEditor.getState()).toEqual("[0]aA bb\ncc[1] dd ee[2]\nff [3]")

    describe "when there is no selection", ->
      it "capitalizes the word after each cursor (if any)", ->
        @testEditor.setState("[0]aA bb\ncc[1] dd ee[2]\nff [3]")
        atom.commands.dispatch @editorView, 'atomic-emacs:capitalize-word-or-region'
        expect(@testEditor.getState()).toEqual("Aa[0] bb\ncc Dd[1] ee\nFf[2] [3]")

      it "merges any cursors that coincide", ->
        @testEditor.setState("[0]aa[1]")
        atom.commands.dispatch @editorView, 'atomic-emacs:capitalize-word-or-region'
        expect(@testEditor.getState()).toEqual("Aa[0]")

    describe "when there are selections", ->
      it "capitalizes each word in each selection", ->
        @testEditor.setState("aa (0)bb CC[0] dd\nee f[1]FFGG(1)G")
        atom.commands.dispatch @editorView, 'atomic-emacs:capitalize-word-or-region'
        expect(@testEditor.getState()).toEqual("aa (0)Bb Cc[0] dd\nee f[1]Ffgg(1)G")

  describe "atomic_emacs:set-mark", ->
    it "sets and activates the mark of all cursors", ->
      @testEditor.setState("[0].[1]")
      [cursor0, cursor1] = @editor.getCursors()
      atom.commands.dispatch @editorView, 'atomic-emacs:set-mark'

      mark0 = EmacsCursor.for(cursor0).mark()
      expect(mark0.isActive()).toBe(true)
      point = mark0.getBufferPosition()
      expect([point.row, point.column]).toEqual([0, 0])

      mark1 = EmacsCursor.for(cursor1).mark()
      expect(mark1.isActive()).toBe(true)
      point = mark1.getBufferPosition()
      expect([point.row, point.column]).toEqual([0, 1])

    it "deactivates marks after all selections are updated", ->
      @testEditor.setState("a[0]bcd e[1]fgh")
      atom.commands.dispatch @editorView, 'atomic-emacs:set-mark'

      atom.commands.dispatch @editorView, 'atomic-emacs:forward-char'
      atom.commands.dispatch @editorView, 'atomic-emacs:forward-char'
      expect(@testEditor.getState()).toEqual("a(0)bc[0]d e(1)fg[1]h")

      atom.commands.dispatch @editorView, 'core:backspace'
      expect(@testEditor.getState()).toEqual("a[0]d e[1]h")
      result = (EmacsCursor.for(c).mark().isActive() for c in @editor.getCursors())
      expect(result).toEqual([false, false])

    it "properly cleans up if the editor is closed while the mark is active", ->
      atom.commands.dispatch @editorView, 'atomic-emacs:set-mark'
      atom.commands.dispatch atom.views.getView(atom.workspace), 'core:close'

  describe "atomic-emacs:mark-sexp", ->
    it "marks a symbol forward of the cursor", ->
      @testEditor.setState("a[0] bc ")
      atom.commands.dispatch @editorView, 'atomic-emacs:mark-sexp'
      expect(@testEditor.getState()).toEqual("a[0] bc(0) ")

    it "marks a balanced delimited expression from the cursor", ->
      @testEditor.setState("a[0] (b c) ")
      atom.commands.dispatch @editorView, 'atomic-emacs:mark-sexp'
      expect(@testEditor.getState()).toEqual("a[0] (b c)(0) ")

    it "marks a balanced quoted expression from the cursor", ->
      @testEditor.setState("a[0] 'b c' ")
      atom.commands.dispatch @editorView, 'atomic-emacs:mark-sexp'
      expect(@testEditor.getState()).toEqual("a[0] 'b c'(0) ")

    it "handles nested delimiters", ->
      @testEditor.setState("a[0] (b' 'c) ")
      atom.commands.dispatch @editorView, 'atomic-emacs:mark-sexp'
      expect(@testEditor.getState()).toEqual("a[0] (b' 'c)(0) ")

    it "extends the marked region on successive calls", ->
      @testEditor.setState("a[0] bc (d e) ")
      atom.commands.dispatch @editorView, 'atomic-emacs:mark-sexp'
      expect(@testEditor.getState()).toEqual("a[0] bc(0) (d e) ")
      atom.commands.dispatch @editorView, 'atomic-emacs:mark-sexp'
      expect(@testEditor.getState()).toEqual("a[0] bc (d e)(0) ")

    it "does not extend a deactivated mark when followed by a move", ->
      @testEditor.setState("a[0]bcd")
      atom.commands.dispatch @editorView, 'atomic-emacs:set-mark'
      atom.commands.dispatch @editorView, 'atomic-emacs:forward-char'
      atom.commands.dispatch @editorView, 'core:cancel'

      atom.commands.dispatch @editorView, 'atomic-emacs:mark-sexp'
      atom.commands.dispatch @editorView, 'atomic-emacs:forward-char'
      expect(@testEditor.getState()).toEqual("abc[0]d(0)")

  describe "atomic-emacs:mark-whole-buffer", ->
    it "marks the whole buffer, with the cursor at the beginning", ->
      @testEditor.setState(" [0] ")
      atom.commands.dispatch @editorView, 'atomic-emacs:mark-whole-buffer'
      expect(@testEditor.getState()).toEqual("[0]  (0)")

    it "removes extra cursors", ->
      @testEditor.setState(" [0] [1]")
      atom.commands.dispatch @editorView, 'atomic-emacs:mark-whole-buffer'
      expect(@testEditor.getState()).toEqual("[0]  (0)")

  describe "atomic-emacs:exchange-point-and-mark", ->
    it "exchanges all cursors with their marks", ->
      @testEditor.setState("[0]..[1].")
      atom.commands.dispatch @editorView, 'atomic-emacs:set-mark'
      atom.commands.dispatch @editorView, 'atomic-emacs:forward-char'
      expect(@testEditor.getState()).toEqual("(0).[0].(1).[1]")
      atom.commands.dispatch @editorView, 'atomic-emacs:exchange-point-and-mark'
      expect(@testEditor.getState()).toEqual("[0].(0).[1].(1)")

  describe "atomic-emacs:close-other-panes", ->
    it "should close all inactive panes", ->
      pane1 = atom.workspace.getActivePane()
      pane2 = pane1.splitRight()
      pane3 = pane2.splitRight()
      pane2.activate()

      atom.commands.dispatch @editorView, 'atomic-emacs:close-other-panes'

      expect(pane1.isDestroyed()).toEqual(true)
      expect(pane2.isDestroyed()).toEqual(false)
      expect(pane3.isDestroyed()).toEqual(true)

  describe "core:cancel", ->
    it "deactivates all marks", ->
      @testEditor.setState("[0].[1]")
      [mark0, mark1] = (EmacsCursor.for(c).mark() for c in @editor.getCursors())
      m.activate() for m in [mark0, mark1]
      atom.commands.dispatch @editorView, 'core:cancel'
      expect(mark0.isActive()).toBe(false)

  describe "atomic-emacs:scroll-up", ->
    it "does not crash on an empty editor", ->
      @testEditor.setState('')
      atom.commands.dispatch @editorView, 'atomic-emacs:scroll-up'

  describe "atomic-emacs:scroll-down", ->
    it "does not crash on an empty editor", ->
      @testEditor.setState('')
      atom.commands.dispatch @editorView, 'atomic-emacs:scroll-up'
