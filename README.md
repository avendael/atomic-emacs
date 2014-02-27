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
* 'ctrl-x ctrl-s': 'core:save'
* 'ctrl-x ctrl-u': 'atomic-emacs:upcase-region'
* 'ctrl-x ctrl-l': 'atomic-emacs:downcase-region'
* 'ctrl-x ctrl-t': 'atomic-emacs:transpose-lines'
* 'alt-x': 'command-palette:toggle'
* 'alt-v': 'core:page-up'
* 'alt-<': 'atomic-emacs:beginning-of-buffer'
* 'alt->': 'atomic-emacs:end-of-buffer'
* 'alt-a': 'atomic-emacs:back-to-indentation'
* 'alt-m': 'atomic-emacs:back-to-indentation'

Some things might not work like how you would expect it to work. For instance, an undo after a
transpose-lines is really weird because the transpose-lines code involves a lot of editing steps.

### Future Work

There is no exact plan on what feature to include next. Basically, my fingers press something, my
muscle memory gets annoyed, and then I just go ahead and fix that. But right at the top of my head,
I'm currently thinking of:

* Set mark
* Kill ring
* Macros
