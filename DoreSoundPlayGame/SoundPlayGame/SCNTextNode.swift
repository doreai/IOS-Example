//
//  SCNTextNode.swift
//  DoreSoundPlayGame
//
//  Created by Sam on 06/03/20.


import SceneKit

public class SCNTextNode: SCNNode {
    /**
    The string object whose text the geometry represents.


    You can supply text as an [NSString](apple-reference-documentation://hsdPnFRdoM) or [NSAttributedString](apple-reference-documentation://hsTWYmDnAB) object.

    See [string parameter under SCNText](apple-reference-documentation://hs9D4jCGTx) for more details.
    */
    var string: Any? = nil {
        didSet {
            if let textGeometry = self.textGeometry, let str = self.string {
                textGeometry.string = str
                self.resetScale()
            }
        }
    }

    private var textRepositioner = SCNNode()
    private var textGeometry: SCNText? = nil

    public var materials: [SCNMaterial] {
        get {
            return self.textGeometry?.materials ?? []
        }
        set {
            self.textGeometry?.materials = materials
        }
    }
    
    public func getText() -> SCNText? {
        return self.textGeometry
    }

    public var firstMaterial: SCNMaterial? {
        get {
            return self.textGeometry?.firstMaterial
        }
        set {
            self.textGeometry?.firstMaterial = firstMaterial
        }
    }

    /// Allow the text to be wrapped by the SCNText geometry - Currently forced to `false`
    private var isWrapped: Bool = false {
        didSet {
//            if let textGeometry = self.textGeometry {
//                textGeometry.isWrapped = isWrapped
//                self.resetScale()
//            }
        }
    }
    /// Fixed width for the text. If the text is smaller than this it will scale it up.
    public var fixedWidth: Float {
        didSet {
            if self.textGeometry != nil {
                self.resetScale()
            }
        }
    }
    /// A number that determines the accuracy or smoothness of the text geometry.
    ///
    public var flatness: CGFloat {
        didSet {
            if let textGeometry = self.textGeometry {
                textGeometry.flatness = self.flatness
            }
        }
    }
    /// Forced scale for the text, only really useful once wrapping is enabled
    public var textScale: SCNVector3 {
        didSet {
            if self.textGeometry != nil {
                self.resetScale()
            }
        }
    }

    /**
    Initializes a new SCNNode containing a geometry in the system or provided font with the appropriate scale.
    **All parameters are optional.**

    - Parameters:
        - text: The string object whose text the geometry represents. Provide NSString or NSAttributedString
        - width: The desired width or length your string should be
        - font: The UIFont desired for this text node
        - textScale: The scale on the text before setting to a width. Has no effect if isWrapped is false
        - depth:  How deep the 3D text object is, default 1.0

    - Returns: A node that contains the text centred in all 3 axis scaled to the desired width.
    */
    public init(text: Any? = nil, width: Float = Float.greatestFiniteMagnitude, isWrapped: Bool = false, font: UIFont? = nil, textScale: Float = 1, depth: CGFloat = 1.0, flatness: CGFloat = 0.6) {
        let textGeom = SCNText(string: text, extrusionDepth: depth)
        let customFont = font ?? UIFont.systemFont(ofSize: UIFont.systemFontSize)
        textGeom.font = customFont
        textGeom.flatness = flatness
        self.isWrapped = isWrapped
        textGeom.isWrapped = false
        self.textScale = SCNVector3(textScale, textScale, 1)
        self.fixedWidth = width
        self.flatness = flatness
        super.init()
        self.textRepositioner.scale = self.textScale
        self.string = text
        self.textGeometry = textGeom
        self.textRepositioner.geometry = textGeom
        self.addChildNode(self.textRepositioner)
        self.resetScale()
    }

    private func resetScale() {
        if self.string == nil {
            print("Text is nil")
            return
        }
        self.textGeometry?.isWrapped = self.isWrapped
        self.scale = SCNVector3(1,1,1)
        self.textRepositioner.scale = textScale
        let thisScale = self.fixedWidth / self.boundingBox.max.x
        self.scale = SCNVector3(thisScale, thisScale, 1)
        let rpGeom = self.textRepositioner.boundingBox
        self.textRepositioner.position = SCNVector3(-(rpGeom.max.x + rpGeom.min.x) / 2, -(rpGeom.max.y + rpGeom.min.y) / 2, 0)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
