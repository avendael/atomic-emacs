module.exports =
class KillRing
  @instances = {}

  @for: (cursor) ->
   cursor._atomicEmacsKillRing ?= new this(cursor)

  constructor: (cursor) ->
    @cursor = cursor
    @entries = []
    @limit = 500
    KillRing.instances[cursor.id] = this
    cursor.onDidDestroy ->
      delete KillRing.instances[cursor.id]

  getEntries: ->
    @entries.slice()

  setEntries: (entries) ->
    @entries = entries

  last: ->
    if @entries.length == 0
      null
    else
      @entries[@entries.length - 1]

  push: (text) ->
    @entries.push(text)
    if @entries.length > @limit
      @entries.shift()

  append: (text) ->
    if @entries.length == 0
      @push(text)
    else
      index = @entries.length - 1
      @entries[index] += text

  prepend: (text) ->
    if @entries.length == 0
      @push(text)
    else
      index = @entries.length - 1
      @entries[index] = "#{text}#{@entries[index]}"
