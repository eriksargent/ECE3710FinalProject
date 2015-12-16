//
//  ViewController.swift
//  RCCar
//
//  Created by Erik Sargent on 11/26/15.
//  Copyright © 2015 eriksargent. All rights reserved.
//

import UIKit
import CoreBluetooth
import CoreMotion

class ViewController: UIViewController {
    //MARK: - Properties
    var centralManager: CBCentralManager!
    var carPeripheral: CBPeripheral?
    
    var motionManager = CMMotionManager()
    
    var label: UILabel!
    
    //MARK: - View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        centralManager = CBCentralManager(delegate: self, queue: nil)
        
        label = UILabel(frame: CGRect(x: view.frame.width / 2 - 150, y: view.frame.height / 2 - 15, width: 300, height: 30))
        label.text = "Searching for car..."
        label.textAlignment = .Center
        label.font = UIFont.systemFontOfSize(20)
        
        view.addSubview(label)
        
        motionManager.deviceMotionUpdateInterval = 0.1
        motionManager.startDeviceMotionUpdatesToQueue(NSOperationQueue.mainQueue()) { motionData, error in
            guard let data = motionData where error == nil else {
                return
            }
            
            let steer = atan2(data.gravity.x, data.gravity.y) - M_PI / 2
            let drive = atan2(data.gravity.x, data.gravity.z) - M_PI / 2
            self.label.transform = CGAffineTransformMakeRotation(CGFloat(steer))
            
            // | Turn Power | Turn H-Bridge | Drive Power | Drive H-Bridge |
            
            var transmitData: UInt8 = 0;
            
            let steerParam = 0.2
            let driveParam = 0.2
            
            transmitData |= min(UInt8(abs(drive) * 3), 3)
            
            transmitData = transmitData << 2
            
            if drive > -driveParam && drive < driveParam {
                transmitData |= 0x3
            } else if drive > driveParam {
                transmitData |= 0x2
            } else {
                transmitData |= 0x1
            }
            
            transmitData = transmitData << 2
            
            transmitData |= min(UInt8(abs(steer) * 3), 3)
            
            transmitData = transmitData << 2
            
            if steer > -steerParam && steer < steerParam {
                transmitData |= 0x3
            } else if steer > steerParam {
                transmitData |= 0x2
            } else {
                transmitData |= 0x1
            }
            
            let dataBytes = NSData(bytes: &transmitData, length: sizeof(UInt8))
            print(String(transmitData, radix: 2))
            
            if let characteristic = self.carPeripheral?.services?.first?.characteristics?.first {
                self.carPeripheral?.writeValue(dataBytes, forCharacteristic: characteristic, type: CBCharacteristicWriteType.WithoutResponse)
            }
        }
    }
}


//MARK: - CoreMotion
extension ViewController: CBCentralManagerDelegate, CBPeripheralDelegate {
    func centralManagerDidUpdateState(central: CBCentralManager) {
        if central.state == CBCentralManagerState.PoweredOn {
            // Scan for peripherals if BLE is turned on
            central.scanForPeripheralsWithServices(nil, options: nil)
            print("Searching")
        }
        else {
            // Can have different conditions for all states if needed - print generic message for now
            print("BLuetooth not initialized")
        }
    }
    
    func centralManager(central: CBCentralManager, didDiscoverPeripheral peripheral: CBPeripheral, advertisementData: [String: AnyObject], RSSI: NSNumber) {
        let deviceName = "RCCAR1"
        let nameOfDeviceFound = (advertisementData as NSDictionary).objectForKey(CBAdvertisementDataLocalNameKey) as? NSString
        
        if nameOfDeviceFound == deviceName {
            // Update Status Label
            print("Found device")
            
            // Stop scanning
            centralManager.stopScan()
            // Set as the peripheral to use and establish connection
            carPeripheral = peripheral
            carPeripheral?.delegate = self
            centralManager.connectPeripheral(peripheral, options: nil)
        }
        else {
            print("Found \(nameOfDeviceFound) instead")
        }
    }
    
    func centralManager(central: CBCentralManager, didConnectPeripheral peripheral: CBPeripheral) {
        print("I found it! Now discover services")
        peripheral.discoverServices(nil)
    }
    
    func peripheral(peripheral: CBPeripheral, didDiscoverServices error: NSError?) {
        guard let services = peripheral.services where error == nil else {
            return
        }
        
        print("Periferal services: \(services.map { $0.UUID })")
        
        for service in services {
            peripheral.discoverCharacteristics(nil, forService: service)
        }
    }
    
    func peripheral(peripheral: CBPeripheral, didDiscoverCharacteristicsForService service: CBService, error: NSError?) {
        print("enabling peripheral")

        guard let characteristics = service.characteristics where error == nil else {
            return
        }
        
        NSOperationQueue.mainQueue().addOperationWithBlock {
            self.label.text = "Connected to car"
        }
        
        print("Characteristics: \(characteristics.map { $0.UUID })")
        
        for characteristic in characteristics {
//            var enableValue = 65 as UInt8
//            let enablyBytes = NSData(bytes: &enableValue, length: sizeof(UInt8))
//            
//            carPeripheral.writeValue(enablyBytes, forCharacteristic: characteristic, type: .WithoutResponse)
            carPeripheral?.setNotifyValue(true, forCharacteristic: characteristic)
        }
    }
    
    func peripheral(peripheral: CBPeripheral, didUpdateValueForCharacteristic characteristic: CBCharacteristic, error: NSError?) {
        guard let dataBytes = characteristic.value else {
            return
        }
        
        let dataLength = dataBytes.length
        var dataArray = [UInt8](count: dataLength, repeatedValue: 0)
        dataBytes.getBytes(&dataArray, length: dataLength * sizeof(UInt8))
        
        print(dataArray)
        print(String(bytes: dataArray, encoding: NSASCIIStringEncoding))
    }
    
    func centralManager(central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: NSError?) {
        label.text = "Searching for car..."
        print("Car disconnected")
        central.scanForPeripheralsWithServices(nil, options: nil)
    }
    
    func peripheral(peripheral: CBPeripheral, didWriteValueForCharacteristic characteristic: CBCharacteristic, error: NSError?) {
        print(error)
    }
    
    func peripheral(peripheral: CBPeripheral, didUpdateNotificationStateForCharacteristic characteristic: CBCharacteristic, error: NSError?) {
        print(characteristic.properties)
    }
}
