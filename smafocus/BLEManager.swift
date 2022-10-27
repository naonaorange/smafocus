//
//  BLEManagerViewModel.swift
//  BLESample
//
//  Created by nao on 2022/10/22.
//

import Foundation
import CoreBluetooth

class BLEManager: NSObject, Identifiable, ObservableObject, CBCentralManagerDelegate, CBPeripheralDelegate{
    @Published var isScaning : Bool = false
    @Published var isConnecting : Bool = false
    @Published var peripherals : [Peripherals] = []
    @Published var connectionPeripheral : CBPeripheral?
    @Published var receivedData : String = ""
    @Published var isReadyToTransmit : Bool = true
    
    public var changeConnectionState : (() -> Void)!
    
    var centralManager : CBCentralManager!
    
    struct Peripherals: Identifiable{
        var id = UUID()
        var name : String
        var peripheral : CBPeripheral
    }
    
    override init(){
        super.init()
        print("BLEManager Init")
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    func startScan(){
        if (!isScaning){
            isScaning = true
            peripherals = []
            centralManager.scanForPeripherals(withServices: BLEServiceSetting.advertisedServiceUUIDs)
        }
    }
    
    func stopScan(){
        if (isScaning){
            isScaning = false
            centralManager.stopScan()
        }
    }
    
    func connect(peripheralName: String){
        if (peripheralName == ""){
            return
        }
        var isFoundPeripheral = false
        peripherals.forEach{ p in
            if(peripheralName == p.name){
                isFoundPeripheral = true
                connectionPeripheral = p.peripheral
            }
        }
        if(isFoundPeripheral){
            centralManager.connect(connectionPeripheral!)
            peripherals = []
        }
    }
    
    func disconnect(){
        guard let peripheral = connectionPeripheral else{
            return
        }
        centralManager.cancelPeripheralConnection(peripheral)
    }
    
    func write(data: Data, characteristic: CBCharacteristic, withResponse: Bool){
        if (isReadyToTransmit){
            if withResponse {
                connectionPeripheral?.writeValue(data, for: characteristic, type: CBCharacteristicWriteType.withResponse)
                isReadyToTransmit = false
            }else{
                connectionPeripheral?.writeValue(data, for: characteristic, type: CBCharacteristicWriteType.withoutResponse)
            }
        }
    }
    
    //This callback is called when the state of manager is change
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        print("[BLEManager] the state of manager is changed : \(central.state)")
        switch(central.state){
        case CBManagerState.poweredOn:
            startScan()
        default:
            break
        }
        
    }
    
    //This callback is called when it is found a periheral
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        guard let name = peripheral.name else{
            return
        }
        var isAlreadyScaned = false
        peripherals.forEach{ p in
            if (p.peripheral.name == name){
                isAlreadyScaned = true
            }
        }
        
        if(!isAlreadyScaned) {
            peripherals.append(Peripherals(name: name, peripheral: peripheral))
        }
        print("[BLEManager] Peripheral is found : " + name)
    }
    
    //This Callback is called when a connection is successed
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("[BLEManager] Success to connect")
        peripheral.delegate = self
        peripheral.discoverServices(nil)
    }
    
    //This callback is called when a connection is failed
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("[BLEManager] Failed to connect")
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        isConnecting = false
        startScan()
        
        print("[BLEManager] Disconected to peripheral")
        
    }
    
    //This callback is called when a service discover is found
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let error = error {
            print("[BLEManager] Failed to discover a service  \(error)")
            return
        }
        guard let services = peripheral.services, services.count > 0 else{
            print("[BLEManager] Peripheral does not have any service")
            return
        }
        for service in services{
            peripheral.discoverCharacteristics(nil, for: service)
        }
        print("[BLEManager] Success to discover a service")
    }
    
    //This callback is called when a characteristic discover is found
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let error = error {
            print("[BLEManager] Failed to discover a characteristic  \(error)")
            return
        }
        guard let characteristics = service.characteristics, characteristics.count > 0 else{
            print("[BLEManager] Service does not have any characteristic")
            return
        }
        for characteristic in characteristics {
            if characteristic.properties.contains(.read){
                peripheral.readValue(for: characteristic)
            }
        }
        print("[BLEManager] Success to discover a characteristic")
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        print("[BLEManager] Success to write a characteristic")
        isReadyToTransmit = true
    }
    
    //This function is called when a characteristic is updated
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            print("[BLEManager] Failed to update a characteristic  \(error)")
            return
        }
        if(characteristic.uuid.isEqual(CBUUID(string: "2A24"))){
            guard let data = characteristic.value else{
                return
            }
            receivedData = String(bytes: data, encoding: .utf8)!
            
            isConnecting = true
            isScaning = false
            stopScan()
        }
        print("[BLEManager] Success to update a characteristic")
    }
}
