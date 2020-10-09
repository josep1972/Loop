//
//  FreeAPSSettingsViewModel.swift
//  Loop
//
//  Created by Ivan Valkou on 10.06.2020.
//  Copyright © 2020 LoopKit Authors. All rights reserved.
//

import SwiftUI
import LoopCore
import Combine

extension FreeAPSSettingsView {
    final class ViewModel: ObservableObject {
        @Published var showRequiredCarbsOnAppBadge: Bool
        @Published var retrospectiveIndex: Int
        let retrospectiveValues = stride(from: 10.0, to: 61.0, by: 10.0).map { $0 }

        private var lifetime = Set<AnyCancellable>()

        init(settings: FreeAPSSettings) {
            showRequiredCarbsOnAppBadge = settings.showRequiredCarbsOnAppBadge

            retrospectiveIndex = retrospectiveValues.firstIndex(of: settings.retrospectiveCorrectionGroupingInterval / 60) ?? 0
        }

        func changes() -> AnyPublisher<FreeAPSSettings, Never> {
            Publishers.CombineLatest($showRequiredCarbsOnAppBadge, $retrospectiveIndex)
                .map {
                    FreeAPSSettings(
                        showRequiredCarbsOnAppBadge: $0.0,
                        retrospectiveCorrectionGroupingInterval: TimeInterval(minutes: self.retrospectiveValues[$0.1])
                    )
                }
                .eraseToAnyPublisher()
        }
    }
}
