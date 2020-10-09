//
//  FreeAPSSettingsViewController.swift
//  Loop
//
//  Created by Ivan Valkou on 10.06.2020.
//  Copyright © 2020 LoopKit Authors. All rights reserved.
//

import SwiftUI
import Combine

final class FreeAPSSettingsViewController: UIHostingController<FreeAPSSettingsView> {
    init(viewModel: FreeAPSSettingsView.ViewModel) {
        super.init(rootView: FreeAPSSettingsView(viewModel: viewModel))
    }

    @objc required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var onDeinit: (() -> Void)?

    deinit {
        onDeinit?()
    }
}
