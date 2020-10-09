//
//  FreeAPSSettingsView.swift
//  Loop
//
//  Created by Ivan Valkou on 10.06.2020.
//  Copyright © 2020 LoopKit Authors. All rights reserved.
//

import SwiftUI

struct FreeAPSSettingsView: View {
    @ObservedObject var viewModel: ViewModel

    init(viewModel: ViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        Form {
            Section {
                Toggle (isOn: $viewModel.showRequiredCarbsOnAppBadge) {
                    Text("Show required carbs on the app badge")
                }
                Picker(selection: $viewModel.retrospectiveIndex, label: Text("Retrospective Correction interval")) {
                    ForEach(0 ..< viewModel.retrospectiveValues.count) { index in
                        Text("\(Int(self.viewModel.retrospectiveValues[index])) min").tag(index)
                    }
                }
            }
        }
        .navigationBarTitle("Other FreeAPS settings")
        .modifier(AdaptsToSoftwareKeyboard())
    }
}
