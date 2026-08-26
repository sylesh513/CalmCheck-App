import CoreLocation
import Flutter
import UIKit

/// The iOS half of `app.calmcheck/device_settings`.
///
/// One job: answer "where is this phone", once, when somebody taps "text my
/// person". Never in the background, never stored. The fix goes into a message
/// they compose in Messages and press send on themselves.
///
/// Every failure — no permission, location off, no fix in time — answers nil,
/// and the Dart side sends the message without a map link rather than making
/// anybody wait.
public class CalmCheckLocationPlugin: NSObject, FlutterPlugin, CLLocationManagerDelegate {
  private static let channelName = "app.calmcheck/device_settings"
  private static let timeout: TimeInterval = 8

  private var manager: CLLocationManager?
  private var pending: FlutterResult?
  private var timeoutTimer: Timer?

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: channelName,
      binaryMessenger: registrar.messenger()
    )
    let instance = CalmCheckLocationPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "currentLocation":
      requestLocation(result)
    default:
      // openAppSettings and countryCode are answered on the Dart side on iOS:
      // the first through the app-settings: URL, the second from the locale,
      // because iOS 16 removed carrier country.
      result(FlutterMethodNotImplemented)
    }
  }

  private func requestLocation(_ result: @escaping FlutterResult) {
    // A second tap while one is in flight gets nil rather than stealing the
    // first one's answer.
    if pending != nil {
      result(nil)
      return
    }
    guard CLLocationManager.locationServicesEnabled() else {
      result(nil)
      return
    }

    pending = result

    let manager = CLLocationManager()
    manager.delegate = self
    manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    self.manager = manager

    timeoutTimer = Timer.scheduledTimer(withTimeInterval: Self.timeout, repeats: false) {
      [weak self] _ in
      self?.finish(nil)
    }

    switch manager.authorizationStatus {
    case .notDetermined:
      manager.requestWhenInUseAuthorization()
    case .authorizedWhenInUse, .authorizedAlways:
      manager.requestLocation()
    default:
      finish(nil)
    }
  }

  private func finish(_ location: CLLocation?) {
    timeoutTimer?.invalidate()
    timeoutTimer = nil
    manager?.delegate = nil
    manager = nil

    guard let pending else { return }
    self.pending = nil

    if let location {
      pending([
        "latitude": location.coordinate.latitude,
        "longitude": location.coordinate.longitude,
      ])
    } else {
      pending(nil)
    }
  }

  // MARK: - CLLocationManagerDelegate

  public func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
    guard pending != nil else { return }
    switch manager.authorizationStatus {
    case .authorizedWhenInUse, .authorizedAlways:
      manager.requestLocation()
    case .notDetermined:
      break  // Still waiting on the person to answer the prompt.
    default:
      finish(nil)
    }
  }

  public func locationManager(
    _ manager: CLLocationManager,
    didUpdateLocations locations: [CLLocation]
  ) {
    finish(locations.last)
  }

  public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
    finish(nil)
  }
}
