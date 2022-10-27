//
//  BMCameraManager.swift
//  smafocus
//
//  Created by nao on 2022/10/23.
//

import Foundation
import CoreBluetooth

class BMCameraManager: BLEManager{
    //var buffer: [UInt8] = [UInt8](repeating: 0, count: Int(headersSize + payloadSize + padBytes))
    var focusMinPacket: [UInt8] = [255, 6, 0, 0, 0, 0, 128, 0, 3, 0, 0, 0]
    var focusMaxPacket: [UInt8] = [255, 6, 0, 0, 0, 0, 128, 0, 0, 8, 0, 0]
    static let outgoingUUID = CBUUID(string: "5DD3465F-1AEE-4299-8493-D2ECA2F8E1BB")
    var outgoingCharacteristic : CBCharacteristic!
    
    override init(){
        super.init()
    }
    
    override func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        super.peripheral(peripheral, didDiscoverCharacteristicsFor: service, error: error)
        
        if let error = error {
            print("[BLEManager] Failed to discover a characteristic  \(error)")
            return
        }
        guard let characteristics = service.characteristics, characteristics.count > 0 else{
            print("[BLEManager] Service does not have any characteristic")
            return
        }
        
        for characteristic in characteristics {
            if characteristic.uuid.isEqual(BMCameraManager.outgoingUUID) {
                print("[BMCameraManager] Found Outgoing characteristic")
                outgoingCharacteristic = characteristic
            }
        }
    }
    
    func changeFocus(focus: Int){
        if((focus < 0) || (2048 < focus)){
            return
        }
        var focusPacket: [UInt8] = [255, 6, 0, 0, 0, 0, 128, 0, 0, 0, 0, 0]
        focusPacket[8] = UInt8(focus & 0xFF)
        focusPacket[9] = UInt8(focus >> 8)
        super.write(data: Data(focusPacket), characteristic: outgoingCharacteristic, withResponse: true)
    }
}
