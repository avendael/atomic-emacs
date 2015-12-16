module.exports =
class State
  constructor: ->
    @_killed = @killing = false
    @_yanked = @yanking = false
    @previousCommand = null
    @recenters = 0
    @_recentered = false

  afterCommand: (event) ->
    if (@killing = @_killed)
      @_killed = false

    if (@yanking = @_yanked)
      @_yanked = false

    if @_recentered
      @recenters = (@recenters + 1) % 3
      @_recentered = false

    @previousCommand = event.type

  killed: ->
    @_killed = true

  yanked: ->
    @_yanked = true

  recentered: ->
    @_recentered = true

  yankComplete: -> @yanking and not @_yanked
