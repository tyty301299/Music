//
//  OptiRangeSliderView.swift
//  Music
//
//  Created by Nguyen Ty on 12/06/2023.
//

import Foundation
import UIKit

var totalSEC = 0.0

extension UIColor {
    convenience init(hex: Int, alpha: Double = 1.0) {
        self.init(red: CGFloat((hex >> 16) & 0xFF) / 255.0, green: CGFloat((hex >> 8) & 0xFF) / 255.0, blue: CGFloat(hex & 0xFF) / 255.0, alpha: CGFloat(255 * alpha) / 255)
    }
}

/// enum for label positions
public enum NHSliderLabelStyle: Int {
    /// lower and upper labels stick to the left and right of slider
    case STICKY

    /// lower and upper labels follow position of lower and upper thumbs
    case FOLLOW
}

/// delegate for changed value
public protocol OptiRangeSliderViewDelegate: class {
    /// slider value changed
    func sliderValueChanged(slider: OptiRangeSlider?, slidervw: OptiRangeSliderView)
}

/// optional implementation
public extension OptiRangeSliderViewDelegate {
    func sliderValueChanged(slider: OptiRangeSlider?, slidervw: OptiRangeSliderView) {}
}

/// Range slider with labels for upper and lower thumbs, title label and configurable step value (optional)
open class OptiRangeSliderView: UIView {
    // MARK: properties

    open var delegate: OptiRangeSliderViewDelegate?

    /// Range slider
    open var rangeSlider: OptiRangeSlider?

    /// Display title
    open var titleLabel: UILabel?

    // lower value label for displaying selected lower value
    open var lowerLabel: UILabel?

    /// upper value label for displaying selected upper value
    open var upperLabel: UILabel?

    /// display format for lower value. Default to %.0f to display value as Int
    open var lowerDisplayStringFormat: String = "%.0f" {
        didSet {
            updateLabelDisplay()
        }
    }

    /// display format for upper value. Default to %.0f to display value as Int
    open var upperDisplayStringFormat: String = "%.0f" {
        didSet {
            updateLabelDisplay()
        }
    }

    /// vertical spacing
    open var spacing: CGFloat = 4.0

    /// position of thumb labels. Set to STICKY to stick to left and right positions. Set to FOLLOW to follow left and right thumbs
    open var thumbLabelStyle: NHSliderLabelStyle = .STICKY

    /// minimum value
    @IBInspectable open var minimumValue: Double = 0.0 {
        didSet {
            rangeSlider?.minimumValue = minimumValue
        }
    }

    @IBInspectable open var maxValue: Double = 0.0 {
        didSet {
            rangeSlider?.maxValue = maxValue
        }
    }

    /// max value
    @IBInspectable open var maximumValue: Double = totalSEC {
        didSet {
            rangeSlider?.maximumValue = maximumValue
        }
    }

    /// value for lower thumb
    @IBInspectable open var lowerValue: Double = 0.0 {
        didSet {
            rangeSlider?.lowerValue = lowerValue
            updateLabelDisplay()
        }
    }

    /// value for upper thumb
    @IBInspectable open var upperValue: Double = totalSEC {
        didSet {
            rangeSlider?.upperValue = upperValue
            updateLabelDisplay()
        }
    }

    /// stepValue. If set, will snap to discrete step points along the slider . Default to nil
    @IBInspectable open var stepValue: Double = 0.0 {
        didSet {
            self.rangeSlider?.stepValue = stepValue
        }
    }

    /// minimum distance between the upper and lower thumbs.
    open var gapBetweenThumbs: Double = 2.0 {
        didSet {
            rangeSlider?.gapBetweenThumbs = gapBetweenThumbs
        }
    }

    /// tint color for track between 2 thumbs
    @IBInspectable open var trackTintColor: UIColor = UIColor(white: 0.9, alpha: 1.0) {
        didSet {
            rangeSlider?.trackTintColor = trackTintColor
        }
    }

