//
//  Microbolus.swift
//  LoopCore
//
//  Created by Ivan Valkou on 07.11.2019.
//  Copyright © 2019 LoopKit Authors. All rights reserved.
//

import Foundation

public enum Microbolus {
    public struct Settings: Equatable, RawRepresentable {
        public typealias RawValue = [String: Any]

        public var enabled: Bool
        public var enabledWithoutCarbs: Bool
        public var partialApplication: Double
        public var minimumBolusSize: Double
        public var shouldOpenBolusScreenOnWatch: Bool
        public var disableByOverride: Bool
        public var overrideLowerBound: Double
        public var basalRateMultiplier: Double
        public var enabledWhenSensorStateIsInvalid: Bool
        public var allowWhenGlucoseBelowTarget: Bool

        public init(
            enabled: Bool = false,
            enabledWithoutCarbs: Bool = false,
            partialApplication: Double = 0.3,
            minimumBolusSize: Double = 0,
            shouldOpenBolusScreenOnWatch: Bool = false,
            disableByOverride: Bool = false,
            overrideLowerBound: Double = 0,
            basalRateMultiplier: Double = 0, // 0 means MaximumBasalRatePerHour
            enabledWhenSensorStateIsInvalid: Bool = false,
            allowWhenGlucoseBelowTarget: Bool = false
        ) {
            self.enabled = enabled
            self.enabledWithoutCarbs = enabledWithoutCarbs
            self.partialApplication = partialApplication
            self.minimumBolusSize = minimumBolusSize
            self.shouldOpenBolusScreenOnWatch = shouldOpenBolusScreenOnWatch
            self.disableByOverride = disableByOverride
            self.overrideLowerBound = overrideLowerBound
            self.basalRateMultiplier = basalRateMultiplier
            self.enabledWhenSensorStateIsInvalid = enabledWhenSensorStateIsInvalid
            self.allowWhenGlucoseBelowTarget = allowWhenGlucoseBelowTarget
        }

        public init?(rawValue: [String : Any]) {
            self = Settings()

            if let enabled = rawValue["enabled"] as? Bool {
                self.enabled = enabled
            }

            if let enabledWithoutCarbs = rawValue["enabledWithoutCarbs"] as? Bool {
                self.enabledWithoutCarbs = enabledWithoutCarbs
            }

            if let partialApplication = rawValue["partialApplication"] as? Double {
                self.partialApplication = partialApplication
            }

            if let minimumBolusSize = rawValue["minimumBolusSize"] as? Double {
                self.minimumBolusSize = minimumBolusSize
            }

            if let shouldOpenBolusScreenOnWatch = rawValue["shouldOpenBolusScreenOnWatch"] as? Bool {
                self.shouldOpenBolusScreenOnWatch = shouldOpenBolusScreenOnWatch
            }

            if let disableByOverride = rawValue["disableByOverride"] as? Bool {
                self.disableByOverride = disableByOverride
            }

            if let overrideLowerBound = rawValue["overrideLowerBound"] as? Double {
                self.overrideLowerBound = overrideLowerBound
            }

            if let basalRateMultiplier = rawValue["basalRateMultiplier"] as? Double {
                self.basalRateMultiplier = basalRateMultiplier
            }

            if let enabledWhenSensorStateIsInvalid = rawValue["enabledWhenSensorStateIsInvalid"] as? Bool {
                self.enabledWhenSensorStateIsInvalid = enabledWhenSensorStateIsInvalid
            }

            if let allowWhenGlucoseBelowTarget = rawValue["allowWhenGlucoseBelowTarget"] as? Bool {
                self.allowWhenGlucoseBelowTarget = allowWhenGlucoseBelowTarget
            }
        }

        public var rawValue: [String : Any] {
            [
                "enabled": enabled,
                "enabledWithoutCarbs": enabledWithoutCarbs,
                "partialApplication": partialApplication,
                "minimumBolusSize": minimumBolusSize,
                "shouldOpenBolusScreenOnWatch": shouldOpenBolusScreenOnWatch,
                "disableByOverride": disableByOverride,
                "overrideLowerBound": overrideLowerBound,
                "basalRateMultiplier": basalRateMultiplier,
                "enabledWhenSensorStateIsInvalid": enabledWhenSensorStateIsInvalid,
                "allowWhenGlucoseBelowTarget": allowWhenGlucoseBelowTarget
            ]
        }
    }
}

public extension Microbolus {
    struct Event: Identifiable {
        public let id = UUID()
        public let date: Date
        public let recommendedAmount: Double
        public let amount: Double
        public let reason: String?
        public let roundedUp: Bool

        public static func canceled(date: Date, recommended: Double, reason: String) -> Event {
            Event(date: date, recommendedAmount: recommended, amount: 0, reason: reason, roundedUp: false)
        }

        public static func failed(date: Date, recommended: Double, error: Error) -> Event {
            Event(date: date, recommendedAmount: recommended, amount: 0, reason: "Failed with error: \(error.localizedDescription)", roundedUp: false)
        }

        public static func succeeded(date: Date, recommended: Double, amount: Double, roundedUp: Bool) -> Event {
            Event(date: date, recommendedAmount: recommended, amount: amount, reason: nil, roundedUp: roundedUp)
        }

        public var description: String {
            let timeFormatter = DateFormatter()
            timeFormatter.timeStyle = .short
            let percentFormatter = NumberFormatter()
            percentFormatter.maximumFractionDigits = 2
            percentFormatter.numberStyle = .percent
            let percent = amount/recommendedAmount
            return "At \(timeFormatter.string(from: date)): enacted \(amount) (\(percentFormatter.string(for: percent) ?? "0 %")) of recommended \(recommendedAmount). \(roundedUp ? "Rounded up to nearest value": "")"
            + (reason ?? "")
        }

    }
}
