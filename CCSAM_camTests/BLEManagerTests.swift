import XCTest
import CoreBluetooth
@testable import CCSAM_cam


protocol CentralManagerProtocol: AnyObject {
    var state: CBManagerState { get }
    var delegate: CBCentralManagerDelegate? { get set }
    func scanForPeripherals(withServices serviceUUIDs: [CBUUID]?, options: [String: Any]?)
    func stopScan()
    func connect(_ peripheral: CBPeripheral, options: [String: Any]?)
    func cancelPeripheralConnection(_ peripheral: CBPeripheral)
}

class MockCentralManager: CentralManagerProtocol {
    var state: CBManagerState = .poweredOn
    weak var delegate: CBCentralManagerDelegate?
    var isScanning = false
    var scanCount = 0
    var connectCount = 0
    var disconnectCount = 0
    
    func scanForPeripherals(withServices serviceUUIDs: [CBUUID]?, options: [String: Any]?) {
        isScanning = true
        scanCount += 1
    }
    
    func stopScan() {
        isScanning = false
    }
    
    func connect(_ peripheral: CBPeripheral, options: [String: Any]?) {
        connectCount += 1
    }
    
    func cancelPeripheralConnection(_ peripheral: CBPeripheral) {
        disconnectCount += 1
    }
}

extension CBCentralManager: CentralManagerProtocol {}

class BLEManagerTests: XCTestCase {
    var bleManager: BLEManager!
    
    override func setUp() {
        super.setUp()
        bleManager = BLEManager()
    }
    
    override func tearDown() {
        bleManager = nil
        super.tearDown()
    }
    
    func testInitialization() {
        XCTAssertNotNil(bleManager)
        XCTAssertFalse(bleManager.isConnected)
        XCTAssertNil(bleManager.connectedDevice)
        XCTAssertEqual(bleManager.statusMessage, "Ready to scan")
    }
    
    func testDiscoveredDevices() {
        XCTAssertEqual(bleManager.discoveredDevices.count, 0)
    }
    
    func testPublishedProperties() {
        XCTAssertFalse(bleManager.isScanning)
        XCTAssertFalse(bleManager.receiveInProgress)
        XCTAssertNil(bleManager.wavFileURL)
        XCTAssertNil(bleManager.snapshotImage)
    }
}
