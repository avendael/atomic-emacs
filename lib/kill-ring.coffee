module.exports =
class KillRing
  @instances = {}

  constructor: () ->
    @currentIndex = -1
    @entries = []
    @limit = 500

  isEmpty: ->
    @entries.length == 0

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

  getCurrentEntry: ->
    if @entries.length == 0
      return null
    else
      @entries[@currentIndex]

  rotate: (n) ->
    return null if @entries.length == 0
    @currentIndex = (@currentIndex + n) % @entries.length
    @currentIndex += @entries.length if @currentIndex < 0
    return @entries[@currentIndex]
