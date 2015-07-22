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
    result = null
    @editor.backwardsScanInBufferRange regExp, [BOB, @cursor.getBufferPosition()], (hit) ->
      result = hit.range
    result

  # Look for the next occurrence of the given regexp.
  #
  # Return a Range if found, null otherwise. This does not move the cursor.
  locateForward: (regExp) ->
    result = null
    eof = @editor.getEofBufferPosition()
    @editor.scanInBufferRange regExp, [@cursor.getBufferPosition(), eof], (hit) ->
      result = hit.range
    result

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

  # Return the character after the cursor.
  nextCharacter: ->
    position = @cursor.getBufferPosition()
    lineLength = @editor.lineTextForBufferRow(position.row).length
    if position.column == lineLength
      if position.row == @editor.getLastBufferRow()
        null
      else
        @editor.getTextInBufferRange([position, [position.row + 1, 0]])
    else
      @editor.getTextInBufferRange([position, position.translate([0, 1])])

  # Return the character before the cursor.
  previousCharacter: ->
    position = @cursor.getBufferPosition()
    if position.column == 0
      if position.row == 0
        null
      else
        column = @editor.lineTextForBufferRow(position.row - 1).length
        @editor.getTextInBufferRange([[position.row - 1, column], position])
    else
      @editor.getTextInBufferRange([position.translate([0, -1]), position])

  # Skip to the end of the current or next symbolic expression.
  skipSexpForward: ->
    @skipForwardUntil(/[\w()[\]{}'"]/i)
    character = @nextCharacter()
    if OPENERS.hasOwnProperty(character) or CLOSERS.hasOwnProperty(character)
      stack = []
      quotes = 0
      here = @cursor.getBufferPosition()
      eof = @editor.getEofBufferPosition()
      re = /[^()[\]{}"'`\\]+|\\.|[()[\]{}"'`]/g
      @editor.scanInBufferRange re, [here, eof], (hit) =>
        if hit.matchText == stack[stack.length - 1]
          stack.pop()
          if stack.length == 0
            @cursor.setBufferPosition(hit.range.end)
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
    else
      @skipForwardUntil(/\W/i)

  # Skip to the beginning of the current or previous symbolic expression.
  skipSexpBackward: ->
    @skipBackwardUntil(/[\w()[\]{}'"]/i)
    character = @previousCharacter()
    if OPENERS.hasOwnProperty(character) or CLOSERS.hasOwnProperty(character)
      stack = []
      quotes = 0
      here = @cursor.getBufferPosition()
      bof = [0, 0]
      re = /[^()[\]{}"'`\\]+|\\.|[()[\]{}"'`]/g
      @editor.backwardsScanInBufferRange re, [bof, here], (hit) =>
        if hit.matchText == stack[stack.length - 1]
          stack.pop()
          if stack.length == 0
            @cursor.setBufferPosition(hit.range.start)
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
    else
      @skipBackwardUntil(/\W/i)

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
