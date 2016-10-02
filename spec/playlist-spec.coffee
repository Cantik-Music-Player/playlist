mock = require 'mock-require'

mock('electron', {
  remote: ''
})

Playlist = require '../lib/playlist.coffee'
sinon = require 'sinon'
assert = require 'assert'

describe "Playlist", ->
  beforeEach ->
    @playlist = new Playlist({
      'pluginManager': {
        'plugins': {
          'centralarea': {
            'addPanel': sinon.spy()
          }
        }
      }
    })

  it "Initialized", ->
    assert(@playlist.cantik.pluginManager.plugins.centralarea.addPanel.called)

    assert.deepEqual(@playlist.tracklist, [])
    assert.deepEqual(@playlist.tracklistHistory, [])
    assert.deepEqual(@playlist.tracklistIndex, -1)
    assert.deepEqual(@playlist.tracklistHistoryIndex, -1)
    assert.deepEqual(@playlist.random, false)
    assert.deepEqual(@playlist.repeat, null)

  it "Set random", ->
    eventRandom = false
    @playlist.on('random_changed', ->
      eventRandom = true)

    @playlist.tracklistHistory = [1, 2, 3, 4]
    @playlist.tracklistHistoryIndex = 3
    @playlist.tracklist = [1, 2, 3, 4, 5, 6, 7]
    @playlist.tracklistIndex = 3
    @playlist.random = false

    @playlist.setRandom true

    assert.deepEqual(@playlist.tracklistHistory, [4])
    assert.deepEqual(@playlist.tracklistHistoryIndex, 0)
    assert.deepEqual(@playlist.random, true)
    assert.deepEqual(eventRandom, true)

  it "Set random without change", ->
    eventRandom = false
    @playlist.on('random_changed', ->
      eventRandom = true)

    @playlist.tracklistHistory = [1, 2, 3, 4]
    @playlist.tracklistHistoryIndex = 3
    @playlist.tracklist = [1, 2, 3, 4, 5, 6, 7]
    @playlist.tracklistIndex = 3
    @playlist.random = false

    @playlist.setRandom false

    assert.deepEqual(@playlist.tracklistHistory, [1, 2, 3, 4])
    assert.deepEqual(@playlist.tracklistHistoryIndex, 3)
    assert.deepEqual(@playlist.random, false)
    assert.deepEqual(eventRandom, false)

  it "Switch Repeat State", ->
    eventRepeat = 0
    @playlist.on('repeat_changed', ->
      eventRepeat++)

    assert.deepEqual(@playlist.repeat, null)
    do @playlist.switchRepeatState
    assert.deepEqual(@playlist.repeat, 'all')
    do @playlist.switchRepeatState
    assert.deepEqual(@playlist.repeat, 'one')
    do @playlist.switchRepeatState
    assert.deepEqual(@playlist.repeat, null)

    assert.deepEqual(eventRepeat, 3)

  it "Add track", ->
    eventTracklist = false
    @playlist.on('tracklist_changed', ->
      eventTracklist = true)

    assert.deepEqual(@playlist.tracklist, [])

    @playlist.addTrack 1

    assert.deepEqual(@playlist.tracklist, [1])
    assert.deepEqual(eventTracklist, true)

  it "Add tracks", ->
    @playlist.addTrack = sinon.spy()

    @playlist.addTracks [1, 2, 3]

    assert(@playlist.addTrack.calledWith(1))
    assert(@playlist.addTrack.calledWith(2))
    assert(@playlist.addTrack.calledWith(3))

  it "Clean Tracklist", ->
    eventTracklist = false
    @playlist.on('tracklist_changed', ->
      eventTracklist = true)

    @playlist.tracklist = [1, 2, 3]
    @playlist.tracklistIndex = 1
    @playlist.tracklistHistory = [1, 2]

    do @playlist.cleanPlaylist

    assert.deepEqual(@playlist.tracklist, [])
    assert.deepEqual(@playlist.tracklistIndex, -1)
    assert.deepEqual(@playlist.tracklistHistory, [])
    assert.deepEqual(eventTracklist, true)

  it "Go next thought the history", ->
    eventTrack = false
    @playlist.on('track_changed', ->
      eventTrack = true)

    @playlist.tracklist = [1, 2, 3, 4, 5, 6]
    @playlist.tracklistHistory = [1, 2, 3, 4]
    @playlist.tracklistHistoryIndex = 2

    assert.deepEqual(@playlist.getNextTrack(), 4)
    assert.deepEqual(@playlist.tracklistHistoryIndex, 3)
    assert.deepEqual(@playlist.tracklistIndex, 3)
    assert.deepEqual(eventTrack, true)

  it "Go to next track", ->
    eventTrack = false
    @playlist.on('track_changed', ->
      eventTrack = true)

    @playlist.tracklist = [1, 2, 3, 4, 5, 6]
    @playlist.tracklistIndex = 4

    assert.deepEqual(@playlist.getNextTrack(), 6)
    assert.deepEqual(@playlist.tracklistIndex, 5)
    assert.deepEqual(eventTrack, true)

  it "Go to beginning when repeat is all", ->
    eventTrack = false
    @playlist.on('track_changed', ->
      eventTrack = true)

    @playlist.tracklist = [1, 2, 3, 4, 5, 6]
    @playlist.tracklistIndex = 5
    @playlist.repeat = 'all'

    assert.deepEqual(@playlist.getNextTrack(), 1)
    assert.deepEqual(@playlist.tracklistIndex, 0)
    assert.deepEqual(eventTrack, true)

  it "Go next random", ->
    eventTrack = false
    @playlist.on('track_changed', ->
      eventTrack = true)

    @playlist.tracklist = [1, 2, 3, 4, 5, 6]
    @playlist.tracklistIndex = 5
    @playlist.tracklistHistory = [1, 2, 3, 4, 5, 6]
    @playlist.tracklistHistoryIndex = 5
    @playlist.repeat = 'all'
    @playlist.random = true

    played = []
    played.push(@playlist.getNextTrack())
    played.push(@playlist.getNextTrack())
    played.push(@playlist.getNextTrack())
    played.push(@playlist.getNextTrack())
    played.push(@playlist.getNextTrack())
    played.push(@playlist.getNextTrack())
    played.push(@playlist.getNextTrack())

    output = {}
    output[played[key]] = played[key] for key in [0...played.length]
    unique = (value for key, value of output)

    assert.deepEqual(unique, [1, 2, 3, 4, 5, 6])
    assert.deepEqual(played.length, 7)
    assert.notDeepEqual(played, [1, 2, 3, 4, 5, 6, 1])
    assert.deepEqual(eventTrack, true)

  it "Go back thought history", ->
    eventTrack = false
    @playlist.on('track_changed', ->
      eventTrack = true)

    @playlist.tracklist = [1, 2, 3, 4, 5, 6]
    @playlist.tracklistHistory = [1, 2, 3, 4]
    @playlist.tracklistHistoryIndex = 2

    assert.deepEqual(@playlist.getLastTrack(), 2)
    assert.deepEqual(@playlist.tracklistHistoryIndex, 1)
    assert.deepEqual(@playlist.tracklistIndex, 1)
    assert.deepEqual(eventTrack, true)

  it "Go back", ->
    eventTrack = false
    @playlist.on('track_changed', ->
      eventTrack = true)

    @playlist.tracklist = [1, 2, 3, 4, 5, 6]
    @playlist.tracklistHistory = [3, 4, 5, 6]
    @playlist.tracklistHistoryIndex = 0
    @playlist.tracklistIndex = 2

    assert.deepEqual(@playlist.getLastTrack(), 2)
    assert.deepEqual(@playlist.tracklistHistoryIndex, 0)
    assert.deepEqual(@playlist.tracklistHistory, [2, 3, 4, 5, 6])
    assert.deepEqual(@playlist.tracklistIndex, 1)
    assert.deepEqual(eventTrack, true)
