//
//  FaceDepthManager.swift
//  DepthMapUi
//
//  Created by nao on 2022/11/30.
//

import Foundation

import UIKit
import SceneKit
import ARKit
import Vision
import SwiftUI
import VideoToolbox

class FaceDepthManager: NSObject, ObservableObject, ARSCNViewDelegate, ARSessionDelegate{
    var sceneView: ARSCNView = ARSCNView()
    @Published var colorCGImage: CGImage!
    var colorPixelBuffer: CVPixelBuffer!
    var depthPixelBuffer: CVPixelBuffer!
    var confidencePixelBuffer: CVPixelBuffer!
    let context = CIContext(options: nil)
    var sessionCount = 0
    var isFaceDetected = false
    
    //var colorImageDrawLayer: CALayer?
    //var depthImageDrawLayer: CALayer?
    //private var colorImageFaceViews = [UIView]()
    //private var depthImageFaceViews = [UIView]()
    
    var faceDepth = 0.0
    //var faceDepthBuffer = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
    var faceDepthBuffer = [0.0, 0.0, 0.0, 0.0, 0.0]
    var faceDepthIndex = 0
    
    var bleManager : BMCameraManager!
    var isAutoFocus = false
    var focus = 0.0
    
    
    override init(){
        super.init()
        //start()
    }
    
    public func startAutoFocus(manager: BMCameraManager){
        self.bleManager = manager
        self.isAutoFocus = true
    }
    
    public func stopAutoFocus(){
        self.bleManager = nil
        self.isAutoFocus = false
    }
    
    
    func start() -> Bool{
        var isOk = false
        func buildConfigure() -> ARWorldTrackingConfiguration? {
            let configuration = ARWorldTrackingConfiguration()
            configuration.environmentTexturing = .automatic
            if type(of: configuration).supportsFrameSemantics(.sceneDepth) {
               configuration.frameSemantics = .sceneDepth
            }else{
                return nil
            }
            return configuration
        }
        isFaceDetected = false
        let configuration = buildConfigure()
        if (configuration != nil){
            sceneView.session.run(configuration!)
            sceneView.session.delegate = self
            isOk = true
        }
        return isOk
    }
    
    func stop() {
        sceneView.session.pause()
    }
    
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        if ((session.currentFrame?.capturedImage == nil) ||
            (session.currentFrame?.sceneDepth?.depthMap == nil) ||
            (session.currentFrame?.sceneDepth?.confidenceMap == nil)) {
            return
        }
        colorPixelBuffer = session.currentFrame?.capturedImage
        depthPixelBuffer = session.currentFrame?.sceneDepth?.depthMap
        confidencePixelBuffer = session.currentFrame?.sceneDepth?.confidenceMap
        
        //print(CVPixelBufferGetWidth(colorPixelBuffer), CVPixelBufferGetHeight(colorPixelBuffer))
        //print(sessionCount)
        sessionCount = sessionCount + 1
        
        if (sessionCount % 5 != 0) {
            return
        }
        
        let colorCIImage = CIImage(cvPixelBuffer: self.colorPixelBuffer)
        self.colorCGImage = context.createCGImage(colorCIImage, from: colorCIImage.extent)
        
