SearchView = require './search-view'

module.exports =
class Search
  constructor: ->
    @panel = null
    @searchEditor = null
    @emacsEditor = null

  start: (@emacsEditor, @direction) ->
    @searchView ?= new SearchView(this)
    @searchView.start()

  exit: ->
    @searchView.exit()
    @emacsEditor.editor.element.focus()

  cancel: ->
    @searchView.cancel()
    @emacsEditor.editor.element.focus()

  changed: (text) ->
    console.log "TODO: search changed: #{text}"

  exited: ->
    console.log 'TODO: search exited'

  canceled: ->
    console.log 'TODO: search canceled'
