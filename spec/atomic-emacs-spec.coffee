AtomicEmacs = require '../lib/atomic-emacs'

# Use the command `window:run-package-specs` (cmd-alt-ctrl-p) to run specs.
#
# To run a specific `it` or `describe` block add an `f` to the front (e.g. `fit`
# or `fdescribe`). Remove the `f` to unfocus the block.

describe "AtomicEmacs", ->
  activationPromise = null

  beforeEach ->
    atom.workspaceView = new WorkspaceView
    activationPromise = atom.packages.activatePackage('atomicEmacs')

  describe "when the atomic-emacs:toggle event is triggered", ->
    it "attaches and then detaches the view", ->
      expect(atom.workspaceView.find('.atomic-emacs')).not.toExist()

      # This is an activation event, triggering it will cause the package to be
      # activated.
      atom.workspaceView.trigger 'atomic-emacs:toggle'

      waitsForPromise ->
        activationPromise

      runs ->
        expect(atom.workspaceView.find('.atomic-emacs')).toExist()
        atom.workspaceView.trigger 'atomic-emacs:toggle'
        expect(atom.workspaceView.find('.atomic-emacs')).not.toExist()
