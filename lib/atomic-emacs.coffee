{CompositeDisposable} = require 'atom'
EmacsCursor = require './emacs-cursor'
EmacsEditor = require './emacs-editor'
KillRing = require './kill-ring'
Mark = require './mark'
State = require './state'

class AtomicEmacs
  constructor: ->
    @state = new State

  afterCommand: (event) ->
    Mark.deactivatePending()

    if @state.yankComplete()
      emacsEditor = @editor(event)
      for emacsCursor in emacsEditor.getEmacsCursors()
        emacsCursor.yankComplete()

    @state.afterCommand(event)

  editor: (event) ->
    # Get editor from the event if possible so we can target mini-editors.
    if event.target?.getModel
      editor = event.target.getModel()
    else
      editor = atom.workspace.getActiveTextEditor()
    EmacsEditor.for(editor, @state)

  closeOtherPanes: (event) ->
    activePane = atom.workspace.getActivePane()
    return if not activePane
    for pane in atom.workspace.getPanes()
      unless pane is activePane
        pane.close()

module.exports =
  AtomicEmacs: AtomicEmacs
  Mark: Mark

  activate: ->
    atomicEmacs = new AtomicEmacs()
    document.getElementsByTagName('atom-workspace')[0]?.classList?.add('atomic-emacs')
    @disposable = new CompositeDisposable
    @disposable.add atom.commands.onDidDispatch (event) -> atomicEmacs.afterCommand(event)
    @disposable.add atom.commands.add 'atom-text-editor',
      # Navigation
      "atomic-emacs:backward-char": (event) -> atomicEmacs.editor(event).backwardChar()
      "atomic-emacs:forward-char": (event) -> atomicEmacs.editor(event).forwardChar()
      "atomic-emacs:backward-word": (event) -> atomicEmacs.editor(event).backwardWord()
      "atomic-emacs:forward-word": (event) -> atomicEmacs.editor(event).forwardWord()
      "atomic-emacs:backward-sexp": (event) -> atomicEmacs.editor(event).backwardSexp()
      "atomic-emacs:forward-sexp": (event) -> atomicEmacs.editor(event).forwardSexp()
      "atomic-emacs:previous-line": (event) -> atomicEmacs.editor(event).previousLine()
      "atomic-emacs:next-line": (event) -> atomicEmacs.editor(event).nextLine()
      "atomic-emacs:backward-paragraph": (event) -> atomicEmacs.editor(event).backwardParagraph()
      "atomic-emacs:forward-paragraph": (event) -> atomicEmacs.editor(event).forwardParagraph()
      "atomic-emacs:back-to-indentation": (event) -> atomicEmacs.editor(event).backToIndentation()

      # Killing & Yanking
      "atomic-emacs:backward-kill-word": (event) -> atomicEmacs.editor(event).backwardKillWord()
      "atomic-emacs:kill-word": (event) -> atomicEmacs.editor(event).killWord()
      "atomic-emacs:kill-line": (event) -> atomicEmacs.editor(event).killLine()
      "atomic-emacs:kill-region": (event) -> atomicEmacs.editor(event).killRegion()
      "atomic-emacs:copy-region-as-kill": (event) -> atomicEmacs.editor(event).copyRegionAsKill()
      "atomic-emacs:yank": (event) -> atomicEmacs.editor(event).yank()
      "atomic-emacs:yank-pop": (event) -> atomicEmacs.editor(event).yankPop()
      "atomic-emacs:yank-shift": (event) -> atomicEmacs.editor(event).yankShift()

      # Editing
      "atomic-emacs:delete-horizontal-space": (event) -> atomicEmacs.editor(event).deleteHorizontalSpace()
      "atomic-emacs:delete-indentation": (event) -> atomicEmacs.editor(event).deleteIndentation()
      "atomic-emacs:open-line": (event) -> atomicEmacs.editor(event).openLine()
      "atomic-emacs:just-one-space": (event) -> atomicEmacs.editor(event).justOneSpace()
      "atomic-emacs:transpose-chars": (event) -> atomicEmacs.editor(event).transposeChars()
      "atomic-emacs:transpose-lines": (event) -> atomicEmacs.editor(event).transposeLines()
      "atomic-emacs:transpose-words": (event) -> atomicEmacs.editor(event).transposeWords()
      "atomic-emacs:downcase-word-or-region": (event) -> atomicEmacs.editor(event).downcaseWordOrRegion()
      "atomic-emacs:upcase-word-or-region": (event) -> atomicEmacs.editor(event).upcaseWordOrRegion()
      "atomic-emacs:capitalize-word-or-region": (event) -> atomicEmacs.editor(event).capitalizeWordOrRegion()

      # Marking & Selecting
      "atomic-emacs:set-mark": (event) -> atomicEmacs.editor(event).setMark()
      "atomic-emacs:mark-sexp": (event) -> atomicEmacs.editor(event).markSexp()
      "atomic-emacs:mark-whole-buffer": (event) -> atomicEmacs.editor(event).markWholeBuffer()
      "atomic-emacs:exchange-point-and-mark": (event) -> atomicEmacs.editor(event).exchangePointAndMark()

      # Scrolling
      "atomic-emacs:recenter-top-bottom": (event) -> atomicEmacs.editor(event).recenterTopBottom()
      "atomic-emacs:scroll-down": (event) -> atomicEmacs.editor(event).scrollDown()
      "atomic-emacs:scroll-up": (event) -> atomicEmacs.editor(event).scrollUp()

      # UI
      "atomic-emacs:close-other-panes": (event) -> atomicEmacs.closeOtherPanes(event)
      "core:cancel": (event) -> atomicEmacs.editor(event).keyboardQuit()

  deactivate: ->
    document.getElementsByTagName('atom-workspace')[0]?.classList?.remove('atomic-emacs')
    @disposable?.dispose()
    @disposable = null
    KillRing.global.reset()
