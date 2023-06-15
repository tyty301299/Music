//
//  AudioViewController.swift
//  Music
//
//  Created by Nguyen Ty on 15/06/2023.
//

import AVKit
import MediaPlayer
import MobileCoreServices
import Photos
import UIKit

protocol DataDelegate: ViewController {
    func dataAudioModel(index: Int, audioModel: AudioModel)
}

class AudioViewController: UIViewController {
    @IBOutlet var txtAudioLbl: UILabel!
    @IBOutlet var sliderAudioView: UIView!
    weak var delegate: DataDelegate?
    // rangeSlider
    var rangeSlider: SlickRangeSlider!
    var mergeSlidervw: OptiRangeSliderView!

    var audioTotalsec = 0.0
    var pickedFileName: String = ""
    var slctAudioUrl: URL?
    var videoUrl: URL

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

    required init(videoUrl: URL, data: AudioModel, slctAudioUrl: URL? = nil, selectedTableViewCell: Int = -1) {
        self.videoUrl = videoUrl
        self.selectedTableViewCell = selectedTableViewCell
        self.slctAudioUrl = slctAudioUrl
        self.data = data
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        mergesliderminimumValue = data.startTime ?? 0.0
        mergeslidermaximumValue = data.endTime ?? 0.0
        txtAudioLbl?.text = data.fileName
        setupAudioCropSliderView()
        setupSilder()
        if selectedTableViewCell == -1 {
            sliderAudioView.isHidden = true
        }
        // Do any additional setup after loading the view.
    }

    @IBAction func selectedAudio(_ sender: Any) {
        let documentPicker: UIDocumentPickerViewController = UIDocumentPickerViewController(documentTypes: ["public.audio", "public.mp3", "public.mpeg-4-audio", "public.aifc-audio", "public.aiff-audio"], in: .import)
        documentPicker.delegate = self
        documentPicker.modalPresentationStyle = UIModalPresentationStyle.fullScreen
        present(documentPicker, animated: true, completion: nil)
    }

    @IBAction func saveAudio(_ sender: Any) {
        data.volume = 0.5
        if selectedTableViewCell == -1 {
            data.endTime = mergeslidermaximumValue
            data.startTime = mergesliderminimumValue
        }
        else {
            data.startVideo = mergesliderminimumValue
        }
        data.audioURL = slctAudioUrl
        data.fileName = pickedFileName
        delegate?.dataAudioModel(index: selectedTableViewCell, audioModel: data)
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
            mergeSlidervw.lowerValue = mergesliderminimumValue
            mergeSlidervw.upperValue = mergeslidermaximumValue
            mergeSlidervw.stepValue = 1
            mergeSlidervw.gapBetweenThumbs = 5
            mergeSlidervw.thumbLabelStyle = .FOLLOW
            mergeSlidervw.lowerDisplayStringFormat = "%.0f"
            mergeSlidervw.upperDisplayStringFormat = "%.0f"
            mergeSlidervw.sizeToFit()
            sliderAudioView.addSubview(mergeSlidervw)
        }
    }

    func setupSilder() {
        guard let slctAudioUrl = slctAudioUrl else { return }
        let asset = AVAsset(url: slctAudioUrl)
        let assetVideo = AVAsset(url: videoUrl)
        audioTotalsec = CMTimeGetSeconds(assetVideo.duration) < CMTimeGetSeconds(asset.duration) ? CMTimeGetSeconds(assetVideo.duration) : CMTimeGetSeconds(asset.duration)
        pickedFileName = slctAudioUrl.lastPathComponent
        txtAudioLbl.text = pickedFileName
        mergeSlidervw.maxValue = audioTotalsec
        mergeSlidervw.maximumValue = CMTimeGetSeconds(assetVideo.duration)
        mergeSlidervw.upperValue = audioTotalsec
        mergesliderminimumValue = 0.0
        mergeslidermaximumValue = audioTotalsec
    }
}

extension AudioViewController: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        if controller.documentPickerMode == UIDocumentPickerMode.import {
            if urls.count > 0, let urlDocument = urls.first {
                let asset = AVAsset(url: urlDocument)
                let assetVideo = AVAsset(url: videoUrl)
                slctAudioUrl = urlDocument
                audioTotalsec = CMTimeGetSeconds(assetVideo.duration) < CMTimeGetSeconds(asset.duration) ? CMTimeGetSeconds(assetVideo.duration) : CMTimeGetSeconds(asset.duration)
                pickedFileName = urlDocument.lastPathComponent
                slctAudioUrl = urlDocument
                txtAudioLbl.text = pickedFileName
                mergeSlidervw.maxValue = audioTotalsec
                mergeSlidervw.maximumValue = CMTimeGetSeconds(assetVideo.duration)
                mergeSlidervw.upperValue = audioTotalsec
                if selectedTableViewCell != -1, let start = data.startTime, let end = data.endTime {
                    mergesliderminimumValue = start
                    mergeslidermaximumValue = end
                } else {
                    mergesliderminimumValue = 0.0
                    mergeslidermaximumValue = audioTotalsec
                }
            }
        }
    }
}

// MARK: UIImagePicker Delegate

extension AudioViewController: OptiRangeSliderViewDelegate {
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