    /// track highlight tint color
    @IBInspectable open var trackHighlightTintColor: UIColor = UIColor(red: 0.0, green: 0.45, blue: 0.94, alpha: 1.0) {
        didSet {
            rangeSlider?.trackHighlightTintColor = trackHighlightTintColor
        }
    }

    /// thumb tint color
    @IBInspectable open var thumbTintColor: UIColor = UIColor.white {
        didSet {
            rangeSlider?.thumbTintColor = thumbTintColor
        }
    }

    /// thumb border color
    @IBInspectable open var thumbBorderColor: UIColor = UIColor.gray {
        didSet {
            rangeSlider?.thumbBorderColor = thumbBorderColor
        }
    }

    /// thumb border width
    @IBInspectable open var thumbBorderWidth: CGFloat = 0.5 {
        didSet {
            rangeSlider?.thumbBorderWidth = thumbBorderWidth
        }
    }

    /// set 0.0 for square thumbs to 1.0 for circle thumbs
    @IBInspectable open var curvaceousness: CGFloat = 1.0 {
        didSet {
            rangeSlider?.curvaceousness = curvaceousness
        }
    }

    /// thumb width and height
    @IBInspectable open var thumbSize: CGFloat = 32.0 {
        didSet {
            if let slider = rangeSlider {
                var oldFrame = slider.frame
                oldFrame.size.height = thumbSize
                slider.frame = oldFrame
            }
        }
    }

    // MARK: init

    override public init(frame: CGRect) {
        super.init(frame: frame)

        setup()
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        setup()
    }

