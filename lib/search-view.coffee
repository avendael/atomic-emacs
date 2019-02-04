{TextEditor} = require 'atom'

module.exports =
class SearchView
  constructor: (@searchManager) ->
    @searchEditor = new TextEditor(mini: true)
    @searchEditor.element.setAttribute('id', 'atomic_emacs_search_editor')
    @searchEditor.onDidChange => @_runQuery() if @active

    @element = document.createElement('div')
    @element.classList.add('atomic-emacs', 'search')
    @element.innerHTML = """
      <div class="row editor">
        <label for="atomic_emacs_search_editor">Search:</label>
        <div class="SEARCH-EDITOR"></div>
        <button class="case-sensitivity"></button>
        <button class="is-reg-exp"></button>
      </div>
    """

    @label = @element.querySelector('label')
    @caseSensitivityButton = @element.querySelector('.case-sensitivity')
    @isRegExpButton = @element.querySelector('.is-reg-exp')

    placeholder = @element.querySelector('.SEARCH-EDITOR')
    placeholder.parentNode.replaceChild(@searchEditor.element, placeholder)

    @wrapIcon = document.createElement('div')
    @wrapIcon.classList.add('atomic-emacs', 'search-wrap-icon')

    @caseSensitive = false
    @_updateCaseSensitivityButton()
    @caseSensitivityButton.addEventListener 'click', (event) =>
      @toggleCaseSensitivity()

    @isRegExp = false
    @_updateIsRegExpButton()
    @isRegExpButton.addEventListener 'click', (event) =>
      @toggleIsRegExp()

    @panel = atom.workspace.addBottomPanel
      item: this
      visible: false

    @active = false
    @lastQuery = null

    @workspaceFocusInListener = (event) =>
      if @active and event.target.closest('.atomic-emacs.search') == null
        @exit()

  destroy: ->
    @searchEditor.destroy()
    @panel.destroy()

  start: ({@direction}) ->
    @_activate()
    @searchEditor.element.focus()

  exit: ->
    @_deactivate()
    @searchManager.exited()

  cancel: ->
    @_deactivate()
    @searchManager.canceled()

  isEmpty: ->
    @searchEditor.isEmpty()

  repeatLastQuery: (@direction) ->
    if @lastQuery
      @searchEditor.setText(@lastQuery)

  toggleCaseSensitivity: ->
    @caseSensitive = not @caseSensitive
    @_updateCaseSensitivityButton()
    @_runQuery() if @active

  toggleIsRegExp: ->
    @isRegExp = not @isRegExp
    @_updateIsRegExpButton()
    @_runQuery() if @active

  append: (text) ->
    @searchEditor.setText(@searchEditor.getText() + text)

  resetProgress: ->
    @total = 0
    @isScanning = true
    @currentIndex = null
    @label.innerText = "Search:"

  setProgress: (currentIndex, total) ->
    @currentIndex = currentIndex
    @total = total
    @_updateLabel()

  scanningDone: ->
    @isScanning = false
    @_updateLabel()

  showWrapIcon: (direction) ->
    # Adapted from find-and-replace's FindView#showWrapIcon().
    activePaneItem = atom.workspace.getCenter().getActivePaneItem()
    return if not activePaneItem?

    paneItemView = atom.views.getView(activePaneItem)
    return if not paneItemView?

    paneItemView.parentNode.appendChild(@wrapIcon)
    [icon, otherIcon] =
      if direction == 'forward'
        ['icon-move-up', 'icon-move-down']
      else
        ['icon-move-down', 'icon-move-up']
    @wrapIcon.classList.remove(otherIcon)
    @wrapIcon.classList.add(icon, 'visible')
    clearTimeout(@wrapTimeout)
    @wrapTimeout = setTimeout((=>
      @wrapIcon.classList.remove('visible')
      paneItemView.parentNode.removeChild(@wrapIcon)
    ), 500)

  _activate: ->
    @active = true
    @resetProgress()
    @panel.show()

    workspaceView = atom.views.getView(atom.workspace)
    workspaceView.classList.add('atomic-emacs-search-visible')
    workspaceView.addEventListener 'focusin', @workspaceFocusInListener

  _deactivate: ->
    @active = false
    @searchEditor.setText('')
    @panel.hide()
    workspaceView = atom.views.getView(atom.workspace)
    workspaceView.classList.remove('atomic-emacs-search-visible')
    workspaceView.removeEventListener 'focusin', @workspaceFocusInListener

  _runQuery: ->
    text = @searchEditor.getText()
    @lastQuery = text
    @searchManager.changed(text, {@caseSensitive, @isRegExp, @direction})

  _updateLabel: ->
    if @total == 0 and not @isScanning
      @label.innerHTML = 'No&nbsp;matches'
    else
      currentIndex = @currentIndex ? '?'
      total = @total ? '?'
      ellipsis = if @isScanning then '...' else ''
      @label.innerHTML = "#{currentIndex}&nbsp;of&nbsp;#{total}#{ellipsis}"

  _updateCaseSensitivityButton: ->
    @caseSensitivityButton.textContent = if @caseSensitive then 'Case: on' else 'Case: off'

  _updateIsRegExpButton: ->
    @isRegExpButton.textContent = if @isRegExp then 'Reg Exp: on' else 'Reg Exp: off'
