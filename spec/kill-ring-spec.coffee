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

  describe "fork", ->
    it "creates a copy of the kill ring, with the same current entry", ->
      @killRing.setEntries(['x', 'y']).rotate(-1)
      fork = @killRing.fork()
      expect(fork.getEntries()).toEqual(['x', 'y'])
      expect(fork.getCurrentEntry()).toEqual('x')

    it "maintains separate state to the original", ->
      @killRing.setEntries(['x', 'y']).rotate(-1)
      fork = @killRing.fork()

      fork.rotate(1)
      expect(fork.getCurrentEntry()).toEqual('y')

      fork.push('z')
      expect(fork.getEntries()).toEqual(['x', 'y', 'z'])

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

  describe "rotate", ->
    it "rotates the killRing contents", ->
      @killRing.push('a')
      @killRing.push('b')
      @killRing.push('c')
      expect(@killRing.getCurrentEntry()).toEqual('c')
      expect(@killRing.rotate(-1)).toEqual('b')
      expect(@killRing.getCurrentEntry()).toEqual('b')
      expect(@killRing.rotate(-1)).toEqual('a')
      expect(@killRing.rotate(-1)).toEqual('c')
      expect(@killRing.rotate(1)).toEqual('a')
      @killRing.push('d')
      expect(@killRing.getCurrentEntry()).toEqual('d')
      expect(@killRing.rotate(-1)).toEqual('c')

  describe "with atomic-emacs.yankFromClipboard and atomic-emacs.pushToClipboard enabled
      it pulls from the clipboard before preforming any operations", ->
    beforeEach ->
      atom.config.set "atomic-emacs.yankFromClipboard", true
      atom.config.set 'atomic-emacs.killToClipboard', true

    describe "push", ->
      it "appends the given entry to the list and sends it to the clipboard", ->
        @killRing.push('a')
        expect(atom.clipboard.read()).toEqual('a')
        atom.clipboard.write('b')
        @killRing.push('c')
        expect(atom.clipboard.read()).toEqual('c')
        expect(@killRing.getEntries()).toEqual(['initial clipboard content', 'a', 'b', 'c'])

    describe "append", ->
      it "", ->
        @killRing.append('a')
        expect(atom.clipboard.read()).toEqual('initial clipboard contenta')
        expect(@killRing.getEntries()).toEqual(['initial clipboard contenta'])

      it "appends the given text to the last entry otherwise", ->
        @killRing.push('a')
        atom.clipboard.write('b')
        @killRing.append('c')
        expect(atom.clipboard.read()).toEqual('bc')
        expect(@killRing.getEntries()).toEqual(['initial clipboard content', 'a', 'bc'])

    describe "prepend", ->
      it "creates an entry if the kill ring is empty", ->
        @killRing.prepend('a')
        expect(atom.clipboard.read()).toEqual('ainitial clipboard content')
        expect(@killRing.getEntries()).toEqual(['ainitial clipboard content'])

      it "prepends the given text to the last entry otherwise", ->
        @killRing.push('a')
        atom.clipboard.write('b')
        @killRing.prepend('c')
        expect(atom.clipboard.read()).toEqual('cb')
        expect(@killRing.getEntries()).toEqual(['initial clipboard content', 'a', 'cb'])

    describe "rotate, getCurrentEntry, and position tracking", ->
      it "rotates the currentEntry through the killRing contents", ->
        expect(@killRing.getCurrentEntry()).toEqual('initial clipboard content')
        @killRing.push('a')
        @killRing.push('b')
        @killRing.push('c')
        expect(@killRing.getCurrentEntry()).toEqual('c')
        expect(@killRing.rotate(-1)).toEqual('b')
        expect(@killRing.getCurrentEntry()).toEqual('b')
        expect(@killRing.rotate(-1)).toEqual('a')
        expect(@killRing.rotate(-1)).toEqual('initial clipboard content')
        atom.clipboard.write('d')
        expect(@killRing.rotate(-1)).toEqual('c')
        atom.clipboard.write('e')
        expect(@killRing.getCurrentEntry()).toEqual('e')


