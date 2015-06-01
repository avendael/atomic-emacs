{CompositeDisposable} = require 'atom'
AtomicEmacs = require './atomic-emacs'

module.exports =

  activate: ->
    @subscriptions = new CompositeDisposable
    @atomicEmacsObjects = new WeakMap
    @subscriptions.add atom.workspace.observeTextEditors (editor) =>
      return if editor.mini
      unless @atomicEmacsObjects.get(editor)
        @atomicEmacsObjects.set(editor, new AtomicEmacs(editor))

  deactivate: ->
    @subscriptions?.dispose()
    @subscriptions = null

    for editor in atom.workspace.getTextEditors()
      @atomicEmacsObjects.get(editor)?.destroy()
    @atomicEmacsObjects = null
