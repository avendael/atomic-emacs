## 0.11.0 (2017-05-15)

* Add option to have clipboard copies appended to kill ring. [Marty Gentillon]
* Killing with multiple cursors also appends to global kill ring. [Marty
  Gentillon]

## 0.10.0 (2017-02-27)

* Add transpose-sexps (ctrl-alt-t).
* Setting to make built-in cut & copy commands use the kill ring.
* Fix error when closing a tab with the mark active.
* Fix some bindings being shadowed by Atom Core on Linux & Windows.
* Fix commands potentially firing twice after upgrading Atomic Emacs.
* Address deprecation warnings in recent Atom versions.

## 0.9.2 (2016-06-18)

* Fix scroll-{up,down} in an empty editor.

## 0.9.1 (2016-03-26)

* New bindings:
  * ctrl-x ctrl-c: application:quit [Josh Meyer]
  * ctrl-x u: core:undo [Josh Meyer]
* copy-region-as-kill writes to clipboard, like other kill commands. [Yuichi
  Tanikawa]
* Fix selection disappearing when moving past the ends of the buffer.
* Added note to readme about key binding collisions on Windows.

## 0.9.0 (2016-01-02)

* Updated readme.
* Killing and yanking commands, multi-cursor aware. See readme for details.
* transpose-{chars,words,lines} now works with multiple cursors.
* Add "alt-g alt-g" as an alias for go-to-line:toggle.
* Fix delete-indentation.
* Fix issue with selection jumping erratically when moving after a mark-sexp.
* open-line no longer jumps to the start of the line.
* Fix undo behavior of just-one-space, {{up,down}case,capitalize}-word-or-region.

## 0.8.0 (2015-12-03)
* C-v, M-v now consistently moves half a screen up/down.
* C-l now cycles through middle-top-bottom, like Emacs' default.

## 0.7.4 (2015-10-05)
* C-g now cancels auto-complete and multiple cursors, like escape.

## 0.7.3 (2015-09-05)
* Fix crash on latest Atom when clearing the region.

## 0.7.2 (2015-07-19)
* Remove deprecated .editor selector
* Fix paragraph movement commands
* Fix upcasing & downcasing, add capitalizing, work on words or selections.
* C-x 1 now closes other panes, not other tabs.
* Add start/end of line key bindings for Windows
* Don't override ctrl-a on win32.
* Bind "ctrl-k ctrl-k" to cut-to-end-of-line on win32.

## 0.7.1 (2015-06-20)
* Remove keybindings that don't make sense in mini-editors
* Replace autocomplete keybindings with autocomplete-plus
* Make alt-{left,right} the same as alt-{b,f}.

## 0.7.0 (2015-06-10)
* Fix behavior of ctrl-a and alt-m
* Fix behavior of keybindings when autocomplete menu is active
* Make commands work in mini editors
* Fix deprecation in delete-indentation
* Fix transpose-chars
* Add missing activation commands

## 0.6.0 (2015-06-01)
* Remove usage of deprecated APIs
* Add delete indentation

## 0.5.1 (2015-04-28)
* Fix remove mark

## 0.5.0 (2015-04-08)
* Move out of using deprecated APIs

## 0.4.2 (2015-04-02)
* Do not override keymappings when autocomplete is active

## 0.4.1 (2015-03-16)
* Add ctrl-a and ctrl-e keybindings for Linux

## 0.4.0 (2015-01-27)
* Added a setting to use core navigation keys instead of the atomic-emacs versions

## 0.3.7 (2015-01-20)
* Bind `next-paragraph` and `previous-paragraph` to `M-}` and `M-{` respectively.

## 0.3.6 (2015-01-03)
* Fix `next-line` and `previous-line` skipping bug.

## 0.3.5 (2014-11-30)
* Bind ctrl-k to `editor:cut-to-end-of-line`

## 0.3.4 (2014-11-23)
* Rename `autoflow:reflow-paragraph` to `autoflow:reflow-selection` because of upstream change.
* Bind ctrl-k to `editor:delete-to-end-of-line`

## 0.3.3 (2014-09-24)
* Fixed for atom update 0.130.0.

## 0.3.2 (2014-07-27)
* Fixed the recenter command.
* Fixed the test suite.
* Enabled travis ci.

## 0.3.1 (2014-07-13)
* Fixed a bug where the editor is not being accessible inside transact.

## 0.3.0 (2014-07-12)
* Make atomic-emacs work with React.

## 0.2.13 (2014-06-18)
* Partial fix for Uncaught TypeError, issue #17

## 0.2.12 (2014-05-27)
* previous-line and next-line now works for the command palette.
* tab now works as expected when the mark is active.

## 0.2.11 (2014-04-11)
* Because of a tagging mishap, what should have been 0.2.9 became 0.2.11
* Tags that weren't deleted were deleted, but I forgot to update package.json. Hence 0.2.11. Bummer.

## 0.2.9 (2014-04-11)
* Arrow keys should now work properly with set-mark.
* ctrl-n and ctrl-p should now work as expected in fuzzy-finder.
* alt-w now uses the new mark deactivate API.

## 0.2.8 (2014-04-08)
* M-q bound to reflow-paragraph.
* Movement by words are now more emacs-like.

## 0.2.7 (2014-04-01)
* Mark improvements.

## 0.2.6 (2014-03-20)
* Added movement by paragraph with marks support. Not yet 100% emacs compatible.

## 0.2.5 (2014-03-18)
* Added alt-t as transpose-words.
* Improved transpose-lines. Indents are now included in the transposed lines.
* New API for cursors.

## 0.2.4 (2014-03-13)
* Set mark will now retain selection when moving by words.
* Added the recenter-top-bottom command.
* Added the just-one-space command.
* Added the delete-horizontal-space command.

## 0.2.3 (2014-03-08)
* ctrl-v and alt-v will now retain the mark if active.
* changed binding of alt-/ from `autocomplete:attach` to `autocomplete:toggle`.
* Bind ctrl-s and ctrl-r to find next/prev when in `.find-and-replace`.

## 0.2.2 (2014-03-08)
* Fixed a bug where the next and previous line commands cause a crash when used in the file finder without an editor opened.
* Moved some keybindings to `.body` so that they can be used in other views, ie. settings view.

## 0.2.1 (2014-03-04)

* Fixed a bug where the selection can only move in the y-axis.
* Improved set-mark. It will now retain the selection on most of the current motion commands. Still have to figure out how to make this work with ctrl-v and alt-v.
* ctrl-g will now cancel the selection.

## 0.2.0 (2014-03-01)

* Added marks to select an arbitrary group of text. This should be mapped by the user because the core ctrl-space mapping can't be overriden by this package.
* Added transpose characters.
* Added an emacs style copy mapped to alt-w.
* Added alt-; mapping for toggling line comments.
* The mark's head and tail can be swapped with ctrl-x ctrl-x.
* Transposing lines now make use of the new transactions API.

## 0.1.1 (2014-02-28)

* Rebound some more keys.
* Ctrl-g will now attempt to cancel an action. Works most of the time except for the editor, because the core Go To Line keymap which can't be overridden it seems.

## 0.1.0 (2014-02-27)

* Initial Release. Lots of things missing.
