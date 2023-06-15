//
//  ViewController.swift
//  Music
//
//  Created by Nguyen Ty on 09/06/2023.
//

import AVFoundation
import AVKit
import MediaPlayer
import MobileCoreServices
import Photos
import UIKit

class ViewController: UIViewController {
    @IBOutlet var videoView: UIView!
    @IBOutlet var tableView: UITableView!
    @IBOutlet var timePlayLabel: UILabel!
    // Video Crop view
    @IBOutlet var playPauseImage: UIImageView!
    @IBOutlet var timeMaxLabel: UILabel!

    var audioTotalsec = 0.0
    var pickedFileName: String = ""
    var slctAudioUrl: URL?
    var videoUrl: URL?

    var arrAudio = [AudioModel()]
    var audioplayer = AVAudioPlayer()
    var avplayer = AVPlayer()
    var audioplayers: [AVAudioPlayer] = []
    var playerController = AVPlayerViewController()

    override func viewDidLoad() {
        super.viewDidLoad()
        setUpTableView()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    @IBAction func pauseAudio(_ sender: Any) {
        if audioplayer.isPlaying {
            audioplayer.pause()
        } else {
            audioplayer.play()
        }
    }

    @IBAction func trimAudio(_ sender: Any) {
        let vc = TrimAudioViewController()
        present(vc, animated: true)
    }

    func alert(title: String, message: String, action: @escaping () -> Void) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)

        let okAction = UIAlertAction(title: "OK", style: .default) { _ in
            action()
        }

        // Add the action to the alert controller
        alertController.addAction(okAction)

        // Present the alert
        // Assuming you have a view controller named "viewController" to present the alert from
        present(alertController, animated: true, completion: nil)
    }

    @IBAction func exportVideoEdit(_ sender: Any) {
        guard let videoUrl = videoUrl else { return }
        print(" Audio Model :\(AVAsset(url: videoUrl).duration)")
        arrAudio.forEach { audio in
            print("Audio Model : \(audio.audioURL) -- \(audio.startTime) --- \(audio.endTime) -- \(audio.startVideo) -- \(audio.endVideo)")
        }
        AudioManager.shared.addAudiosToVideo(videoURL: videoUrl, audios: arrAudio, isMuted: avplayer.isMuted) { success, error in
            if success {
                DispatchQueue.main.async {
                    print("Exported video with added sound successfully in photo")
                    self.alert(title: "Export Video Success", message: "Exported video with added sound successfully in photo") {
                    }
                }
            } else {
                if let error = error {
                    DispatchQueue.main.async {
                        print(error.localizedDescription)
                        self.alert(title: "Export Video Error", message: error.localizedDescription) {
                        }
                    }
                }
            }
        }
    }

    @IBAction func selectedVideo(_ sender: Any) {
        let videoPickerController = UIImagePickerController()
        videoPickerController.delegate = self
        videoPickerController.transitioningDelegate = self
        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) == false { return }
        videoPickerController.allowsEditing = true
        videoPickerController.sourceType = .photoLibrary
        videoPickerController.mediaTypes = [kUTTypeMovie as String]
        videoPickerController.modalPresentationStyle = .custom
        present(videoPickerController, animated: true, completion: nil)
    }

    @IBAction func selectedAudio(_ sender: Any) {
        if let urlVideo = videoUrl {
            let vc = AudioViewController(videoUrl: urlVideo, data: AudioModel())
            vc.delegate = self
            present(vc, animated: true)
        } else {
            alert(title: "Video Empty", message: "please choose video") {}
        }
    }

    func setUpTableView() {
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.allowsSelection = true
        tableView.delegate = self
        tableView.dataSource = self
    }

    func addVideoPlayer(videoUrl: URL, to view: UIView) {
        self.videoUrl = videoUrl
        avplayer = AVPlayer(url: videoUrl)
        playerController.player = avplayer
        addChild(playerController)
        view.addSubview(playerController.view)
        playerController.view.frame = view.bounds
        playerController.showsPlaybackControls = true
        avplayer.play()
    }

    func addAudioPlayer(AudioUrl: URL) {
        do {
            audioplayer = try AVAudioPlayer(contentsOf: AudioUrl)
        } catch {
            print("Error add Audio :  \(error)")
        }
        audioplayer.play()
    }
}

extension ViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }
}

extension ViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return arrAudio.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = arrAudio[indexPath.row].fileName
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let audio = arrAudio[indexPath.row]
        if let videoUrl = videoUrl {
            let vc = AudioViewController(videoUrl: videoUrl,
                                         data: audio,
                                         slctAudioUrl: audio.audioURL,
                                         selectedTableViewCell: indexPath.row)
            vc.delegate = self
            print("Audio Model : \(audio.audioURL) -- \(audio.startTime) --- \(audio.endTime)")
            present(vc, animated: true)
        }
    }
}

// MARK: UIImagePicker Delegate

extension ViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIViewControllerTransitioningDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        let videoURL = info[UIImagePickerController.InfoKey.mediaURL] as? URL
        dismiss(animated: true, completion: nil)

        if let videourl = videoURL {
            addVideoPlayer(videoUrl: videourl, to: videoView)
        }
    }
}

extension ViewController: DataDelegate {
    func dataAudioModel(index: Int, audioModel: AudioModel) {
        if index == -1 {
            arrAudio.append(audioModel)
        } else {
            arrAudio[index] = audioModel
        }
        tableView.reloadData()
        dismiss(animated: true)
        print("HOT HOT ARR AUDIO : \(arrAudio.first)")
    }
}
