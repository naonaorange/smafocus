//
//  QrCodeDepthManager.swift
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

class QrCodeDepthManager: NSObject, ObservableObject, ARSCNViewDelegate, ARSessionDelegate{
    var sceneView: ARSCNView = ARSCNView()
    @Published var colorCGImage: CGImage!
    var colorCIImage: CIImage!
    var colorPixelBuffer: CVPixelBuffer!
    var depthPixelBuffer: CVPixelBuffer!
    var confidencePixelBuffer: CVPixelBuffer!
    let context = CIContext(options: nil)
    var sessionCount = 0
    var isQrCodeDetected = false
    @Published var imageSize : CGSize!
    @Published var qrCodeRect : CGRect!
    
    var qrCodeDepth = 0.0
    var qrCodeDepthBuffer = [0.0, 0.0, 0.0, 0.0, 0.0]
    var qrCodeDepthIndex = 0
    
    var bleManager : BMCameraManager!
    var isAutoFocus = false
    var focus = 0.0
    
    override init(){
        super.init()
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
        isQrCodeDetected = false
        let configuration = buildConfigure()
        if (configuration != nil){
            sceneView.session.run(configuration!)
            sceneView.session.delegate = self
            isOk = true
        }
        return isOk
    }
    
    func stop() {
        //sceneView.session.pause()
        //sceneView.session.delegate = nil
    }
    
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        if ((session.currentFrame?.capturedImage == nil) ||
            (session.currentFrame?.sceneDepth?.depthMap == nil) ||
            (session.currentFrame?.sceneDepth?.confidenceMap == nil)){
            return
        }
        
        colorPixelBuffer = session.currentFrame?.capturedImage
        depthPixelBuffer = session.currentFrame?.sceneDepth?.depthMap
        confidencePixelBuffer = session.currentFrame?.sceneDepth?.confidenceMap
        
        //1920, 1440
        imageSize = CGSize(width: CVPixelBufferGetWidth(colorPixelBuffer), height: CVPixelBufferGetHeight(colorPixelBuffer))
        //print(sessionCount)
        sessionCount = sessionCount + 1
        
        if (sessionCount % 5 != 0) {
            return
        }
        
        self.colorCIImage = CIImage(cvPixelBuffer: self.colorPixelBuffer)
        self.colorCGImage = context.createCGImage(colorCIImage, from: colorCIImage.extent)
        
        DispatchQueue.global(qos: .background).async {
            let request = VNDetectBarcodesRequest(completionHandler: self.handleDetectedQrCode)
            let handler = VNImageRequestHandler(cgImage: self.colorCGImage, options: [:])
            try? handler.perform([request])
        }
    }
    
    func handleDetectedQrCode(request: VNRequest?, error: Error?) {
        if error != nil {
            isQrCodeDetected = false
            qrCodeRect = nil
            return
        }
            
        if (request?.results?.count == 0) {
            DispatchQueue.main.async {
                self.qrCodeRect = nil
            }
            return
        }
        
        var qrCodeCount = 0
        for qrCode in request?.results as! [VNBarcodeObservation] {
            if(qrCodeCount != 0){
                break
            }
            qrCodeCount += 1
            guard let depth = self.getQrCodeDepth(depthPixelBuffer: self.depthPixelBuffer, qrCode: qrCode) else{
                return
            }
            qrCodeDepthBuffer[qrCodeDepthIndex] = depth
            qrCodeDepth = qrCodeDepthBuffer.reduce(0, +) / Double(qrCodeDepthBuffer.count)
            qrCodeDepthIndex = qrCodeDepthIndex + 1
            if (qrCodeDepthIndex >= qrCodeDepthBuffer.count) {
                qrCodeDepthIndex = 0
            }
            isQrCodeDetected = true
            
            DispatchQueue.main.async {
                self.qrCodeRect = qrCode.boundingBox
            }
            /*
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
            */
        }
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
    
    func getQrCodeDepth(depthPixelBuffer: CVPixelBuffer, qrCode: VNBarcodeObservation) -> Double!{
        let boundingBox = qrCode.boundingBox
        let width = CVPixelBufferGetWidth(depthPixelBuffer)
        let height = CVPixelBufferGetHeight(depthPixelBuffer)

        let sizeWidth = Int(CGFloat(width) * boundingBox.width)
        let sizeHeight = Int(CGFloat(height) * boundingBox.height)
        
        var minWidth = Int(CGFloat(width) * boundingBox.minX)
        minWidth += Int(sizeWidth / 4)
        var maxWidth = Int(CGFloat(width) * boundingBox.maxX)
        maxWidth -= Int(sizeWidth / 4)
        var minHeight = Int(CGFloat(height) * boundingBox.minY)
        minHeight += Int(sizeHeight / 4)
        var maxHeight = Int(CGFloat(height) * boundingBox.maxY)
        maxHeight -= Int(sizeHeight / 4)
        
        guard 0 < minWidth, minWidth < width else { return nil}
        guard 0 < maxWidth, maxWidth < width else { return nil}
        guard 0 < minHeight, minHeight < height else { return nil}
        guard 0 < maxHeight, maxHeight < height else { return nil}
        
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
        for w in minWidth..<maxWidth {
            for h in minHeight..<maxHeight {
                depth += Double(depthArray[width * h + w])
                depthCount += 1
            }
        }
        depth /= Double(depthCount)
        return depth
    }
}
