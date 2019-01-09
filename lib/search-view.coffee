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
    @searchEditor.onDidChange => @search.changed(@searchEditor.getText())

    @element = document.createElement('div')
    @element.classList.add('atomic-emacs', 'search')
    @element.appendChild(label)
    @element.appendChild(@searchEditor.element)

    @panel = atom.workspace.addModalPanel
      item: this
      visible: false

    @active = false

  start: ->
    @searchEditor.selectAll()
    @panel.show()
    @searchEditor.element.focus()
    @active = true

  exit: ->
    @active = false
    @panel.hide()
    @search.exited()

  cancel: ->
    @active = false
    @panel.hide()
    @search.canceled()