    /// setup
    open func setup() {
        autoresizingMask = [.flexibleWidth]

        titleLabel = UILabel(frame: .zero)
        titleLabel?.numberOfLines = 1
        titleLabel?.font = UIFont.boldSystemFont(ofSize: 16.0)
        titleLabel?.text = ""
        addSubview(titleLabel!)

        lowerLabel = UILabel(frame: .zero)
        lowerLabel?.numberOfLines = 1
        lowerLabel?.font = UIFont.systemFont(ofSize: 14.0)
        lowerLabel?.text = ""
        lowerLabel?.textColor = UIColor.white
        lowerLabel?.textAlignment = .center
        addSubview(lowerLabel!)

        upperLabel = UILabel(frame: .zero)
        upperLabel?.numberOfLines = 1
        upperLabel?.font = UIFont.systemFont(ofSize: 14.0)
        upperLabel?.text = ""
        upperLabel?.textColor = UIColor.white
        upperLabel?.textAlignment = .center
        addSubview(upperLabel!)

        rangeSlider = OptiRangeSlider(frame: .zero)
        addSubview(rangeSlider!)

        updateLabelDisplay()

        rangeSlider?.addTarget(self, action: #selector(rangeSliderValueChanged(_:)), for: .valueChanged)
    }

    func getTimeStringFromSeconds(seconds: Double) -> String {
        let dcFormatter = DateComponentsFormatter()
        dcFormatter.zeroFormattingBehavior = DateComponentsFormatter.ZeroFormattingBehavior.pad
        if seconds > 3600 {
            dcFormatter.allowedUnits = [NSCalendar.Unit.hour, NSCalendar.Unit.minute, NSCalendar.Unit.second]
        } else {
            dcFormatter.allowedUnits = [NSCalendar.Unit.minute, NSCalendar.Unit.second]
        }

        dcFormatter.unitsStyle = DateComponentsFormatter.UnitsStyle.positional

        return dcFormatter.string(from: seconds)!
    }

    // MARK: range slider delegage

    /// Range slider change events. Upper / lower labels will be updated accordingly.
    /// Selected value for filterItem will also be updated
    ///
    /// - Parameter rangeSlider: the changed rangeSlider
    @objc open func rangeSliderValueChanged(_ rangeSlider: OptiRangeSlider) {
        delegate?.sliderValueChanged(slider: rangeSlider, slidervw: self)

        updateLabelDisplay()
    }

    // MARK: -

    // update labels display
    open func updateLabelDisplay() {
        // self.lowerLabel?.text = String(format: self.lowerDisplayStringFormat, rangeSlider!.lowerValue )
        // self.upperLabel?.text = String(format: self.upperDisplayStringFormat, rangeSlider!.upperValue )

        let lowerVal = getTimeStringFromSeconds(seconds: rangeSlider!.lowerValue)
        let upperVal = getTimeStringFromSeconds(seconds: rangeSlider!.upperValue)

        lowerLabel?.text = lowerVal
        upperLabel?.text = upperVal

        if lowerLabel != nil {
            // for stepped value we animate the labels
            if thumbLabelStyle == .FOLLOW {
                UIView.animate(withDuration: 0.1, animations: {
                    self.layoutSubviews()
                })
            } else {
                setNeedsLayout()
                layoutIfNeeded()
            }
        }
    }

    /// layout subviews
    override open func layoutSubviews() {
        super.layoutSubviews()

        if let titleLabel = titleLabel, let lowerLabel = lowerLabel,
           let upperLabel = upperLabel, let rangeSlider = rangeSlider {
            let commonWidth = bounds.width
            if !titleLabel.isHidden && titleLabel.text != nil && titleLabel.text!.count > 0 {
                titleLabel.frame = CGRect(x: 0, y: 0, width: commonWidth, height: titleLabel.font.lineHeight + spacing)
            }

            rangeSlider.frame = CGRect(x: 0, y: titleLabel.frame.origin.y + titleLabel.frame.size.height + spacing, width: commonWidth, height: thumbSize)

            let lowerWidth = estimatelabelSize(font: lowerLabel.font, string: lowerLabel.text!, constrainedToWidth: Double(commonWidth)).width
            let upperWidth = estimatelabelSize(font: upperLabel.font, string: upperLabel.text!, constrainedToWidth: Double(commonWidth)).width

            var lowerLabelX: CGFloat = 0
            var upperLabelX: CGFloat = 0

            if thumbLabelStyle == .FOLLOW {
                lowerLabelX = rangeSlider.lowerThumbLayer.frame.midX - lowerWidth / 2
                upperLabelX = rangeSlider.upperThumbLayer.frame.midX - upperWidth / 2
            } else {
                // fix lower label to left and upper label to right
                lowerLabelX = rangeSlider.frame.origin.x + spacing
                upperLabelX = rangeSlider.frame.origin.x + rangeSlider.frame.size.width - thumbSize + spacing
            }

            lowerLabel.frame = CGRect(x: lowerLabelX, y: rangeSlider.frame.size.height + 20, width: lowerWidth, height: lowerLabel.font.lineHeight + spacing)

            upperLabel.frame = CGRect(x: upperLabelX, y: rangeSlider.frame.size.height + 20, width: upperWidth, height: upperLabel.font.lineHeight + spacing)
        }
    }

    // return the best size that fit within the box
    override open func sizeThatFits(_ size: CGSize) -> CGSize {
        if let titleLabel = titleLabel, let lowerLabel = lowerLabel {
            var height: CGFloat = 0
            var titleLabelMaxY: CGFloat = 0
            if !titleLabel.isHidden && titleLabel.text != nil && titleLabel.text!.count > 0 {
                titleLabelMaxY = titleLabel.font.lineHeight + spacing
            }
            height = titleLabelMaxY + lowerLabel.font.lineHeight + spacing + thumbSize
            return CGSize(width: size.width, height: height)
        }
        return size
    }

    /// get size for string of this font
    ///
    /// - parameter font: font
    /// - parameter string: a string
    /// - parameter width:  constrained width
    ///
    /// - returns: string size for constrained width
    private func estimatelabelSize(font: UIFont, string: String, constrainedToWidth width: Double) -> CGSize {
        return string.boundingRect(with: CGSize(width: width, height: Double.greatestFiniteMagnitude),
                                   options: NSStringDrawingOptions.usesLineFragmentOrigin,
                                   attributes: [NSAttributedString.Key.font: font],
                                   context: nil).size
    }
}
