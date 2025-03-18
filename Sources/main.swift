import class AsyncAlgorithms.AsyncChannel
import class CoreBluetooth.CBCentralManager
import protocol CoreBluetooth.CBCentralManagerDelegate
import enum CoreBluetooth.CBManagerState
import class CoreBluetooth.CBPeripheral
import struct Foundation.Duration
import class Foundation.NSNumber
import class Foundation.ProcessInfo
import class ObjectiveC.NSObject

let durationDefault: Duration = .seconds(3)

let env: [String: String] = ProcessInfo.processInfo.environment
let durationSecondsS: String? = env["ENV_TIMEOUT_SECONDS"]
let durationSeconds: Float64? = durationSecondsS.flatMap {
  let s: String = $0
  return Float64(s)
}
let duration: Duration = durationSeconds.map { .seconds($0) } ?? durationDefault

enum Event {
  case stateUpdated(CBManagerState)
  case poweredOn
  case timeout
}

class CentralHandler: NSObject {
  let ch: AsyncChannel<Event>
  let i: Int = 42

  public init(ch: AsyncChannel<Event>) {
    self.ch = ch
  }
}

func state2str(_ state: CBManagerState) -> String {
  switch state {
  case .poweredOff: "powered off"
  case .poweredOn: "powered on"
  case .resetting: "resetting"
  case .unauthorized: "unauthorized"
  case .unknown: "unknown"
  case .unsupported: "unsupported"

  @unknown default: "UNKNOWN"
  }
}

extension CentralHandler: CBCentralManagerDelegate {
  func centralManagerDidUpdateState(_ central: CBCentralManager) {
    let state: CBManagerState = central.state
    let ch: AsyncChannel = self.ch
    Task {
      switch state {
      case .poweredOn:
        await ch.send(.poweredOn)
      default:
        await ch.send(.stateUpdated(state))
      }
    }
  }

  func centralManager(
    _ central: CBCentralManager,
    didDiscover peripheral: CBPeripheral,
    advertisementData: [String: Any],
    rssi RSSI: NSNumber
  ) {
    print("peripheral: \( peripheral )")
    print("advertisement: \( advertisementData )")
    print("rssi: \( RSSI )")
  }
}

@main
struct BleScan {
  static func main() async {
    let ch: AsyncChannel<Event> = AsyncChannel()
    let cmng: CBCentralManager = CBCentralManager()
    let hndl: CentralHandler = CentralHandler(ch: ch)
    cmng.delegate = hndl

    Task {
      do {
        try await Task.sleep(for: duration)
      } catch {
        print("\( error )")
      }

      await ch.send(.timeout)
    }

    for await event in ch {
      switch event {
      case .timeout:
        return
      case .poweredOn:
        cmng.scanForPeripherals(
          withServices: [],
          options: nil
        )
      default:
        print("\( event )")
      }
    }
  }
}
