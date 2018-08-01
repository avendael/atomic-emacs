module.exports =
  initialize: ->
    @_killed = @killing = false
    @_yanked = @yanking = false
    @previousCommand = null
    @recenters = 0
    @_recentered = false

  beforeCommand: (event) ->
    # Some plugins like "intentions" bind things to the pressing of a modifier,
    # which should not be able to cancel a dabbrev.
    if not @_isModifierKeyEvent(event) and not /dabbrev/.test(event.type) and @dabbrevState?
      @dabbrevState.emacsEditor.dabbrevDone()
      @dabbrevState = null
    @isDuringCommand = true

  afterCommand: (event) ->
    if (@killing = @_killed)
      @_killed = false

    if (@yanking = @_yanked)
      @_yanked = false

    if @_recentered
      @_recentered = false
      @recenters = (@recenters + 1) % 3
    else
      @recenters = 0

    @previousCommand = event.type
    @isDuringCommand = false

  killed: ->
    @_killed = true

  yanked: ->
    @_yanked = true

  recentered: ->
    @_recentered = true

  yankComplete: -> @yanking and not @_yanked

  _isModifierKeyEvent: (event) ->
    event.originalEvent?.constructor is KeyboardEvent and
      [0x10, 0x11, 0x12, 0x5b, 0x5d].includes(event.originalEvent.which)
