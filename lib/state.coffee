module.exports =
class State
  constructor: ->
    @killed = @killing = false
    @yanked = @yanking = false
    @previousCommand = null
    @recenters = 0

  beforeCommand: (event) ->
    @killed = false
    @yanked = false

  afterCommand: (event) ->
    @killing = @killed
    @yanking = @yanked
    @previousCommand = event.type

  yankComplete: -> @yanking and not @yanked
