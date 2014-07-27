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

* 'ctrl-f': 'atomic-emacs:forward-char'
* 'ctrl-b': 'atomic-emacs:backward-char'
* 'ctrl-n': 'atomic-emacs:next-line'
* 'ctrl-p': 'atomic-emacs:previous-line'
* 'ctrl-a': 'atomic-emacs:move-beginning-of-line'
* 'ctrl-e': 'atomic-emacs:move-end-of-line'
* 'ctrl-l': 'atomic-emacs:recenter-top-bottom'
* 'ctrl-g': 'atomic-emacs:remove-mark'
* 'ctrl-y': 'core:paste'
* 'ctrl-w': 'atomic-emacs:kill-region'
* 'ctrl-v': 'atomic-emacs:scroll-up'
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
* 'ctrl-x h': 'atomic-emacs:mark-whole-buffer'
* 'ctrl-x ctrl-x': 'atomic-emacs:exchange-point-and-mark'
* 'alt-f': 'atomic-emacs:forward-word'
* 'alt-b': 'atomic-emacs:backward-word'
* 'alt-q': 'autoflow:reflow-paragraph'
* 'atl-t': 'atomic-emacs:transpose-words'
* 'alt-w': 'atomic-emacs:copy'
* 'alt-;': 'editor:toggle-line-comments'
* 'alt-v': 'atomic-emacs:scroll-down'
* 'alt-<': 'atomic-emacs:beginning-of-buffer'
* 'alt->': 'atomic-emacs:end-of-buffer'
* 'alt-m': 'atomic-emacs:back-to-indentation'
* 'alt-/': 'autocomplete:toggle'
* 'alt-.': 'symbols-view:toggle-file-symbols'
* 'alt-\\': 'atomic-emacs:delete-horizontal-space'
* 'alt-space': 'atomic-emacs:just-one-space'
* 'alt-[': 'atomic-emacs:backward-paragraph'
* 'alt-]': 'atomic-emacs:forward-paragraph'

#### Some things that might not work as expected

There is a set-marks command. However, the ctrl-space mapping is being used by atom-core, and this package cannot override the core mappings. To use this command, the user must include the following lines in the user's keymap.cson (accessed through menu Atom -> Open Your Keymap):

```
'.editor':
  'ctrl-space': 'atomic-emacs:set-mark'
```

There is also a known issue that suddenly borks the keybindings. Please check issue [#17](https://github.com/avendael/atomic-emacs/issues/17) for the workaround.

### Future Work

Version 1.0.0 should be somewhat close to what [sublemacspro](https://github.com/grundprinzip/sublemacspro) currently has as of time of writing (03/04/14), and then improve further based on that. Next up are:

* Kill ring
* Macros
* Motion commands for other platforms (OSX has the basic emacs motion commands by default)

### Contributing

Yes please!