        DispatchQueue.global(qos: .background).async {
            let request = VNDetectFaceRectanglesRequest(completionHandler: self.handleDetectedFaces)
            let handler = VNImageRequestHandler(cgImage: self.colorCGImage, options: [:])
            try? handler.perform([request])
        }
    }
    
    func handleDetectedFaces(request: VNRequest?, error: Error?) {
        //if let nsError = error as NSError? {
        if error != nil {
            isFaceDetected = false
            return
        }
        
        //DispatchQueue.main.async {
            //_ = self.colorImageFaceViews.map { $0.removeFromSuperview() }
            //self.colorImageFaceViews.removeAll()
            //_ = self.depthImageFaceViews.map { $0.removeFromSuperview() }
            //self.depthImageFaceViews.removeAll()
            
            var faceCount = 0
            for face in request?.results as! [VNFaceObservation] {
                if(faceCount != 0){
                    break
                }
                faceCount += 1
                //print(face.boundingBox)
                let depth = self.getFaceDepth(depthPixelBuffer: self.depthPixelBuffer, face: face)
                faceDepthBuffer[faceDepthIndex] = depth!
                faceDepth = faceDepthBuffer.reduce(0, +) / Double(faceDepthBuffer.count)
                faceDepthIndex = faceDepthIndex + 1
                if (faceDepthIndex >= faceDepthBuffer.count) {
                    faceDepthIndex = 0
                }
                isFaceDetected = true
                //print(self.faceDepth)
                /*
                let colorFaceView = self.getFaceView(uiImageView: self.colorImageView, uiImage: self.colorImage, face: face)
                let depthFaceView = self.getFaceView(uiImageView: self.depthImageView, uiImage: self.depthImage, face: face)
                self.colorImageView.addSubview(colorFaceView)
                self.depthImageView.addSubview(depthFaceView)
                self.colorImageFaceViews.append(colorFaceView)
                self.depthImageFaceViews.append(depthFaceView)
                */
                
                if isAutoFocus {
                    focus = 1693.0 * pow(faceDepth, 0.08)
                    if (focus < 0) {
                        focus = 0
                    }else if (2048 < focus){
                        focus = 2048
                    }
                    DispatchQueue.main.async {
                        self.bleManager.changeFocus(focus: Int(self.focus))
                    }
                }
                print(self.faceDepth, self.focus)
            }
        //}
    }
    
    func getFaceView(uiImageView: UIImageView, uiImage: UIImage, face: VNFaceObservation) -> UIView {
        let aspect = uiImage.size.width / uiImage.size.height
        let boundingBox = face.boundingBox
        let origin = CGPoint(x: boundingBox.minX * uiImageView.bounds.width, y: (1 - boundingBox.maxY) * uiImageView.bounds.height)
        let size = CGSize(width: boundingBox.width * uiImageView.bounds.width, height: boundingBox.height * uiImageView.bounds.height / aspect)
        
        let view = UIView(frame: CGRect(origin: origin, size: size))
        view.layer.borderWidth = 4.0
        view.layer.borderColor = UIColor.red.cgColor
        return view
    }
    
    func getFaceDepth(depthPixelBuffer: CVPixelBuffer, face: VNFaceObservation) -> Double!{
        let boundingBox = face.boundingBox
        let width = CVPixelBufferGetWidth(depthPixelBuffer)
        let height = CVPixelBufferGetHeight(depthPixelBuffer)

        let faceSizeWidth = Int(CGFloat(width) * boundingBox.width)
        let faceSizeHeight = Int(CGFloat(height) * boundingBox.height)
        
        var faceMinWidth = Int(CGFloat(width) * boundingBox.minX)
        faceMinWidth += Int(faceSizeWidth / 4)
        var faceMaxWidth = Int(CGFloat(width) * boundingBox.maxX)
        faceMaxWidth -= Int(faceSizeWidth / 4)
        var faceMinHeight = Int(CGFloat(height) * boundingBox.minY)
        faceMinHeight += Int(faceSizeHeight / 4)
        var faceMaxHeight = Int(CGFloat(height) * boundingBox.maxY)
        faceMaxHeight -= Int(faceSizeHeight / 4)
        
        guard 0 < faceMinWidth, faceMinWidth < width else { return nil}
        guard 0 < faceMaxWidth, faceMaxWidth < width else { return nil}
        guard 0 < faceMinHeight, faceMinHeight < height else { return nil}
        guard 0 < faceMaxHeight, faceMaxHeight < height else { return nil}
        
        CVPixelBufferLockBaseAddress(depthPixelBuffer, .readOnly)
        let base = CVPixelBufferGetBaseAddress(depthPixelBuffer)
        // UnsafeMutableRawPointer -> UnsafeMutablePointer<Float32>
        let bindPtr = base?.bindMemory(to: Float32.self, capacity: width * height)
        // UnsafeMutablePointer -> UnsafeBufferPointer<Float32>
        let bufPtr = UnsafeBufferPointer(start: bindPtr, count: width * height)
        // UnsafeBufferPointer<Float32> -> Array<Float32>
        let depthArray = Array(bufPtr)
        CVPixelBufferUnlockBaseAddress(depthPixelBuffer, .readOnly)
        
        var depthCount = 0
        var depth = 0.0
        for w in faceMinWidth..<faceMaxWidth {
            for h in faceMinHeight..<faceMaxHeight {
                depth += Double(depthArray[width * h + w])
                depthCount += 1
            }
        }
        depth /= Double(depthCount)
        return depth
    }
}

extension ARFrame {
    func imageTransformedImage(orientation: UIInterfaceOrientation, viewPort: CGRect) -> UIImage? {
        let pixelBuffer = self.capturedImage
        //let imageSize = CGSize(width: pixelBuffer.width, height: pixelBuffer.height)
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        return UIImage(ciImage: screenTransformed(ciImage: ciImage, orientation: orientation, viewPort: viewPort))
    }
    
    func depthMapTransformedImage(orientation: UIInterfaceOrientation, viewPort: CGRect) -> UIImage? {
        guard let pixelBuffer = self.sceneDepth?.depthMap else { return nil }
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        return UIImage(ciImage: screenTransformed(ciImage: ciImage, orientation: orientation, viewPort: viewPort))
    }
    
    func depthMapTransformedImage2(orientation: UIInterfaceOrientation, viewPort: CGRect) -> CIImage? {
        guard let pixelBuffer = self.sceneDepth?.depthMap else { return nil }
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        return screenTransformed(ciImage: ciImage, orientation: orientation, viewPort: viewPort)
    }

