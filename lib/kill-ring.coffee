module.exports =
class KillRing
  @instances = {}

  @for: (cursor) ->
   cursor._atomicEmacsKillRing ?= new this(cursor)

  constructor: (cursor) ->
    @cursor = cursor
    @currentIndex = -1
    @entries = []
    @limit = 500
    @marker = null
    KillRing.instances[cursor.id] = this
    cursor.onDidDestroy ->
      delete KillRing.instances[cursor.id]

  getEntries: ->
    @entries.slice()

  setEntries: (entries) ->
    @entries = entries
    @currentIndex = @entries.length - 1

  push: (text) ->
    @entries.push(text)
    if @entries.length > @limit
      @entries.shift()
    @currentIndex = @entries.length - 1

  append: (text) ->
    if @entries.length == 0
      @push(text)
    else
      index = @entries.length - 1
      @entries[index] += text
      @currentIndex = @entries.length - 1

  prepend: (text) ->
    if @entries.length == 0
      @push(text)
    else
      index = @entries.length - 1
      @entries[index] = "#{text}#{@entries[index]}"
      @currentIndex = @entries.length - 1

  currentEntry: ->
    if @entries.length == 0
      return null
    else
      @entries[@currentIndex]

  yank: ->
    if @entries.length > 0
      @_ensureMarkerInitialized()
      range = @cursor.editor.setTextInBufferRange(@marker.getBufferRange(), @currentEntry())
      @marker.setBufferRange(range)

  rotate: (n) ->
    return if @entries.length == 0 or @marker == null
    @currentIndex = (@currentIndex + n) % @entries.length
    @currentIndex += @entries.length if @currentIndex < 0
    range = @cursor.editor.setTextInBufferRange(@marker.getBufferRange(), @currentEntry())
    @marker.setBufferRange(range)

  yankComplete: ->
    if @marker
      @marker.destroy()
      @marker = null

  _ensureMarkerInitialized: ->
    return if @marker
    @marker = @cursor.editor.markBufferPosition(@cursor.getBufferPosition())
