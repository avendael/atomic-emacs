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

  horizontalSpaceRange: ->
    @skipCharactersBackward(' \t')
    start = @cursor.getBufferPosition()
    @skipCharactersForward(' \t')
    end = @cursor.getBufferPosition()
    [start, end]

  endLineIfNecessary: ->
    row = @cursor.getBufferPosition().row
    if row == @editor.getLineCount() - 1
      length = @cursor.getCurrentBufferLine().length
      @editor.setTextInBufferRange([[row, length], [row, length]], "\n")

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