    func ConfidenceMapTransformedImage(orientation: UIInterfaceOrientation, viewPort: CGRect) -> UIImage? {
        guard let pixelBuffer = self.sceneDepth?.confidenceMap,
              let ciImage = confidenceMapToCIImage(pixelBuffer: pixelBuffer) else { return nil }
        
        return UIImage(ciImage: screenTransformed(ciImage: ciImage, orientation: orientation, viewPort: viewPort))
    }

    func confidenceMapToCIImage(pixelBuffer: CVPixelBuffer) -> CIImage? {
        func confienceValueToPixcelValue(confidenceValue: UInt8) -> UInt8 {
            guard confidenceValue <= ARConfidenceLevel.high.rawValue else {return 0}
            return UInt8(floor(Float(confidenceValue) / Float(ARConfidenceLevel.high.rawValue) * 255))
        }
        CVPixelBufferLockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: 0))
        guard let base = CVPixelBufferGetBaseAddress(pixelBuffer) else { return nil }
        let height = CVPixelBufferGetHeight(pixelBuffer)
        let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)

        for i in stride(from: 0, to: bytesPerRow*height, by: MemoryLayout<UInt8>.stride) {
            let data = base.load(fromByteOffset: i, as: UInt8.self)
            let pixcelValue = confienceValueToPixcelValue(confidenceValue: data)
            base.storeBytes(of: pixcelValue, toByteOffset: i, as: UInt8.self)
        }
        CVPixelBufferUnlockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: 0))

        return CIImage(cvPixelBuffer: pixelBuffer)
    }

    func screenTransformed(ciImage: CIImage, orientation: UIInterfaceOrientation, viewPort: CGRect) -> CIImage {
        let transform = screenTransform(orientation: orientation, viewPortSize: viewPort.size, captureSize: ciImage.extent.size)
        return ciImage.transformed(by: transform).cropped(to: viewPort)
    }

    func screenTransform(orientation: UIInterfaceOrientation, viewPortSize: CGSize, captureSize: CGSize) -> CGAffineTransform {
        let normalizeTransform = CGAffineTransform(scaleX: 1.0/captureSize.width, y: 1.0/captureSize.height)
        let flipTransform = (orientation.isPortrait) ? CGAffineTransform(scaleX: -1, y: -1).translatedBy(x: -1, y: -1) : .identity
        let displayTransform = self.displayTransform(for: orientation, viewportSize: viewPortSize)
        let toViewPortTransform = CGAffineTransform(scaleX: viewPortSize.width, y: viewPortSize.height)
        return normalizeTransform.concatenating(flipTransform).concatenating(displayTransform).concatenating(toViewPortTransform)
    }

    fileprivate func createTexture(fromPixelBuffer pixelBuffer: CVPixelBuffer, pixelFormat: MTLPixelFormat, planeIndex: Int, textureCache: CVMetalTextureCache) -> CVMetalTexture? {
        let width = CVPixelBufferGetWidthOfPlane(pixelBuffer, planeIndex)
        let height = CVPixelBufferGetHeightOfPlane(pixelBuffer, planeIndex)
        
        var texture: CVMetalTexture? = nil
        let status = CVMetalTextureCacheCreateTextureFromImage(nil, textureCache, pixelBuffer, nil, pixelFormat,
                                                               width, height, planeIndex, &texture)
        
        if status != kCVReturnSuccess {
            texture = nil
        }
        
        return texture
    }

    func buildCapturedImageTextures(textureCache: CVMetalTextureCache) -> (textureY: CVMetalTexture, textureCbCr: CVMetalTexture)? {
        // Create two textures (Y and CbCr) from the provided frame's captured image
        let pixelBuffer = self.capturedImage
        
        guard CVPixelBufferGetPlaneCount(pixelBuffer) >= 2 else {
            return nil
        }
        
        guard let capturedImageTextureY = createTexture(fromPixelBuffer: pixelBuffer, pixelFormat: .r8Unorm, planeIndex: 0, textureCache: textureCache),
              let capturedImageTextureCbCr = createTexture(fromPixelBuffer: pixelBuffer, pixelFormat: .rg8Unorm, planeIndex: 1, textureCache: textureCache) else {
            return nil
        }
        
        return (textureY: capturedImageTextureY, textureCbCr: capturedImageTextureCbCr)
    }

    func buildDepthTextures(textureCache: CVMetalTextureCache) -> (depthTexture: CVMetalTexture, confidenceTexture: CVMetalTexture)? {
        guard let depthMap = self.sceneDepth?.depthMap,
            let confidenceMap = self.sceneDepth?.confidenceMap else {
                return nil
        }
        
        guard let depthTexture = createTexture(fromPixelBuffer: depthMap, pixelFormat: .r32Float, planeIndex: 0, textureCache: textureCache),
              let confidenceTexture = createTexture(fromPixelBuffer: confidenceMap, pixelFormat: .r8Uint, planeIndex: 0, textureCache: textureCache) else {
            return nil
        }
        
        return (depthTexture: depthTexture, confidenceTexture: confidenceTexture)
    }
}
