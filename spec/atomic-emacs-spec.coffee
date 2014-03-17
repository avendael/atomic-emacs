{WorkspaceView} = require 'atom'
AtomicEmacs = require '../lib/atomic-emacs'
EditorState = require './editor-state'

describe "AtomicEmacs", ->
  beforeEach ->
    atom.workspaceView = new WorkspaceView
    @editor = atom.project.openSync()
    @event = targetView: => {editor: @editor}

  describe "atomic-emacs:transpose-words", ->
    it "transposes the current word with the one after it", ->
      EditorState.set(@editor, "aaa b[0]bb .\tccc ddd")
      AtomicEmacs.transposeWords(@event)
      expect(EditorState.get(@editor)).toEqual("aaa ccc .\tbbb[0] ddd")

    it "transposes the previous and next words if at the end of a word", ->
      EditorState.set(@editor, "aaa bbb[0] .\tccc ddd")
      AtomicEmacs.transposeWords(@event)
      expect(EditorState.get(@editor)).toEqual("aaa ccc .\tbbb[0] ddd")

    it "transposes the previous and next words if at the beginning of a word", ->
      EditorState.set(@editor, "aaa bbb .\t[0]ccc ddd")
      AtomicEmacs.transposeWords(@event)
      expect(EditorState.get(@editor)).toEqual("aaa ccc .\tbbb[0] ddd")

    it "transposes the previous and next words if in between words", ->
      EditorState.set(@editor, "aaa bbb .[0]\tccc ddd")
      AtomicEmacs.transposeWords(@event)
      expect(EditorState.get(@editor)).toEqual("aaa ccc .\tbbb[0] ddd")

    it "moves to the start of the last word if in the last word", ->
      # Emacs leaves point at the start of the word, but that seems unintuitive.
      EditorState.set(@editor, "aaa bbb .\tcc[0]c ")
      AtomicEmacs.transposeWords(@event)
      expect(EditorState.get(@editor)).toEqual("aaa bbb .\tccc[0] ")

    it "transposes the last two words if at the start of the last word", ->
      EditorState.set(@editor, "aaa bbb .\t[0]ccc")
      AtomicEmacs.transposeWords(@event)
      expect(EditorState.get(@editor)).toEqual("aaa ccc .\tbbb[0]")

    it "transposes the first two words if at the start of the buffer", ->
      EditorState.set(@editor, "[0]aaa .\tbbb ccc")
      AtomicEmacs.transposeWords(@event)
      expect(EditorState.get(@editor)).toEqual("bbb .\taaa[0] ccc")

    it "moves to the start of the word if it's the only word in the buffer", ->
      # Emacs leaves point at the start of the word, but that seems unintuitive.
      EditorState.set(@editor, " \taaa [0]\t")
      AtomicEmacs.transposeWords(@event)
      expect(EditorState.get(@editor)).toEqual(" \taaa[0] \t")

  describe "atomic-emacs:transpose-lines", ->
    it "transposes this line with the previous one, and moves to the next line", ->
      EditorState.set(@editor, "aaa\nb[0]bb\nccc\n")
      AtomicEmacs.transposeLines(@event)
      expect(EditorState.get(@editor)).toEqual("bbb\naaa\n[0]ccc\n")

    it "pretends it's on the second line if it's on the first", ->
      EditorState.set(@editor, "a[0]aa\nbbb\nccc\n")
      AtomicEmacs.transposeLines(@event)
      expect(EditorState.get(@editor)).toEqual("bbb\naaa\n[0]ccc\n")

    it "creates a newline at end of file if necessary", ->
      EditorState.set(@editor, "aaa\nb[0]bb")
      AtomicEmacs.transposeLines(@event)
      expect(EditorState.get(@editor)).toEqual("bbb\naaa\n[0]")

    it "still transposes if at the end of the buffer after a trailing newline", ->
      EditorState.set(@editor, "aaa\nbbb\n[0]")
      AtomicEmacs.transposeLines(@event)
      expect(EditorState.get(@editor)).toEqual("aaa\n\nbbb\n[0]")

    it "inserts a blank line at the top if there's only one line with a trailing newline", ->
      EditorState.set(@editor, "a[0]aa\n")
      AtomicEmacs.transposeLines(@event)
      expect(EditorState.get(@editor)).toEqual("\naaa\n[0]")

    it "inserts a blank line at the top if there's only one line with no trailing newline", ->
      EditorState.set(@editor, "a[0]aa")
      AtomicEmacs.transposeLines(@event)
      expect(EditorState.get(@editor)).toEqual("\naaa\n[0]")
