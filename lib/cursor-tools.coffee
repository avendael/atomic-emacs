Mark = require './mark'

OPENERS = {'(': ')', '[': ']', '{': '}', '\'': '\'', '"': '"', '`': '`'}
CLOSERS = {')': '(', ']': '[', '}': '{', '\'': '\'', '"': '"', '`': '`'}

# Wraps a Cursor to provide a nicer API for common operations.
class CursorTools
  constructor: (@cursor) ->
    @editor = @cursor.editor

  # Look for the previous occurrence of the given regexp.
  #
  # Return a Range if found, null otherwise. This does not move the cursor.
  locateBackward: (regExp) ->
    @_locateBackwardFrom(@cursor.getBufferPosition(), regExp)

  # Look for the next occurrence of the given regexp.
  #
  # Return a Range if found, null otherwise. This does not move the cursor.
  locateForward: (regExp) ->
    @_locateForwardFrom(@cursor.getBufferPosition(), regExp)

  # Look for the previous word character.
  #
  # Return a Range if found, null otherwise. This does not move the cursor.
  locateWordCharacterBackward: ->
    @locateBackward @_getWordCharacterRegExp()

  # Look for the next word character.
  #
  # Return a Range if found, null otherwise. This does not move the cursor.
  locateWordCharacterForward: ->
    @locateForward @_getWordCharacterRegExp()

  # Look for the previous nonword character.
  #
  # Return a Range if found, null otherwise. This does not move the cursor.
  locateNonWordCharacterBackward: ->
    @locateBackward @_getNonWordCharacterRegExp()

  # Look for the next nonword character.
  #
  # Return a Range if found, null otherwise. This does not move the cursor.
  locateNonWordCharacterForward: ->
    @locateForward @_getNonWordCharacterRegExp()

  # Move to the start of the previous occurrence of the given regexp.
  #
  # Return true if found, false otherwise.
  goToMatchStartBackward: (regExp) ->
    @_goTo @locateBackward(regExp)?.start

  # Move to the start of the next occurrence of the given regexp.
  #
  # Return true if found, false otherwise.
  goToMatchStartForward: (regExp) ->
    @_goTo @locateForward(regExp)?.start

  # Move to the end of the previous occurrence of the given regexp.
  #
  # Return true if found, false otherwise.
  goToMatchEndBackward: (regExp) ->
    @_goTo @locateBackward(regExp)?.end

  # Move to the end of the next occurrence of the given regexp.
  #
  # Return true if found, false otherwise.
  goToMatchEndForward: (regExp) ->
    @_goTo @locateForward(regExp)?.end

  # Skip backwards over the given characters.
  #
  # If the end of the buffer is reached, remain there.
  skipCharactersBackward: (characters) ->
    regexp = new RegExp("[^#{escapeRegExp(characters)}]")
    @skipBackwardUntil(regexp)

  # Skip forwards over the given characters.
  #
  # If the end of the buffer is reached, remain there.
  skipCharactersForward: (characters) ->
    regexp = new RegExp("[^#{escapeRegExp(characters)}]")
    @skipForwardUntil(regexp)

  # Skip backwards over any word characters.
  #
  # If the beginning of the buffer is reached, remain there.
  skipWordCharactersBackward: ->
    @skipBackwardUntil(@_getNonWordCharacterRegExp())

  # Skip forwards over any word characters.
  #
  # If the end of the buffer is reached, remain there.
  skipWordCharactersForward: ->
    @skipForwardUntil(@_getNonWordCharacterRegExp())

  # Skip backwards over any non-word characters.
  #
  # If the beginning of the buffer is reached, remain there.
  skipNonWordCharactersBackward: ->
    @skipBackwardUntil(@_getWordCharacterRegExp())

  # Skip forwards over any non-word characters.
  #
  # If the end of the buffer is reached, remain there.
  skipNonWordCharactersForward: ->
    @skipForwardUntil(@_getWordCharacterRegExp())

  # Skip over characters until the previous occurrence of the given regexp.
  #
  # If the beginning of the buffer is reached, remain there.
  skipBackwardUntil: (regexp) ->
    if not @goToMatchEndBackward(regexp)
      @_goTo BOB

  # Skip over characters until the next occurrence of the given regexp.
  #
  # If the end of the buffer is reached, remain there.
  skipForwardUntil: (regexp) ->
    if not @goToMatchStartForward(regexp)
      @_goTo @editor.getEofBufferPosition()

  _nextCharacterFrom: (position) ->
    lineLength = @editor.lineTextForBufferRow(position.row).length
    if position.column == lineLength
      if position.row == @editor.getLastBufferRow()
        null
      else
        @editor.getTextInBufferRange([position, [position.row + 1, 0]])
    else
      @editor.getTextInBufferRange([position, position.translate([0, 1])])

  _previousCharacterFrom: (position) ->
    if position.column == 0
      if position.row == 0
        null
      else
        column = @editor.lineTextForBufferRow(position.row - 1).length
        @editor.getTextInBufferRange([[position.row - 1, column], position])
    else
      @editor.getTextInBufferRange([position.translate([0, -1]), position])

  nextCharacter: ->
    @_nextCharacterFrom(@cursor.getBufferPosition())

  previousCharacter: ->
    @_nextCharacterFrom(@cursor.getBufferPosition())

  # Skip to the end of the current or next symbolic expression.
  skipSexpForward: ->
    point = @cursor.getBufferPosition()
    target = @_sexpForwardFrom(point)
    @cursor.setBufferPosition(target)

  # Skip to the beginning of the current or previous symbolic expression.
  skipSexpBackward: ->
    point = @cursor.getBufferPosition()
    target = @_sexpBackwardFrom(point)
    @cursor.setBufferPosition(target)

  # Add the next sexp to the cursor's selection. Activate if necessary.
  markSexp: ->
    mark = Mark.for(@cursor)
    mark.activate() unless mark.isActive()
    range = mark.getSelectionRange()
    newTail = @_sexpForwardFrom(range.end)
    mark.setSelectionRange(range.start, newTail)

  _sexpForwardFrom: (point) ->
    eob = @editor.getEofBufferPosition()
    point = @_locateForwardFrom(point, /[\w()[\]{}'"]/i)?.start or eob
    character = @_nextCharacterFrom(point)
    if OPENERS.hasOwnProperty(character) or CLOSERS.hasOwnProperty(character)
      result = null
      stack = []
      quotes = 0
      eof = @editor.getEofBufferPosition()
      re = /[^()[\]{}"'`\\]+|\\.|[()[\]{}"'`]/g
      @editor.scanInBufferRange re, [point, eof], (hit) =>
        if hit.matchText == stack[stack.length - 1]
          stack.pop()
          if stack.length == 0
            result = hit.range.end
            hit.stop()
          else if /^["'`]$/.test(hit.matchText)
            quotes -= 1
        else if (closer = OPENERS[hit.matchText])
          unless /^["'`]$/.test(closer) and quotes > 0
            stack.push(closer)
            quotes += 1 if /^["'`]$/.test(closer)
        else if CLOSERS[hit.matchText]
          if stack.length == 0
            hit.stop()
      result or point
    else
      @_locateForwardFrom(point, /\W/i)?.start or eob

  _sexpBackwardFrom: (point) ->
    point = @_locateBackwardFrom(point, /[\w()[\]{}'"]/i)?.end or BOB
    character = @_previousCharacterFrom(point)
    if OPENERS.hasOwnProperty(character) or CLOSERS.hasOwnProperty(character)
      result = null
      stack = []
      quotes = 0
      re = /[^()[\]{}"'`\\]+|\\.|[()[\]{}"'`]/g
      @editor.backwardsScanInBufferRange re, [BOB, point], (hit) =>
        if hit.matchText == stack[stack.length - 1]
          stack.pop()
          if stack.length == 0
            result = hit.range.start
            hit.stop()
          else if /^["'`]$/.test(hit.matchText)
            quotes -= 1
        else if (opener = CLOSERS[hit.matchText])
          unless /^["'`]$/.test(opener) and quotes > 0
            stack.push(opener)
            quotes += 1 if /^["'`]$/.test(opener)
        else if OPENERS[hit.matchText]
          if stack.length == 0
            hit.stop()
      result or point
    else
      @_locateBackwardFrom(point, /\W/i)?.end or BOB

  # Delete and return the word at the cursor.
  #
  # If not in or at the start or end of a word, return the empty string and
  # leave the buffer unmodified.
  extractWord: (cursorTools) ->
    @skipWordCharactersBackward()
    range = @locateNonWordCharacterForward()
    wordEnd = if range then range.start else @editor.getEofBufferPosition()
    wordRange = [@cursor.getBufferPosition(), wordEnd]
    word = @editor.getTextInBufferRange(wordRange)
    @editor.setTextInBufferRange(wordRange, '')
    word

  _locateBackwardFrom: (point, regExp) ->
    result = null
    @editor.backwardsScanInBufferRange regExp, [BOB, point], (hit) ->
      result = hit.range
    result

  _locateForwardFrom: (point, regExp) ->
    result = null
    eof = @editor.getEofBufferPosition()
    @editor.scanInBufferRange regExp, [point, eof], (hit) ->
      result = hit.range
    result

  _getWordCharacterRegExp: ->
    nonWordCharacters = atom.config.get('editor.nonWordCharacters')
    new RegExp('[^\\s' + escapeRegExp(nonWordCharacters) + ']')

  _getNonWordCharacterRegExp: ->
    nonWordCharacters = atom.config.get('editor.nonWordCharacters')
    new RegExp('[\\s' + escapeRegExp(nonWordCharacters) + ']')

  _goTo: (point) ->
    if point
      @cursor.setBufferPosition(point)
      true
    else
      false

# Stolen from underscore-plus, which we can't seem to require() from a package
# without depending on a separate copy of the whole library.
escapeRegExp = (string) ->
  if string
    string.replace(/[-\/\\^$*+?.()|[\]{}]/g, '\\$&')
  else
    ''

BOB = {row: 0, column: 0}

module.exports = CursorTools
