KillRing = require './../lib/kill-ring'
TestEditor = require './test-editor'

describe "KillRing", ->
  beforeEach ->
    waitsForPromise =>
      atom.workspace.open().then (editor) =>
        @editor = editor
        @cursor = @editor.getLastCursor()
        @killRing = new KillRing

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
