## 0.3.1
* Fixed a bug where the editor is not being accessible inside transact.

## 0.3.0
* Make atomic-emacs work with React.

## 0.2.13
* Partial fix for Uncaught TypeError, issue #17

## 0.2.12
* previous-line and next-line now works for the command palette.
* tab now works as expected when the mark is active.

## 0.2.11
* Because of a tagging mishap, what should have been 0.2.9 became 0.2.11
* Tags that weren't deleted were deleted, but I forgot to update package.json. Hence 0.2.11. Bummer.

## 0.2.9
* Arrow keys should now work properly with set-mark.
* ctrl-n and ctrl-p should now work as expected in fuzzy-finder.
* alt-w now uses the new mark deactivate API.

## 0.2.8
* M-q bound to reflow-paragraph.
* Movement by words are now more emacs-like.

## 0.2.7
* Mark improvements.

## 0.2.6
* Added movement by paragraph with marks support. Not yet 100% emacs compatible.

## 0.2.5
* Added alt-t as transpose-words.
* Improved transpose-lines. Indents are now included in the transposed lines.
* New API for cursors.

## 0.2.4
* Set mark will now retain selection when moving by words.
* Added the recenter-top-bottom command.
* Added the just-one-space command.
* Added the delete-horizontal-space command.

## 0.2.3
* ctrl-v and alt-v will now retain the mark if active.
* changed binding of alt-/ from `autocomplete:attach` to `autocomplete:toggle`.
* Bind ctrl-s and ctrl-r to find next/prev when in `.find-and-replace`.

## 0.2.2
* Fixed a bug where the next and previous line commands cause a crash when used in the file finder without an editor opened.
* Moved some keybindings to `.body` so that they can be used in other views, ie. settings view.

## 0.2.1

* Fixed a bug where the selection can only move in the y-axis.
* Improved set-mark. It will now retain the selection on most of the current motion commands. Still have to figure out how to make this work with ctrl-v and alt-v.
* ctrl-g will now cancel the selection.

## 0.2.0

* Added marks to select an arbitrary group of text. This should be mapped by the user because the core ctrl-space mapping can't be overriden by this package.
* Added transpose characters.
* Added an emacs style copy mapped to alt-w.
* Added alt-; mapping for toggling line comments.
* The mark's head and tail can be swapped with ctrl-x ctrl-x.
* Transposing lines now make use of the new transactions API.

## 0.1.1

* Rebound some more keys.
* Ctrl-g will now attempt to cancel an action. Works most of the time except for the editor, because the core Go To Line keymap which can't be overridden it seems.

## 0.1.0

* Initial Release. Lots of things missing.
