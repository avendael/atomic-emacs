{CompositeDisposable} = require 'atom'
AtomicEmacs = require './atomic-emacs'
EmacsState = require './emacs-state'

module.exports =

  activate: ->
    @atomicEmacs = new AtomicEmacs()
    @subscriptions = new CompositeDisposable
    @emacsStates = new WeakMap
    @registerCommands()

    @subscriptions.add atom.workspace.observeTextEditors (editor) =>
      return if editor.mini
      unless @emacsStates.get(editor)
        emacsState = new EmacsState(editor)
        @emacsStates.set(editor, emacsState)

  registerCommands: ->
    @subscriptions.add atom.commands.add 'atom-text-editor',
      "atomic-emacs:backward-kill-word": (event) => @atomicEmacs.backwardKillWord(event)
      "atomic-emacs:backward-paragraph": (event) => @atomicEmacs.backwardParagraph(event)
      "atomic-emacs:backward-word": (event) => @atomicEmacs.backwardWord(event)
      "atomic-emacs:copy": (event) => @atomicEmacs.copy(event)
      "atomic-emacs:delete-horizontal-space": (event) => @atomicEmacs.deleteHorizontalSpace(event)
      "atomic-emacs:delete-indentation": @atomicEmacs.deleteIndentation
      "atomic-emacs:downcase-region": (event) => @atomicEmacs.downcaseRegion(event)
      "atomic-emacs:exchange-point-and-mark": (event) => @atomicEmacs.exchangePointAndMark(event)
      "atomic-emacs:forward-paragraph": (event) => @atomicEmacs.forwardParagraph(event)
      "atomic-emacs:forward-word": (event) => @atomicEmacs.forwardWord(event)
      "atomic-emacs:just-one-space": (event) => @atomicEmacs.justOneSpace(event)
      "atomic-emacs:kill-word": (event) => @atomicEmacs.killWord(event)
      "atomic-emacs:open-line": (event) => @atomicEmacs.openLine(event)
      "atomic-emacs:recenter-top-bottom": (event) => @atomicEmacs.recenterTopBottom(event)
      "atomic-emacs:set-mark": (event) => @atomicEmacs.setMark(event)
      "atomic-emacs:transpose-chars": (event) => @atomicEmacs.transposeChars(event)
      "atomic-emacs:transpose-lines": (event) => @atomicEmacs.transposeLines(event)
      "atomic-emacs:transpose-words": (event) => @atomicEmacs.transposeWords(event)
      "atomic-emacs:upcase-region": (event) => @atomicEmacs.upcaseRegion(event)
      "core:cancel": (event) => @atomicEmacs.keyboardQuit(event)

  deactivate: ->
    @subscriptions.dispose()
    @subscriptions = null
    atom.workspace.getTextEditors().forEach((editor) =>
      @emacsStates.get(editor)?.destroy()
    )
    @emacsStates = null
