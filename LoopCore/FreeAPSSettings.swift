//
//  FreeAPS.swift
//  LoopCore
//
//  Created by Ivan Valkou on 10.06.2020.
//  Copyright © 2020 LoopKit Authors. All rights reserved.
//

import Foundation

public struct FreeAPSSettings: Equatable, RawRepresentable {
    public typealias RawValue = [String: Any]

    public var showRequiredCarbsOnAppBadge: Bool

    public var retrospectiveCorrectionGroupingInterval: TimeInterval

    public init(showRequiredCarbsOnAppBadge: Bool = false, retrospectiveCorrectionGroupingInterval: TimeInterval = TimeInterval(minutes: 30)) {
        self.showRequiredCarbsOnAppBadge = showRequiredCarbsOnAppBadge
        self.retrospectiveCorrectionGroupingInterval = retrospectiveCorrectionGroupingInterval
    }

    public init?(rawValue: [String : Any]) {
        self = FreeAPSSettings()

        if let showRequiredCarbsOnAppBadge = rawValue["showRequiredCarbsOnAppBadge"] as? Bool {
            self.showRequiredCarbsOnAppBadge = showRequiredCarbsOnAppBadge
        }

        if let retrospectiveCorrectionGroupingInterval = rawValue["retrospectiveCorrectionGroupingInterval"] as? TimeInterval {
            self.retrospectiveCorrectionGroupingInterval = retrospectiveCorrectionGroupingInterval
        }
    }

    public var rawValue: [String : Any] {
        [
            "showRequiredCarbsOnAppBadge": showRequiredCarbsOnAppBadge,
            "retrospectiveCorrectionGroupingInterval": retrospectiveCorrectionGroupingInterval
        ]
    }
}
