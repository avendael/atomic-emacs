TestEditor = require './test-editor'

describe "TestEditor", ->
  cursorPosition = (editor, i) ->
    cursor = editor.getCursors()[i]
    point = cursor?.getBufferPosition()
    [point?.row, point?.column]

  cursorRange = (editor, i) ->
    cursor = editor.getCursors()[i]
    return null if !cursor?

    head = cursor.marker.getHeadBufferPosition()
    tail = cursor.marker.getTailBufferPosition()
    [head?.row, head?.column, tail?.row, tail?.column]

  beforeEach ->
    waitsForPromise =>
      atom.workspace.open().then (editor) =>
        @editor = editor
        @testEditor = new TestEditor(@editor)

  describe "set", ->
    it "sets the buffer text", ->
      @testEditor.setState('hi')
      expect(@editor.getText()).toEqual('hi')

    it "sets cursors where specified", ->
      @testEditor.setState('[0]a[2]b[1]')
      expect(@editor.getText()).toEqual('ab')

      expect(cursorPosition(@editor, 0)).toEqual([0, 0])
      expect(cursorPosition(@editor, 1)).toEqual([0, 2])
      expect(cursorPosition(@editor, 2)).toEqual([0, 1])

    it "handles missing cursors", ->
      expect((=> @testEditor.setState('[0]x[2]'))).
        toThrow('missing head of cursor 1')

    it "sets forward & reverse selections if tails are specified", ->
      @testEditor.setState('a(0)b[1]c[0]d(1)e')
      expect(@editor.getText()).toEqual('abcde')

      expect(cursorRange(@editor, 0)).toEqual([0, 3, 0, 1])
      expect(cursorRange(@editor, 1)).toEqual([0, 2, 0, 4])

  describe "get", ->
    it "correctly positions cursors", ->
      @editor.setText('abc')
      @editor.getLastCursor().setBufferPosition([0, 2])
      @editor.addCursorAtBufferPosition([0, 1])
      expect(@testEditor.getState()).toEqual('a[1]b[0]c')

    it "correctly positions heads & tails of forward & reverse selections", ->
      @editor.setText('abcde')
      @editor.getLastCursor().selection.setBufferRange([[0, 1], [0, 3]])
      cursor = @editor.addCursorAtBufferPosition([0, 0])
      cursor.selection.setBufferRange([[0, 2], [0, 4]], reversed: true)
      expect(@testEditor.getState()).toEqual('a(0)b[1]c[0]d(1)e')
