{CompositeDisposable} = require 'atom'
EmacsCursor = require './emacs-cursor'
EmacsEditor = require './emacs-editor'
KillRing = require './kill-ring'
Mark = require './mark'
State = require './state'

beforeCommand = (event) ->
  State.beforeCommand(event)

afterCommand = (event) ->
  Mark.deactivatePending()

  if State.yankComplete()
    emacsEditor = getEditor(event)
    for emacsCursor in emacsEditor.getEmacsCursors()
      emacsCursor.yankComplete()

  State.afterCommand(event)

getEditor = (event) ->
  # Get editor from the event if possible so we can target mini-editors.
  editor = event.target?.getModel?() ? atom.workspace.getActiveTextEditor()
  EmacsEditor.for(editor)

closeOtherPanes = (event) ->
  activePane = atom.workspace.getActivePane()
  return if not activePane
  for pane in atom.workspace.getPanes()
    unless pane is activePane
      pane.close()

module.exports =
  EmacsCursor: EmacsCursor
  EmacsEditor: EmacsEditor
  KillRing: KillRing
  Mark: Mark
  State: State

  config:
    alwaysUseKillRing:
      type: 'boolean',
      default: false,
      title: 'Use kill ring for built-in copy & cut commands.'
    killToClipboard:
      type: 'boolean',
      default: true,
      title: 'Send kills to the system clipboard'
    yankFromClipboard:
      type: 'boolean',
      default: false,
      title: 'Yank changed text from the system clipboard'
    killWholeLine:
      type: 'boolean',
      default: false,
      title: 'Always Kill whole line.'

  activate: ->
    if @disposable
      console.log "atomic-emacs activated twice -- aborting"
      return

    State.initialize()
    document.getElementsByTagName('atom-workspace')[0]?.classList?.add('atomic-emacs')
    @disposable = new CompositeDisposable
    @disposable.add atom.commands.onWillDispatch (event) -> beforeCommand(event)
    @disposable.add atom.commands.onDidDispatch (event) -> afterCommand(event)
    @disposable.add atom.commands.add 'atom-text-editor',
      # Navigation
      "atomic-emacs:backward-char": (event) -> getEditor(event).backwardChar()
      "atomic-emacs:forward-char": (event) -> getEditor(event).forwardChar()
      "atomic-emacs:backward-word": (event) -> getEditor(event).backwardWord()
      "atomic-emacs:forward-word": (event) -> getEditor(event).forwardWord()
      "atomic-emacs:backward-sexp": (event) -> getEditor(event).backwardSexp()
      "atomic-emacs:forward-sexp": (event) -> getEditor(event).forwardSexp()
      "atomic-emacs:previous-line": (event) -> getEditor(event).previousLine()
      "atomic-emacs:next-line": (event) -> getEditor(event).nextLine()
      "atomic-emacs:backward-paragraph": (event) -> getEditor(event).backwardParagraph()
      "atomic-emacs:forward-paragraph": (event) -> getEditor(event).forwardParagraph()
      "atomic-emacs:back-to-indentation": (event) -> getEditor(event).backToIndentation()

      # Killing & Yanking
      "atomic-emacs:backward-kill-word": (event) -> getEditor(event).backwardKillWord()
      "atomic-emacs:kill-word": (event) -> getEditor(event).killWord()
      "atomic-emacs:kill-line": (event) -> getEditor(event).killLine()
      "atomic-emacs:kill-region": (event) -> getEditor(event).killRegion()
      "atomic-emacs:copy-region-as-kill": (event) -> getEditor(event).copyRegionAsKill()
      "atomic-emacs:append-next-kill": (event) -> State.killed()
      "atomic-emacs:yank": (event) -> getEditor(event).yank()
      "atomic-emacs:yank-pop": (event) -> getEditor(event).yankPop()
      "atomic-emacs:yank-shift": (event) -> getEditor(event).yankShift()
      "atomic-emacs:cut": (event) ->
        if atom.config.get('atomic-emacs.alwaysUseKillRing')
          getEditor(event).killRegion()
        else
          event.abortKeyBinding()
      "atomic-emacs:copy": (event) ->
        if atom.config.get('atomic-emacs.alwaysUseKillRing')
          getEditor(event).copyRegionAsKill()
        else
          event.abortKeyBinding()

      # Editing
      "atomic-emacs:delete-horizontal-space": (event) -> getEditor(event).deleteHorizontalSpace()
      "atomic-emacs:delete-indentation": (event) -> getEditor(event).deleteIndentation()
      "atomic-emacs:open-line": (event) -> getEditor(event).openLine()
      "atomic-emacs:just-one-space": (event) -> getEditor(event).justOneSpace()
      "atomic-emacs:transpose-chars": (event) -> getEditor(event).transposeChars()
      "atomic-emacs:transpose-lines": (event) -> getEditor(event).transposeLines()
      "atomic-emacs:transpose-sexps": (event) -> getEditor(event).transposeSexps()
      "atomic-emacs:transpose-words": (event) -> getEditor(event).transposeWords()
      "atomic-emacs:downcase-word-or-region": (event) -> getEditor(event).downcaseWordOrRegion()
      "atomic-emacs:upcase-word-or-region": (event) -> getEditor(event).upcaseWordOrRegion()
      "atomic-emacs:capitalize-word-or-region": (event) -> getEditor(event).capitalizeWordOrRegion()

      # Marking & Selecting
      "atomic-emacs:set-mark": (event) -> getEditor(event).setMark()
      "atomic-emacs:mark-sexp": (event) -> getEditor(event).markSexp()
      "atomic-emacs:mark-whole-buffer": (event) -> getEditor(event).markWholeBuffer()
      "atomic-emacs:exchange-point-and-mark": (event) -> getEditor(event).exchangePointAndMark()

      # Scrolling
      "atomic-emacs:recenter-top-bottom": (event) -> getEditor(event).recenterTopBottom()
      "atomic-emacs:scroll-down": (event) -> getEditor(event).scrollDown()
      "atomic-emacs:scroll-up": (event) -> getEditor(event).scrollUp()

      # UI
      "atomic-emacs:close-other-panes": (event) -> closeOtherPanes(event)
      "core:cancel": (event) -> getEditor(event).keyboardQuit()

  deactivate: ->
    document.getElementsByTagName('atom-workspace')[0]?.classList?.remove('atomic-emacs')
    @disposable?.dispose()
    @disposable = null
    KillRing.global.reset()
