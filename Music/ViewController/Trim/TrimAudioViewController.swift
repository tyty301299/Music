//
//  TrimAudioViewController.swift
//  Music
//
//  Created by Nguyen Ty on 15/06/2023.
//
import AVFoundation
import AVKit
import MediaPlayer
import MobileCoreServices
import Photos
import UIKit

class TrimAudioViewController: UIViewController {
    @IBOutlet var nameFiled: UITextField!
    @IBOutlet var txtAudioLbl: UILabel!
    @IBOutlet var sliderAudioView: UIView!
    var rangeSlider: SlickRangeSlider!
    var mergeSlidervw: OptiRangeSliderView!
    var audioTotalsec = 0.0
    var pickedFileName: String = ""
    var slctAudioUrl: URL?

    var mergesliderminimumValue: Double = 0.0
    var mergeslidermaximumValue: Double = 0.0
    var selectedTableViewCell: Int = -1
    var arrAudio = [AudioModel()]
    var audioplayer = AVAudioPlayer()
    var avplayer = AVPlayer()
    var audioplayers: [AVAudioPlayer] = []
    var playerController = AVPlayerViewController()
    var data = AudioModel()
    var isTrimAudio: Bool = false

    override func viewDidLoad() {
        super.viewDidLoad()
        setupAudioCropSliderView()
        // Do any additional setup after loading the view.
    }

    @IBAction func saveAudioTrim(_ sender: Any) {
        guard let audioUrl = slctAudioUrl else {
            self.alert(title: "Audio Error", message: "please choose Audio") {
               
            }
            return
        }
        if let name = nameFiled.text, !name.isEmpty {
            AudioManager.shared.trimAudio(sourceURL: audioUrl, startTime: mergesliderminimumValue, stopTime: mergeslidermaximumValue, name: nameFiled.text ?? "file trim") { url in
                print("hot hot url Trim audio : \(url)")
                DispatchQueue.main.async {
                    self.alert(title: "Trim audio ", message: "Trim audio success at the document") {
                        self.dismiss(animated: true)
                    }
                }
            } failure: { error in
                self.alert(title: "save audio trim Error", message: error.debugDescription) {
                    print("Error ")
                }
            }
        } else {
            alert(title: "File Name Empty", message: "please choose File name") {
            }
        }
    }

    @IBAction func selectedAudio(_ sender: Any) {
        let documentPicker: UIDocumentPickerViewController = UIDocumentPickerViewController(documentTypes: ["public.audio", "public.mp3", "public.mpeg-4-audio", "public.aifc-audio", "public.aiff-audio"], in: .import)
        documentPicker.delegate = self
        documentPicker.modalPresentationStyle = UIModalPresentationStyle.fullScreen
        present(documentPicker, animated: true, completion: nil)
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

    func setupAudioCropSliderView() {
        if mergeSlidervw == nil {
            mergeSlidervw = OptiRangeSliderView(frame: CGRect(x: 20, y: -15, width: sliderAudioView.frame.size.width - 40, height: sliderAudioView.frame.size.height))
            mergeSlidervw.delegate = self
            mergeSlidervw.tag = 2
            mergeSlidervw.thumbTintColor = UIColor.lightGray
            mergeSlidervw.trackHighlightTintColor = UIColor.darkGray
            mergeSlidervw.lowerLabel?.textColor = UIColor.lightGray
            mergeSlidervw.upperLabel?.textColor = UIColor.lightGray
            mergeSlidervw.trackTintColor = UIColor.lightGray
            mergeSlidervw.thumbBorderColor = UIColor.clear
            mergeSlidervw.lowerValue = 0.0
            mergeSlidervw.upperValue = audioTotalsec
            mergeSlidervw.stepValue = 1
            mergeSlidervw.gapBetweenThumbs = 5
            mergeSlidervw.thumbLabelStyle = .FOLLOW
            mergeSlidervw.lowerDisplayStringFormat = "%.0f"
            mergeSlidervw.upperDisplayStringFormat = "%.0f"
            mergeSlidervw.sizeToFit()
            sliderAudioView.addSubview(mergeSlidervw)
        }
    }
}

extension TrimAudioViewController: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        if controller.documentPickerMode == UIDocumentPickerMode.import {
            if urls.count > 0, let urlDocument = urls.first {
                let asset = AVAsset(url: urlDocument)
                audioTotalsec = CMTimeGetSeconds(asset.duration)
                pickedFileName = urlDocument.lastPathComponent
                slctAudioUrl = urlDocument
                txtAudioLbl.text = pickedFileName
                mergeSlidervw.maxValue = audioTotalsec
                mergeSlidervw.maximumValue = CMTimeGetSeconds(asset.duration)
                mergeSlidervw.upperValue = audioTotalsec
                mergesliderminimumValue = 0.0
                mergeslidermaximumValue = audioTotalsec
            }
        }
    }
}

// MARK: UIImagePicker Delegate

extension TrimAudioViewController: OptiRangeSliderViewDelegate {
    func sliderValueChanged(slider: OptiRangeSlider?, slidervw: OptiRangeSliderView) {
        switch slidervw.tag {
        case 2:
            mergesliderminimumValue = slider?.lowerValue ?? 0.0
            mergeslidermaximumValue = slider?.upperValue ?? 0.0
        default:
            break
        }
    }
}
