{TextEditor} = require 'atom'

module.exports =
class SearchView
  constructor: (@search) ->
    label = document.createElement('label')
    label.textContent = 'Search: '
    label.setAttribute('for', 'atomic-emacs-search-editor')

    @searchEditor = new TextEditor(mini: true)
    @searchEditor.element.addEventListener 'blur', => @exit() if @active
    @searchEditor.element.setAttribute('id', 'atomic-emacs-search-editor')
    @searchEditor.onDidChange =>
      if @active
        text = @searchEditor.getText()
        @lastQuery = text
        @search.changed(text)

    @element = document.createElement('div')
    @element.classList.add('atomic-emacs', 'search')
    @element.appendChild(label)
    @element.appendChild(@searchEditor.element)

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

  _activate: ->
    @active = true
    @panel.show()
    atom.views.getView(atom.workspace).classList.
      add('atomic-emacs-search-visible')

  _deactivate: ->
    @active = false
    @searchEditor.setText('')
    @panel.hide()
    atom.views.getView(atom.workspace).classList.
      remove('atomic-emacs-search-visible')
