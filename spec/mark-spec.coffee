{WorkspaceView} = require 'atom'
EditorState = require './editor-state'
Mark = require './../lib/mark'

describe "Mark", ->
  beforeEach ->
    atom.workspaceView = new WorkspaceView
    @editor = atom.project.openSync()
    @cursor = @editor.getCursor()

  describe ".for", ->
    it "returns the mark for the given cursor", ->
      EditorState.set(@editor, "a[0]b[1]c")
      [cursor0, cursor1] = @editor.getCursors()
      mark0 = Mark.for(cursor0)
      mark1 = Mark.for(cursor1)
      expect(mark0.cursor).toBe(cursor0)
      expect(mark1.cursor).toBe(cursor1)

    it "returns the same Mark each time for a cursor", ->
      mark = Mark.for(@cursor)
      expect(Mark.for(@cursor)).toBe(mark)

  describe "constructor", ->
    it "sets the mark to where the cursor is", ->
      EditorState.set(@editor, ".[0]")
      mark = Mark.for(@cursor)
      {row, column} = mark.getBufferPosition()
      expect([row, column]).toEqual([0, 1])

    it "deactivates and destroys the marker when the cursor is destroyed", ->
      EditorState.set(@editor, "[0].")
      [cursor0, cursor1] = @editor.getCursors()
      numMarkers = @editor.getMarkerCount()

      cursor1 = @editor.addCursorAtBufferPosition([0, 1])
      mark1 = Mark.for(cursor1)
      expect(@editor.getMarkerCount()).toBeGreaterThan(numMarkers)

      cursor1.destroy()
      expect(mark1.isActive()).toBe(false)
      expect(@editor.getMarkerCount()).toEqual(numMarkers)

  describe "set", ->
    it "sets the mark position to where the cursor is", ->
      EditorState.set(@editor, "[0].")
      mark = Mark.for(@cursor)

      @cursor.setBufferPosition([0, 1])
      expect(mark.getBufferPosition().column).toEqual(0)

      mark.set()
      expect(mark.getBufferPosition().column).toEqual(1)

    it "clears the active selection", ->
      EditorState.set(@editor, "a(0)b[0]c")
      mark = Mark.for(@cursor)
      expect(@cursor.selection.getText()).toEqual('b')

      mark.set()
      expect(@cursor.selection.getText()).toEqual('')

    it "returns the mark so we can conveniently chain an activate() call", ->
      mark = Mark.for(@cursor)
      expect(mark.set()).toBe(mark)

  describe "activate", ->
    it "activates the mark", ->
      mark = Mark.for(@cursor)
      mark.activate()
      expect(mark.isActive()).toBe(true)

    it "causes cursor movements to extend the selection", ->
      EditorState.set(@editor, ".[0]..")
      Mark.for(@cursor).activate()
      @cursor.setBufferPosition([0, 2])
      expect(EditorState.get(@editor)).toEqual(".(0).[0].")

    it "causes buffer edits to deactivate the mark", ->
      EditorState.set(@editor, ".[0]..")
      mark = Mark.for(@cursor)

      mark.set().activate()
      @cursor.setBufferPosition([0, 2])
      expect(EditorState.get(@editor)).toEqual(".(0).[0].")

      @editor.setTextInBufferRange([[0, 0], [0, 1]], 'x')
      expect(mark.isActive()).toBe(false)
      expect(EditorState.get(@editor)).toEqual("x.[0].")
      expect(@cursor.selection.isEmpty()).toBe(true)

    it "doesn't deactive the mark if changes are indents", ->
      EditorState.set(@editor, ".[0]..")
      mark = Mark.for(@cursor)

      mark.set().activate()
      @cursor.setBufferPosition([0, 2])
      expect(EditorState.get(@editor)).toEqual(".(0).[0].")

      @editor.indentSelectedRows()
      expect(mark.isActive()).toBe(true)
      expect(EditorState.get(@editor)).toEqual("  .(0).[0].")
      expect(@cursor.selection.isEmpty()).toBe(false)
      
  describe "deactivate", ->
    it "deactivates the mark", ->
      mark = Mark.for(@cursor)
      mark.activate()
      expect(mark.isActive()).toBe(true)
      mark.deactivate()
      expect(mark.isActive()).toBe(false)

    it "clears the selection", ->
      EditorState.set(@editor, "[0].")
      mark = Mark.for(@cursor)
      mark.activate()
      @cursor.setBufferPosition([0, 1])
      expect(@cursor.selection.isEmpty()).toBe(false)

      mark.deactivate()
      expect(@cursor.selection.isEmpty()).toBe(true)

  describe "exchange", ->
    it "exchanges the cursor and mark", ->
      EditorState.set(@editor, "[0].")
      mark = Mark.for(@cursor)
      @cursor.setBufferPosition([0, 1])

      mark.exchange()

      point = mark.getBufferPosition()
      expect([point.row, point.column]).toEqual([0, 1])
      point = @cursor.getBufferPosition()
      expect([point.row, point.column]).toEqual([0, 0])

    it "activates the mark & selection if it wasn't active", ->
      EditorState.set(@editor, "[0].")
      mark = Mark.for(@cursor)
      @cursor.setBufferPosition([0, 1])

      expect(EditorState.get(@editor)).toEqual(".[0]")
      expect(mark.isActive()).toBe(false)

      mark.exchange()

      expect(EditorState.get(@editor)).toEqual("[0].(0)")
      expect(mark.isActive()).toBe(true)

    it "leaves the mark & selection active if it already was", ->
      EditorState.set(@editor, "[0].")
      mark = Mark.for(@cursor)
      mark.activate()
      @cursor.setBufferPosition([0, 1])

      expect(EditorState.get(@editor)).toEqual("(0).[0]")
      expect(mark.isActive()).toBe(true)

      mark.exchange()

      expect(EditorState.get(@editor)).toEqual("[0].(0)")
      expect(mark.isActive()).toBe(true)
