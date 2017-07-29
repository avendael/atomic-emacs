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

  describe ".pullFromClipboard", ->
    beforeEach ->
      KillRing.global.reset()

    describe "when a single kill ring (the global one) is given", ->
      beforeEach ->
        atom.clipboard.write('old')
        KillRing.lastClip = 'old'
        @killRings = [KillRing.global]

      describe "when there is something new on the clipboard", ->
        beforeEach ->
          atom.clipboard.write('new')

        it "adds it to the kill ring and updates the last clip", ->
          KillRing.pullFromClipboard(@killRings)
          expect(@killRings[0].getEntries()).toEqual(['new'])
          expect(KillRing.lastClip).toEqual('new')

      describe "when there is nothing new on the clipboard", ->
        it "does not update the kill ring", ->
          KillRing.pullFromClipboard(@killRings)
          expect(@killRings[0].getEntries()).toEqual([])

    describe "when multiple kill rings are given", ->
      beforeEach ->
        atom.clipboard.write('old0\nold1\n')
        @killRings = [@killRing, new KillRing]
        KillRing.lastClip = 'old0\nold1\n'

      describe "when there is something new on the clipboard", ->
        it "adds each line to a separate kill ring and updates the last clip", ->
          atom.clipboard.write('new0\nnew1')
          KillRing.pullFromClipboard(@killRings)
          expect(@killRings[0].getEntries()).toEqual(['new0'])
          expect(@killRings[1].getEntries()).toEqual(['new1'])
          expect(KillRing.lastClip).toEqual('new0\nnew1')

        it "ignores extra lines if there are more lines than kill rings", ->
          atom.clipboard.write('new0\nnew1\nnew2')
          KillRing.pullFromClipboard(@killRings)
          expect(@killRings[0].getEntries()).toEqual(['new0'])
          expect(@killRings[1].getEntries()).toEqual(['new1'])

        it "adds entries to all kill rings if there are more kill rings than lines", ->
          atom.clipboard.write('new0')
          KillRing.pullFromClipboard(@killRings)
          expect(@killRings[0].getEntries()).toEqual(['new0'])
          expect(@killRings[1].getEntries()).toEqual([''])

      describe "when there is nothing new on the clipboard", ->
        it "does not update the kill rings", ->
          KillRing.pullFromClipboard(@killRings)
          expect(@killRings[0].getEntries()).toEqual([])
          expect(@killRings[1].getEntries()).toEqual([])

  describe ".pushToClipboard", ->
    beforeEach ->
      KillRing.global.reset()

    describe "when a single kill ring (the global one) is given", ->
      beforeEach ->
        @killRings = [KillRing.global]
        atom.clipboard.write('old')
        KillRing.lastClip = 'old'
        @killRings[0].push('new')

      it "pushes the global kill ring entry to the clipboard", ->
        KillRing.pushToClipboard(@killRings)
        expect(atom.clipboard.read()).toEqual('new')

      it "updates the last clip, so subsequent pulls don't append again", ->
        KillRing.pushToClipboard(@killRings)
        expect(KillRing.lastClip).toEqual('new')

        KillRing.pullFromClipboard(@killRings)
        expect(KillRing.global.getEntries()).toEqual(['new'])

    describe "when multiple kill rings are given", ->
      beforeEach ->
        atom.clipboard.write('old0\nold1\n')
        @killRings = [@killRing, new KillRing]
        KillRing.lastClip = 'old0\nold1\n'
        KillRing.global.push('new0\nnew1\n')

      it "pushes the global kill ring entry to the clipboard", ->
        KillRing.pushToClipboard(@killRings)
        expect(atom.clipboard.read()).toEqual('new0\nnew1\n')

      it "updates the last clip, so subsequent pulls don't append the same thing", ->
        KillRing.pushToClipboard(@killRings)
        expect(KillRing.lastClip).toEqual('new0\nnew1\n')

        KillRing.pullFromClipboard(@killRings)
        expect(@killRings[0].getEntries()).toEqual([])
        expect(@killRings[1].getEntries()).toEqual([])
        expect(KillRing.global.getEntries()).toEqual(['new0\nnew1\n'])
