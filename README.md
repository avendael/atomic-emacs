## Atomic Emacs

An atomic implementation of emacs keybindings.

### Important Note

I love emacs, but this package will never implement all of emacs' features. It only aims to
provide a reasonable set of default emacs keybindings so that emacs refugees might find themselves
at home.

OSX already provides emacs-like keybindings to Atom, and those are not reimplemented in this
package. This might, however, cause a problem later on when Atom becomes available at other
platforms. Once that time comes, I will gladly include those keybindings in this package.

### Current Status

It's super incomplete, very alpha stage. Basically, just these:

* 'ctrl-y': 'core:paste'
* 'ctrl-w': 'core:cut'
* 'ctrl-v': 'core:page-down'
* 'ctrl-s': 'find-and-replace:show'
* 'ctrl-j': 'editor:newline'
* 'ctrl-/': 'core:undo'
* 'ctrl-o': 'atomic-emacs:open-line'
* 'ctrl-t': 'atomic-emacs:transpose-chars'
* 'ctrl-space': 'atomic-emacs:set-mark'
* 'ctrl-x ctrl-x': 'atomic-emacs:exchange-point-and-mark'
* 'ctrl-x ctrl-s': 'core:save'
* 'ctrl-x ctrl-u': 'atomic-emacs:upcase-region'
* 'ctrl-x ctrl-l': 'atomic-emacs:downcase-region'
* 'ctrl-x ctrl-t': 'atomic-emacs:transpose-lines'
* 'ctrl-x o': 'window:focus-next-pane'
* 'ctrl-x b': 'fuzzy-finder:toggle-buffer-finder'
* 'ctrl-x ctrl-f': 'fuzzy-finder:toggle-file-finder'
* 'ctrl-x 3': 'pane:split-right'
* 'ctrl-x 2': 'pane:split-down'
* 'ctrl-x 0': 'pane:close'
* 'ctrl-x 1': 'pane:close-other-items'
* 'ctrl-x k': 'core:close'
* 'ctrl-x h': 'atomic-emacs:mark-whole-buffer'
* 'alt-x': 'command-palette:toggle'
* 'alt-w': 'atomic-emacs:copy'
* 'alt-;': 'editor:toggle-line-comments'
* 'alt-v': 'core:page-up'
* 'alt-<': 'atomic-emacs:beginning-of-buffer'
* 'alt->': 'atomic-emacs:end-of-buffer'
* 'alt-a': 'atomic-emacs:back-to-indentation'
* 'alt-m': 'atomic-emacs:back-to-indentation'
* 'alt-/': 'autocomplete:attach'

#### Some things that might not work as expected

There is a set-marks command. However, the ctrl-space mapping is being used by atom-core, and this package cannot override the core mappings. To use this command, the user must include the following lines in the user's keymap.cson (accessed through menu Atom -> Open Your Keymap):

```
'.editor':
  'ctrl-space': 'atomic-emacs:set-mark'
```

### Future Work

There is no exact plan on what feature to include next. Basically, my fingers press something, my
muscle memory gets annoyed, and then I just go ahead and fix that. But right at the top of my head,
I'm currently thinking of:

* Kill ring
* Macros
