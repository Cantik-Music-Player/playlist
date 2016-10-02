events = require 'events'
require 'coffee-react/register'
PlaylistView = require('./playlist-view').PlaylistView
PlaylistComponent = require('./playlist-view').PlaylistComponent

module.exports =
class Playlist
  constructor: (@cantik) ->
    events.EventEmitter.call(this)

    @element = @cantik.pluginManager.plugins.centralarea.addPanel('Playlist', 'Now Playing')
    @tracklist = []
    @tracklistHistory = []
    @tracklistIndex = -1
    @tracklistHistoryIndex = -1
    @random = false
    @repeat = null

  activate: (state) ->
    @playlistView = new PlaylistView(@, @cantik)

  deactivate: ->
    @playlistView.destroy()

  serialize: ->
    playlistViewState: @playlistView.serialize()

  setRandom: (randomState) ->
    if randomState is not @random
      @tracklistHistory = [@tracklist[@tracklistIndex]]
      @tracklistHistoryIndex = 0
      @random = randomState
      @emit('random_changed', randomState)

  switchRepeatState: ->
    if @repeat is null
      @repeat = 'all'
    else if @repeat is 'all'
      @repeat = 'one'
    else
      @repeat = null
    @emit('repeat_changed', @repeat)

  addTrack: (track) ->
    @tracklist.push(JSON.parse(JSON.stringify(track)))
    @emit('tracklist_changed', @tracklist)

  addTracks: (tracks) ->
    @addTrack t for t in tracks

  deleteTrack: (trackIndex) ->
    @tracklistHistory = @cantik.utils.deleteValueFromArray(@tracklist[trackIndex], @tracklistHistory)
    @tracklist.splice(trackIndex, 1)

    @tracklistIndex-- if trackIndex <= @tracklistIndex
    @tracklistHistoryIndex-- if @tracklistHistoryIndex > -1 + @tracklistHistory.length

    @emit('tracklist_changed', @tracklist)

  moveTrack: (from, to) ->
    currentTrack = @tracklist[@tracklistIndex]
    @tracklist.splice(to, 0, @tracklist.splice(from, 1)[0])
    @tracklistIndex = @tracklist.indexOf(currentTrack)
    @emit('tracklist_changed', @tracklist)

  cleanPlaylist: ->
    @tracklist = []
    @tracklistIndex = -1
    @tracklistHistory = []
    @emit('tracklist_changed', @tracklist)

  getNextTrack: ->
    if @tracklistHistoryIndex < @tracklistHistory.length - 1
      # Going next in the history
      @tracklistHistoryIndex++
      @tracklistIndex = @tracklist.indexOf(@tracklistHistory[@tracklistHistoryIndex])
    else if not @random
      if @tracklistIndex < @tracklist.length - 1
        # No random & not end of plalist => Go next
        @tracklistIndex++
        @tracklistHistory.push(@tracklist[@tracklistIndex])
        @tracklistHistoryIndex = @tracklistHistory.length - 1
      else if @repeat is 'all'
        # End of playlist & repeat is all => Go to first track
        @tracklistIndex = 0
        @tracklistHistory = [@tracklist[@tracklistIndex]]
        @tracklistHistoryIndex = 0
    else
      # Random
      if @repeat is 'all' and @tracklistHistory.length is @tracklist.length
        # Reset history if it contains all te tracklist
        @tracklistHistory = []
      if @tracklistHistory.length < @tracklist.length
        # Find a random not alreay in history
        while true
          @tracklistIndex = Math.floor(Math.random() * @tracklist.length);
          break if @tracklist[@tracklistIndex] not in @tracklistHistory

        @tracklistHistory.push(@tracklist[@tracklistIndex])
        @tracklistHistoryIndex = @tracklistHistory.length - 1

    @emit('track_changed', @tracklist[@tracklistIndex])
    @tracklist[@tracklistIndex]

  getLastTrack: ->
    if @tracklistHistoryIndex > 0
      # Go back in history
      @tracklistHistoryIndex--
      @tracklistIndex = @tracklist.indexOf(@tracklistHistory[@tracklistHistoryIndex])
    else if not @random
      if @tracklistIndex > 0
        # No random and not beginning => Go last track
        @tracklistIndex--
        @tracklistHistory.splice(@tracklistHistoryIndex, 0, @tracklist[@tracklistIndex])

    @emit('track_changed', @tracklist[@tracklistIndex])
    @tracklist[@tracklistIndex]

Playlist.prototype.__proto__ = events.EventEmitter.prototype
