//
//  TempBasalView.swift
//  Loop
//
//  Created by Ivan Valkou on 07.01.2020.
//  Copyright © 2020 LoopKit Authors. All rights reserved.
//

import SwiftUI
import Combine

struct TempBasalView: View {
    @State private var amount: String = ""
    @State private var durationIndex = 0

    let recommendation = PassthroughSubject<TempBasalRecommendation?, Never>()

    private let durationValues = stride(from: 30.0, to: 720.1, by: 30.0).map { $0 }

    private let formatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 3
        return formatter
    }()

    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("Basal rate (U/h)", text: $amount).keyboardType(.decimalPad)
                    Picker(selection: $durationIndex, label: Text("Duration")) {
                        ForEach(0 ..< durationValues.count) { index in
                            Text(
                                String(
                                    format: NSLocalizedString("%.0f h %02.0f min", comment: ""),
                                    self.durationValues[index] / 60 - 0.1,
                                    self.durationValues[index].truncatingRemainder(dividingBy: 60)
                                )
                            ).tag(index)
                        }
                    }
                }
                Button("Cancel Temp Basal") {
                    self.recommendation.send(.init(unitsPerHour: 0, duration: 0))
                }

            }
            .navigationBarTitle("Manual Temp Basal")
            .navigationBarItems(
                leading: Button("Cancel") {
                    self.recommendation.send(nil)
                },
                trailing: Button("Set") {
                    guard let amount = self.formatter.number(from: self.amount)?.doubleValue
                        else {
                            self.recommendation.send(nil)
                            return
                    }
                    let duration = self.durationValues[self.durationIndex]
                    self.recommendation.send(.init(unitsPerHour: amount, duration: duration * 60))
                }.disabled(amount.isEmpty)
            )
        }
    }
}

struct TempBasalView_Previews: PreviewProvider {
    static var previews: some View {
        TempBasalView()
    }
}
