## Atomic Emacs

An atomic implementation of emacs keybindings.
![Build Status](https://travis-ci.org/avendael/atomic-emacs.svg?branch=master)

### Important Note

I love emacs, but this package will never implement all of emacs' features. It only aims to
provide a reasonable set of default emacs keybindings so that emacs refugees might find themselves
at home.

OSX already provides emacs-like keybindings to Atom, and those are not reimplemented in this
package. This might, however, cause a problem later on when Atom becomes available at other
platforms. Once that time comes, I will gladly include those keybindings in this package.

### Current Status

It's super incomplete, very alpha stage. Basically, just these:

* 'ctrl-f': 'core:move-right'
* 'ctrl-b': 'core:move-left'
* 'ctrl-n': 'core:move-down'
* 'ctrl-p': 'core:move-up'
* 'ctrl-a': 'atomic-emacs:move-beginning-of-line'
* 'ctrl-e': 'atomic-emacs:move-end-of-line'
* 'ctrl-l': 'atomic-emacs:recenter-top-bottom'
* 'ctrl-g': 'core:cancel'
* 'ctrl-k': 'editor:cut-to-end-of-line'
* 'ctrl-y': 'core:paste'
* 'ctrl-w': 'atomic-emacs:kill-region'
* 'ctrl-v': 'core:page-down'
* 'ctrl-s': 'find-and-replace:show'
* 'ctrl-r': 'find-and-replace:show'
* 'ctrl-j': 'editor:newline'
* 'ctrl-/': 'core:undo'
* 'ctrl-o': 'atomic-emacs:open-line'
* 'ctrl-t': 'atomic-emacs:transpose-chars'
* 'ctrl-_': 'core:undo'
* 'ctrl-space': 'atomic-emacs:set-mark'
* 'ctrl-x ctrl-s': 'core:save'
* 'ctrl-x ctrl-u': 'atomic-emacs:upcase-region'
* 'ctrl-x ctrl-l': 'atomic-emacs:downcase-region'
* 'ctrl-x ctrl-t': 'atomic-emacs:transpose-lines'
* 'ctrl-x h': 'core:select-all'
* 'ctrl-x ctrl-x': 'atomic-emacs:exchange-point-and-mark'
* 'alt-f': 'atomic-emacs:forward-word'
* 'alt-b': 'atomic-emacs:backward-word'
* 'alt-q': 'autoflow:reflow-selection'
* 'atl-t': 'atomic-emacs:transpose-words'
* 'alt-w': 'atomic-emacs:copy'
* 'alt-;': 'editor:toggle-line-comments'
* 'alt-v': 'core:page-up'
* 'alt-<': 'core:move-to-top'
* 'alt->': 'core:move-to-bottom'
* 'alt-m': 'editor:move-to-first-character-of-line'
* 'alt-/': 'autocomplete:toggle'
* 'alt-.': 'symbols-view:toggle-file-symbols'
* 'alt-\\': 'atomic-emacs:delete-horizontal-space'
* 'alt-space': 'atomic-emacs:just-one-space'
* 'alt-{': 'atomic-emacs:backward-paragraph'
* 'alt-}': 'atomic-emacs:forward-paragraph'

### Future Work

Version 1.0.0 should be somewhat close to what [sublemacspro](https://github.com/grundprinzip/sublemacspro) currently has as of time of writing (03/04/14), and then improve further based on that. Next up are:

* Kill ring
* Macros
* Motion commands for other platforms (OSX has the basic emacs motion commands by default)

### Contributing

Yes please!
