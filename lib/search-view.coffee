{TextEditor} = require 'atom'

module.exports =
class SearchView
  constructor: (@search) ->
    label = document.createElement('label')
    label.textContent = 'Search: '
    label.setAttribute('for', 'atomic-emacs-search-editor')

    @searchEditor = new TextEditor(mini: true)
    @searchEditor.element.addEventListener 'blur', => @exit() if @active
    @searchEditor.element.setAttribute('id', 'atomic_emacs_search_editor')
    @searchEditor.onDidChange =>
      if @active
        text = @searchEditor.getText()
        @lastQuery = text
        @search.changed(text)

    @element = document.createElement('div')
    @element.classList.add('atomic-emacs', 'search')
    @element.innerHTML = """
      <div class="row editor">
        <label for="atomic_emacs_search_editor">Search:</label>
        <div class="SEARCH-EDITOR"></div>
      </div>
      <div class="row">
        <p class="progress">
          Hit <span class="index">0</span> of <span class="total">0</span>
          <span class="scanning-indicator">[...]</span>
        </p>
        <p class="no-matches">No matches.</p>
      </div>
    """

    @scanningIndicator = @element.querySelector('.scanning-indicator')
    @indexElement = @element.querySelector('.index')
    @totalElement = @element.querySelector('.total')
    @progressElement = @element.querySelector('.progress')
    @noMatchesElement = @element.querySelector('.no-matches')

    placeholder = @element.querySelector('.SEARCH-EDITOR')
    placeholder.parentNode.replaceChild(@searchEditor.element, placeholder)

    @panel = atom.workspace.addModalPanel
      item: this
      visible: false

    @active = false
    @lastQuery = null

  start: ->
    @_activate()
    @searchEditor.element.focus()

  exit: ->
    @_deactivate()
    @search.exited()

  cancel: ->
    @_deactivate()
    @search.canceled()

  isEmpty: ->
    @searchEditor.isEmpty()

  repeatLastQuery: ->
    if @lastQuery
      @searchEditor.setText(@lastQuery)

  resetProgress: ->
    @total = 0
    @indexElement.textContent = '?'
    @totalElement.textContent = '?'
    @scanningIndicator.style.display = ''
    @progressElement.style.display = 'none'
    @noMatchesElement.style.display = 'none'

  setIndex: (value) ->
    @progressElement.style.display = ''
    @indexElement.textContent = value

  setTotal: (value) ->
    @total = value
    @totalElement.textContent = value

  scanningDone: ->
    @scanningIndicator.style.display = 'none'
    if @total == 0
      @progressElement.style.display = 'none'
      @noMatchesElement.style.display = ''

  _activate: ->
    @active = true
    @resetProgress()
    @panel.show()
    atom.views.getView(atom.workspace).classList.
      add('atomic-emacs-search-visible')

  _deactivate: ->
    @active = false
    @searchEditor.setText('')
    @panel.hide()
    atom.views.getView(atom.workspace).classList.
      remove('atomic-emacs-search-visible')
