module.exports =
class KillRing
  constructor: ->
    @currentIndex = -1
    @entries = []
    @limit = 500
    @lastSystemClip = undefined
    @global = true

  fork: ->
    fork = new KillRing
    fork.setEntries(@entries)
    fork.currentIndex = @currentIndex
    fork.lastSystemClip = @lastSystemClip
    fork.global = false
    fork

  isEmpty: ->
    @entries.length == 0

  reset: ->
    @entries = []

  getEntries: ->
    @entries.slice()

  setEntries: (entries) ->
    @entries = entries.slice()
    @currentIndex = @entries.length - 1
    this

  _pushSystemClipboard: (text) ->
    if global and atom.config.get("atomic-emacs.killToClipboard")
      atom.clipboard.write(text)
      @lastSystemClip = text

  _pullSystemClipboard: () ->
    if atom.config.get("atomic-emacs.yankFromClipboard")
      text = atom.clipboard.read()
      if (@lastSystemClip != text)
        @lastSystemClip = text
        @_doPush(text)

  _doPush: (text) ->
    @entries.push(text)
    if @entries.length > @limit
      @entries.shift()
    @currentIndex = @entries.length - 1

  push: (text) ->
    @_pullSystemClipboard()
    @_pushSystemClipboard(text)
    @_doPush(text)

  append: (text) ->
    @_pullSystemClipboard()
    if @entries.length == 0
      @push(text)
    else
      index = @entries.length - 1
      newText = @entries[index] + text
      @_pushSystemClipboard(newText)
      @entries[index] = newText
      @currentIndex = @entries.length - 1

  prepend: (text) ->
    @_pullSystemClipboard()
    if @entries.length == 0
      @push(text)
    else
      index = @entries.length - 1
      newText = "#{text}#{@entries[index]}"
      @_pushSystemClipboard(newText)
      @entries[index] = newText
      @currentIndex = @entries.length - 1

  replace: (text) ->
    @_pullSystemClipboard()
    if @entries.length == 0
      @push(text)
    else
      @_pushSystemClipboard(text)
      index = @entries.length - 1
      @entries[index] = text
      @currentIndex = @entries.length - 1

  getCurrentEntry: ->
    @_pullSystemClipboard()
    if @entries.length == 0
      return null
    else
      @entries[@currentIndex]

  rotate: (n) ->
    @_pullSystemClipboard()
    return null if @entries.length == 0
    @currentIndex = (@currentIndex + n) % @entries.length
    @currentIndex += @entries.length if @currentIndex < 0
    return @entries[@currentIndex]

  @global = new KillRing
