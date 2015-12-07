EditorState = require './editor-state'
KillRing = require './../lib/kill-ring'

describe "KillRing", ->
  beforeEach ->
    waitsForPromise =>
      atom.workspace.open().then (editor) =>
        @editor = editor
        @cursor = @editor.getLastCursor()
        @killRing = KillRing.for(@cursor)

  describe ".for", ->
    it "returns the kill ring for the given cursor", ->
      EditorState.set(@editor, "[0].[1]")
      [cursor0, cursor1] = @editor.getCursors()
      killRing0 = KillRing.for(cursor0)
      killRing1 = KillRing.for(cursor1)
      expect(killRing0.cursor).toBe(cursor0)
      expect(killRing1.cursor).toBe(cursor1)

    it "returns the same KillRing each time for a cursor", ->
      killRing = KillRing.for(@cursor)
      expect(KillRing.for(@cursor)).toBe(killRing)

  describe "constructor", ->
    it "creates an empty kill ring", ->
      expect(@killRing.getEntries()).toEqual([])

  describe "push", ->
    it "appends the given entry to the list", ->
      @killRing.push('a')
      @killRing.push('b')
      expect(@killRing.getEntries()).toEqual(['a', 'b'])

  describe "append", ->
    it "creates an entry if the kill ring is empty", ->
      @killRing.append('a')
      expect(@killRing.getEntries()).toEqual(['a'])

    it "appends the given text to the last entry otherwise", ->
      @killRing.push('a')
      @killRing.push('b')
      @killRing.append('c')
      expect(@killRing.getEntries()).toEqual(['a', 'bc'])

  describe "prepend", ->
    it "creates an entry if the kill ring is empty", ->
      @killRing.prepend('a')
      expect(@killRing.getEntries()).toEqual(['a'])

    it "prepends the given text to the last entry otherwise", ->
      @killRing.push('a')
      @killRing.push('b')
      @killRing.prepend('c')
      expect(@killRing.getEntries()).toEqual(['a', 'cb'])
