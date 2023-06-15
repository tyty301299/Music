//
//  AudioModel.swift
//  Music
//
//  Created by Nguyen Ty on 13/06/2023.
//

import AVFAudio
import Foundation

class AudioModel {
    var fileName: String?
    var audioURL: URL?
    var startTime: Double?
    var endTime: Double?
    var startVideo: Double?
    var endVideo: Double?
    var volume: Float?
    var beats: [beat]?

    init(fileName: String? = nil, audioURL: URL? = nil, startTime: Double? = nil, endTime: Double? = nil, startVideo: Double? = nil, endVideo: Double? = nil, volume: Float? = nil, beats: [beat]? = nil) {
        self.fileName = fileName
        self.audioURL = audioURL
        self.startTime = startTime
        self.endTime = endTime
        self.startVideo = startVideo
        self.endVideo = endVideo
        self.volume = volume
        self.beats = beats
    }
}

class beat {
    var beat: CMTime = CMTime(seconds: 0.0, preferredTimescale: 1)
    var volume: Float = 0.0
    init(beat: CMTime, volume: Float) {
        self.beat = beat
        self.volume = volume
    }
}

let beats: [beat] = [beat(beat: CMTime(seconds: 1, preferredTimescale: 1), volume: 1),
                     beat(beat: CMTime(seconds: 4, preferredTimescale: 1), volume: 1),
                     beat(beat: CMTime(seconds: 7, preferredTimescale: 1), volume: 1),
                     beat(beat: CMTime(seconds: 10, preferredTimescale: 1), volume: 1),
                     beat(beat: CMTime(seconds: 14, preferredTimescale: 1), volume: 1),
                     beat(beat: CMTime(seconds: 17, preferredTimescale: 1), volume: 1),
                     beat(beat: CMTime(seconds: 19, preferredTimescale: 1), volume: 1)]
