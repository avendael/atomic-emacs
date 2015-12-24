module.exports =
  initialize: ->
    @_killed = @killing = false
    @_yanked = @yanking = false
    @previousCommand = null
    @recenters = 0
    @_recentered = false

  beforeCommand: (event) ->
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
