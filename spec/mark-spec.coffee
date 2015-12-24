Mark = require './../lib/mark'
TestEditor = require './test-editor'

describe "Mark", ->
  beforeEach ->
    waitsForPromise =>
      atom.workspace.open().then (editor) =>
        @editor = editor
        @testEditor = new TestEditor(@editor)
        @cursor = @editor.getLastCursor()

  describe "constructor", ->
    it "sets the mark to where the cursor is", ->
      @testEditor.setState(".[0]")
      mark = new Mark(@cursor)
      {row, column} = mark.getBufferPosition()
      expect([row, column]).toEqual([0, 1])

  describe "set", ->
    it "sets the mark position to where the cursor is", ->
      @testEditor.setState("[0].")
      mark = new Mark(@cursor)

      @cursor.setBufferPosition([0, 1])
      expect(mark.getBufferPosition().column).toEqual(0)

      mark.set()
      expect(mark.getBufferPosition().column).toEqual(1)

    it "clears the active selection", ->
      @testEditor.setState("a(0)b[0]c")
      mark = new Mark(@cursor)
      expect(@cursor.selection.getText()).toEqual('b')

      mark.set()
      expect(@cursor.selection.getText()).toEqual('')

    it "returns the mark so we can conveniently chain an activate() call", ->
      mark = new Mark(@cursor)
      expect(mark.set()).toBe(mark)

  describe "activate", ->
    it "activates the mark", ->
      mark = new Mark(@cursor)
      mark.activate()
      expect(mark.isActive()).toBe(true)

    it "causes cursor movements to extend the selection", ->
      @testEditor.setState(".[0]..")
      new Mark(@cursor).activate()
      @cursor.setBufferPosition([0, 2])
      expect(@testEditor.getState()).toEqual(".(0).[0].")

    it "causes buffer edits to deactivate the mark after the current command", ->
      @testEditor.setState(".[0]..")
      mark = new Mark(@cursor)

      mark.set().activate()
      @cursor.setBufferPosition([0, 2])
      expect(@testEditor.getState()).toEqual(".(0).[0].")

      @editor.setTextInBufferRange([[0, 0], [0, 1]], 'x')
      expect(mark.isActive()).toBe(false)
      expect(@testEditor.getState()).toEqual("x.[0].")
      expect(@cursor.selection.isEmpty()).toBe(true)

    it "doesn't deactive the mark if changes are indents", ->
      @testEditor.setState(".[0]..")
      mark = new Mark(@cursor)

      mark.set().activate()
      @cursor.setBufferPosition([0, 2])
      expect(@testEditor.getState()).toEqual(".(0).[0].")

      @editor.indentSelectedRows()
      expect(mark.isActive()).toBe(true)
      expect(@testEditor.getState()).toEqual("  .(0).[0].")
      expect(@cursor.selection.isEmpty()).toBe(false)

  describe "deactivate", ->
    it "deactivates the mark", ->
      mark = new Mark(@cursor)
      mark.activate()
      expect(mark.isActive()).toBe(true)
      mark.deactivate()
      expect(mark.isActive()).toBe(false)

    it "clears the selection", ->
      @testEditor.setState("[0].")
      mark = new Mark(@cursor)
      mark.activate()
      @cursor.setBufferPosition([0, 1])
      expect(@cursor.selection.isEmpty()).toBe(false)

      mark.deactivate()
      expect(@cursor.selection.isEmpty()).toBe(true)

  describe "exchange", ->
    it "exchanges the cursor and mark", ->
      @testEditor.setState("[0].")
      mark = new Mark(@cursor)
      @cursor.setBufferPosition([0, 1])

      mark.exchange()

      point = mark.getBufferPosition()
      expect([point.row, point.column]).toEqual([0, 1])
      point = @cursor.getBufferPosition()
      expect([point.row, point.column]).toEqual([0, 0])

    it "activates the mark & selection if it wasn't active", ->
      @testEditor.setState("[0].")
      mark = new Mark(@cursor)
      @cursor.setBufferPosition([0, 1])

      expect(@testEditor.getState()).toEqual(".[0]")
      expect(mark.isActive()).toBe(false)

      mark.exchange()

      expect(@testEditor.getState()).toEqual("[0].(0)")
      expect(mark.isActive()).toBe(true)

    it "leaves the mark & selection active if it already was", ->
      @testEditor.setState("[0].")
      mark = new Mark(@cursor)
      mark.activate()
      @cursor.setBufferPosition([0, 1])

      expect(@testEditor.getState()).toEqual("(0).[0]")
      expect(mark.isActive()).toBe(true)

      mark.exchange()

      expect(@testEditor.getState()).toEqual("[0].(0)")
      expect(mark.isActive()).toBe(true)
