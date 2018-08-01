{Point, Range} = require 'atom'
State = require './state'

BOB = new Point(0, 0)

# Taken from the built-in find-and-replace package (escapeRegExp).
escapeForRegExp = (string) ->
  string.replace(/[\/\\^$*+?.()|[\]{}]/g, '\\$&')

getNonSymbolCharacterRegExp = ->
  nonWordCharacters = atom.config.get('editor.nonWordCharacters')
  if nonWordCharacters.includes('-')
    nonWordCharacters = nonWordCharacters.replace('-', '') + '-'
  nonWordCharacters = nonWordCharacters.replace('_', '')
  new RegExp('[\\s' + escapeForRegExp(nonWordCharacters) + ']')

endOfWordPositionFrom = (editor, point) ->
  eob = editor.getBuffer().getEndPosition()
  result = null
  editor.scanInBufferRange getNonSymbolCharacterRegExp(), [point, eob], (hit) ->
    result = hit
  if result? then result.range.start else eob

# A stage of the search for completions.
#
# This represents a single pass through a region of text, possibly backwards.
# The search for completions consists of a number of stages:
class Stage
  constructor: (@regExp, @editor, @range, @searchBackward, @getNextStage) ->

  scan: ->
    result = null
    if @searchBackward
      @editor.backwardsScanInBufferRange(@regExp, @range, (hit) =>
        endOfWordPosition = endOfWordPositionFrom(@editor, hit.range.end)
        result = @editor.getTextInBufferRange([hit.range.start, endOfWordPosition])
        @range = new Range(@range.start, hit.range.start)
        hit.stop()
      )
    else
      @editor.scanInBufferRange(@regExp, @range, (hit) =>
        endOfWordPosition = endOfWordPositionFrom(@editor, hit.range.end)
        result = @editor.getTextInBufferRange([hit.range.start, endOfWordPosition])
        @range = new Range(hit.range.end, @range.end)
        hit.stop()
      )

    if result?
      [@, result]
    else
      [@getNextStage?(), null]

module.exports =
class Completer
  constructor: (@emacsEditor, @emacsCursor) ->
    eob = @emacsEditor.editor.getBuffer().getEndPosition()
    prefixStart = @emacsCursor.locateBackward(getNonSymbolCharacterRegExp())?.end ? BOB
    prefixEnd = @emacsCursor.locateForward(getNonSymbolCharacterRegExp())?.start ? eob
    point = @emacsCursor.cursor.getBufferPosition()

    @_completions = []
    @currentIndex = null

    if prefixStart.isEqual(point)
      @_scanningDone = true
      return

    @_marker = @emacsEditor.editor.markBufferRange([prefixStart, point])
    @prefix = @emacsEditor.editor.getTextInBufferRange([prefixStart, point])

    backwardRange = new Range(BOB, prefixStart)
    forwardRange = new Range(prefixEnd, eob)

    regExp = new RegExp("\\b#{escapeForRegExp(@prefix)}")
    thisEditor = @emacsEditor.editor
    otherEditors = atom.workspace.getTextEditors().filter (editor) ->
      editor isnt thisEditor

    # Stages:
    #  * 1 backward search, from point to the beginning of buffer
    #  * 1 forward search, from point to the end of the buffer
    #  * N forward searches, of whole buffers, for each other open file
    @_stage = new Stage regExp, thisEditor, backwardRange, true, =>
      nextEditorStage = (index) =>
        if index < otherEditors.length - 1
          editor = otherEditors[index]
          range = new Range(BOB, editor.getBuffer().getEndPosition())
          => new Stage(regExp, editor, range, false, nextEditorStage(index + 1))
        else
          null
      new Stage regExp, thisEditor, forwardRange, false, nextEditorStage(0)

    # "native!" commands don't first on{Did,Will}Dispatch, so we need to listen
    # to editor changes that occur outside a command.
    @disposable = thisEditor.onDidChange =>
      if not State.isDuringCommand
        @emacsEditor.dabbrevDone()

    currentWord = @emacsEditor.editor.getTextInBufferRange([prefixStart, endOfWordPositionFrom(@emacsEditor.editor, point)])
    @_seen = new Set([currentWord])
    @_scanningDone = false
    @_loadNextCompletion()
    if @_completions.length > 0
      @select(0)

  select: (index) ->
    @currentIndex = index
    @emacsEditor.editor.setTextInBufferRange(@_marker.getBufferRange(), @_completions[index])

  next: ->
    # Bail if there are no completions.
    return if @currentIndex is null

    if @currentIndex == @_completions.length - 1
      @_loadNextCompletion()
    @select((@currentIndex + 1) % @_completions.length)

  previous: ->
    # Bail if there are no completions.
    return if @currentIndex is null

    if @currentIndex == 0
      # If we've been to the end and wrapped around, allow going back.
      if @_scanningDone and @_completions.length > 0
        @select(@_completions.length - 1)
    else
      @select(@currentIndex - 1)

  _loadNextCompletion: ->
    if @_scanningDone
      return null

    while @_stage?
      [@_stage, completion] = @_stage.scan()
      if completion? and not @_seen.has(completion)
        @_completions.push(completion)
        @_seen.add(completion)
        return null
    @_scanningDone = true
    null

  destroy: ->
    @disposable?.dispose()
