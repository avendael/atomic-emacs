## Atomic Emacs

Emacs keybindings for Atom.
![Build Status](https://travis-ci.org/avendael/atomic-emacs.svg?branch=master)

## Installation

On the command line:

 * `apm install atomic-emacs`

Or in Atom:

 * In `Preferences`, click the `Install` tab.
 * Type `atomic-emacs` in the search box, and click the `Packages` button.
 * Click `Install` on the `atomic-emacs` package.

There's no need to restart Atom.

## Commands

### Navigation

    'ctrl-b': 'atomic-emacs:backward-char'
    'left': 'atomic-emacs:backward-char'
    'ctrl-f': 'atomic-emacs:forward-char'
    'right': 'atomic-emacs:forward-char'
    'alt-b': 'atomic-emacs:backward-word'
    'alt-left': 'atomic-emacs:backward-word'
    'alt-f': 'atomic-emacs:forward-word'
    'alt-right': 'atomic-emacs:forward-word'
    'ctrl-alt-b': 'atomic-emacs:backward-sexp'
    'ctrl-alt-f': 'atomic-emacs:forward-sexp'
    'ctrl-alt-p': 'atomic-emacs:backward-list'
    'ctrl-alt-n': 'atomic-emacs:forward-list'
    'alt-{': 'atomic-emacs:backward-paragraph'
    'alt-}': 'atomic-emacs:forward-paragraph'
    'alt-m': 'atomic-emacs:back-to-indentation'
    'ctrl-a': 'editor:move-to-beginning-of-line'
    'ctrl-s': 'find-and-replace:show'
    'ctrl-r': 'find-and-replace:show'
    'alt-<': 'core:move-to-top'
    'alt->': 'core:move-to-bottom'

### Killing & Yanking

    'alt-backspace': 'atomic-emacs:backward-kill-word'
    'alt-delete': 'atomic-emacs:backward-kill-word'
    'alt-d': 'atomic-emacs:kill-word'
    'ctrl-k': 'atomic-emacs:kill-line'
    'ctrl-w': 'atomic-emacs:kill-region'
    'alt-w': 'atomic-emacs:copy-region-as-kill'
    'ctrl-alt-w': 'atomic-emacs:append-next-kill'
    'ctrl-y': 'atomic-emacs:yank'
    'alt-y': 'atomic-emacs:yank-pop'
    'alt-shift-y': 'atomic-emacs:yank-shift'

Note that Atomic Emacs does not (yet) support prefix arguments, so to rotate the
kill ring forward, use `yank-shift` (equivalent to `yank-pop` in Emacs with a
prefix argument of -1).

### Editing

    'alt-\\': 'atomic-emacs:delete-horizontal-space'
    'alt-^': 'atomic-emacs:delete-indentation'
    'ctrl-o': 'atomic-emacs:open-line'
    'alt-space': 'atomic-emacs:just-one-space'
    'ctrl-x ctrl-o': 'atomic-emacs:delete-blank-lines'
    'ctrl-t': 'atomic-emacs:transpose-chars'
    'alt-t': 'atomic-emacs:transpose-words'
    'ctrl-x ctrl-t': 'atomic-emacs:transpose-lines'
    'ctrl-x ctrl-l': 'atomic-emacs:downcase-word-or-region'
    'alt-l': 'atomic-emacs:downcase-word-or-region'
    'ctrl-x ctrl-u': 'atomic-emacs:upcase-word-or-region'
    'alt-u': 'atomic-emacs:upcase-word-or-region'
    'alt-c': 'atomic-emacs:capitalize-word-or-region'
    'ctrl-j': 'editor:newline'
    'ctrl-m': 'editor:newline'
    'ctrl-/': 'core:undo'
    'ctrl-_': 'core:undo'
    'alt-/': 'autocomplete-plus:activate'
    'alt-q': 'autoflow:reflow-selection'
    'alt-;': 'editor:toggle-line-comments'

### Marking & Selecting

    'ctrl-space': 'atomic-emacs:set-mark'
    'ctrl-alt-space': 'atomic-emacs:mark-sexp'
    'ctrl-x h': 'atomic-emacs:mark-whole-buffer'
    'ctrl-x ctrl-x': 'atomic-emacs:exchange-point-and-mark'

### UI

    'ctrl-g': 'core:cancel'
    'ctrl-x ctrl-s': 'core:save'
    'ctrl-x ctrl-w': 'core:save-as'
    'alt-x': 'command-palette:toggle'
    'alt-.': 'symbols-view:toggle-file-symbols'
    'ctrl-x ctrl-f': 'atomic-emacs:find-file'
    'ctrl-x b': 'fuzzy-finder:toggle-buffer-finder'
    'ctrl-x k': 'core:close'
    'ctrl-x 0': 'pane:close'
    'ctrl-x 1': 'atomic-emacs:close-other-panes'
    'ctrl-x 2': 'pane:split-down'
    'ctrl-x 3': 'pane:split-right'
    'ctrl-x o': 'window:focus-next-pane'

### Other Packages

For a more Emacs-like version of `find-file`, install
[`advanced-open-file`](https://atom.io/packages/advanced-open-file). Atomic
Emacs will use that package if it exists by default instead of Atom's
fuzzy-finder. This may be disabled in settings, but note that fuzzy-finder
cannot create new files.

### Something missing?

Feel free to suggest features on the Github issue tracker, or better yet, send a
pull request!

## Windows Note

Some common Emacs keystrokes conflict with the default key bindings on Atom for
Windows in unexpected ways. For example, `ctrl-k` (kill-line on emacs) is a
prefix key for a set of pane management commands in Atom for Windows. The result
is that after pressing `ctrl-k`, Atom will wait for 2 seconds to determine if it
should treat this as a full command, or the beginning of another command, making
`kill-line` feel "slow".

You can of course disable this by disabling the all built-in key bindings that
start with `ctrl-k` in your `keymaps.config` file. You can also do this a little
easier with the [disable-keybindings][disable-keybindings] package.

[disable-keybindings]: https://atom.io/packages/disable-keybindings

## Contributing

* [Bug reports](https://github.com/avendael/atomic-emacs/issues)
* [Source](https://github.com/avendael/atomic-emacs)
* Patches: Fork on Github, send pull request.
 * Include tests where practical.
 * Leave the version alone, or bump it in a separate commit.
