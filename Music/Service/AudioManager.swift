//
//  AudioManager.swift
//  Music
//
//  Created by Nguyen Ty on 09/06/2023.
//
import AVFoundation
import AVKit
import MobileCoreServices
import Photos
import UIKit
class AudioManager: NSObject {
    // MARK: crop the Audio which you select portion

    static let shared = AudioManager()

    func trimAudio(sourceURL: URL, startTime: Double, stopTime: Double, name: String, success: @escaping ((URL) -> Void), failure: @escaping ((String?) -> Void)) {
        /// Asset
        let asset = AVAsset(url: sourceURL)
        let compatiblePresets = AVAssetExportSession.exportPresets(compatibleWith: asset)
        if compatiblePresets.contains(AVAssetExportPresetMediumQuality) {
            let documentDirectory = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
            var outputURL = documentDirectory.appendingPathComponent("TrimAudios")
            do {
                try FileManager.default.createDirectory(at: outputURL, withIntermediateDirectories: true, attributes: nil)
                outputURL = outputURL.appendingPathComponent("\(name).m4a")
            } catch let error {
                failure(error.localizedDescription)
            }
            // Remove existing file
            deleteFile(outputURL)
            // export the audio to as per your requirement conversion
            guard let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetAppleM4A) else { return }
            exportSession.outputURL = outputURL
            exportSession.outputFileType = AVFileType.m4a

            let range: CMTimeRange = CMTimeRangeFromTimeToTime(start: CMTimeMakeWithSeconds(startTime, preferredTimescale: asset.duration.timescale), end: CMTimeMakeWithSeconds(stopTime, preferredTimescale: asset.duration.timescale))
            exportSession.timeRange = range

            exportSession.exportAsynchronously(completionHandler: {
                switch exportSession.status {
                case .completed:
                    success(outputURL)
                default:
                    if let _error = exportSession.error?.localizedDescription {
                        failure(_error)
                    }
                }
            })
        }
    }

    func addAudiosToVideo(videoURL: URL, audios: [AudioModel], isMuted: Bool, completion: @escaping (Bool, Error?) -> Void) {
        let composition = AVMutableComposition()
        var audioMix = AVMutableAudioMix()
        // Load video asset
        let videoAsset = AVAsset(url: videoURL)
        let videoTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)

        if let assetTrack = videoAsset.tracks(withMediaType: .video).first {
            try? videoTrack?.insertTimeRange(CMTimeRange(start: CMTime.zero, duration: videoAsset.duration), of: assetTrack, at: CMTime.zero)
        }

        // Load audio asset
        if !isMuted {
            let audioTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)
            if let videoAudioTrack = videoAsset.tracks(withMediaType: .audio).first {
                try? audioTrack?.insertTimeRange(CMTimeRange(start: CMTime.zero,
                                                             duration: videoAsset.duration),
                                                 of: videoAudioTrack, at: CMTime.zero)
            }
        }

        audios.forEach { audio in
            guard let url = audio.audioURL,
                  let start = audio.startTime,
                  let end = audio.endTime,
                  let startVideo = audio.startVideo, let volume = audio.volume else {
                return
            }
            let audioExtraTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)
            let audioAsset = AVAsset(url: url)
            if let extraAudioTrack = audioAsset.tracks(withMediaType: .audio).first, let trackID = audioExtraTrack?.trackID {
                let start: CMTime = CMTime(seconds: start, preferredTimescale: 1)
                let end: CMTime = CMTime(seconds: end, preferredTimescale: 1)
                print("TRACKID : \(audioExtraTrack?.trackID)")
                let startTimerVideo: CMTime = CMTime(seconds: startVideo, preferredTimescale: 1)
                print("HOT HOT TIMER \(audio.fileName ?? "") : \(start) --- \(end) -- \(startTimerVideo)")
                self.adjustSoundInAudioTrack(audioTrack: extraAudioTrack,
                                             trackID: trackID,
                                             volume: volume,
                                             timeRange: CMTimeRange(start: start, end: end),
                                             audioMix: &audioMix)
                try? audioExtraTrack?.insertTimeRange(CMTimeRange(start: start, end: end), of: extraAudioTrack, at: startTimerVideo)
            }
        }

        // Export composition
        guard let exportSession = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetHighestQuality) else {
            completion(false, nil)
            return
        }

        let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        var outputURL = documentDirectory.appendingPathComponent("MergeVideowithAudio")
        do {
            try FileManager.default.createDirectory(at: outputURL, withIntermediateDirectories: true, attributes: nil)
            outputURL = outputURL.appendingPathComponent("\(outputURL.lastPathComponent).mp4")
        } catch let error {
            print("error file")
        }

        // Remove existing file
        deleteFile(outputURL)
        print("HOT HOT AUDIO MIX : \(audioMix.inputParameters)")
        DispatchQueue.main.async {
            exportSession.audioMix = audioMix
            exportSession.outputURL = outputURL
            exportSession.outputFileType = .mp4
            exportSession.shouldOptimizeForNetworkUse = true
            exportSession.exportAsynchronously {
                if exportSession.status == .completed {
                    completion(true, nil)
                    self.save(videoUrl: outputURL, toAlbum: "Video Editor") { isSaved, error in
                        if isSaved {
                            print("save success")
                            completion(true, nil)
                        } else {
                            print("save error : \(error)")
                            completion(false, error)
                        }
                    }
                } else {
                    completion(false, exportSession.error)
                }
            }
        }
    }

    func adjustSoundInAudioTrack(audioTrack: AVAssetTrack, trackID: CMPersistentTrackID, volume: Float, timeRange: CMTimeRange, audioMix: inout AVMutableAudioMix) {
        let audioMixInputParameters = AVMutableAudioMixInputParameters(track: audioTrack)
        audioMixInputParameters.trackID = trackID
        audioMixInputParameters.setVolume(volume, at: timeRange.start)
        audioMix.inputParameters.append(audioMixInputParameters)
    }

    func deleteFile(_ filePath: URL) {
        guard FileManager.default.fileExists(atPath: filePath.path) else {
            return
        }
        do {
            try FileManager.default.removeItem(atPath: filePath.path)
        } catch {
            fatalError("Unable to delete file: \(error) : \(#function).")
        }
    }

    func createAlbum(withTitle title: String, completionHandler: @escaping (PHAssetCollection?) -> Void) {
        DispatchQueue.global(qos: .background).async {
            var placeholder: PHObjectPlaceholder?

            PHPhotoLibrary.shared().performChanges({
                let createAlbumRequest = PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: title)
                placeholder = createAlbumRequest.placeholderForCreatedAssetCollection
            }, completionHandler: { created, _ in
                var album: PHAssetCollection?
                if created {
                    UserDefaults.standard.set(true, forKey: "AlbumCreated")
                    let collectionFetchResult = placeholder.map { PHAssetCollection.fetchAssetCollections(withLocalIdentifiers: [$0.localIdentifier], options: nil) }
                    album = collectionFetchResult?.firstObject
                }
                completionHandler(album)
            })
        }
    }

    func getAlbum(title: String, completionHandler: @escaping (PHAssetCollection?) -> Void) {
        DispatchQueue.global(qos: .background).async { [weak self] in
            let fetchOptions = PHFetchOptions()
            fetchOptions.predicate = NSPredicate(format: "title = %@", title)
            let collections = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: fetchOptions)

            if let album = collections.firstObject {
                completionHandler(album)
            } else {
                self?.createAlbum(withTitle: title, completionHandler: { album in
                    completionHandler(album)
                })
            }
        }
    }

    func save(videoUrl: URL, toAlbum titled: String, completionHandler: @escaping (Bool, Error?) -> Void) {
        getAlbum(title: titled) { album in
            DispatchQueue.global(qos: .background).async {
                PHPhotoLibrary.shared().performChanges({
                    let assetRequest = PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: videoUrl)
                    let assets = assetRequest?.placeholderForCreatedAsset
                        .map { [$0] as NSArray } ?? NSArray()
                    let albumChangeRequest = album.flatMap { PHAssetCollectionChangeRequest(for: $0) }
                    albumChangeRequest?.addAssets(assets)
                }, completionHandler: { success, error in
                    completionHandler(success, error)
                })
            }
        }
    }
}
