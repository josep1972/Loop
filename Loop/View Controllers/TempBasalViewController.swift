//
//  TempBasalViewController.swift
//  Loop
//
//  Created by Ivan Valkou on 07.01.2020.
//  Copyright © 2020 LoopKit Authors. All rights reserved.
//

import SwiftUI
import Combine

final class TempBasalViewController: UIHostingController<TempBasalView> {
    private var lifetime: AnyCancellable?
    
    init() {
        let view = TempBasalView()
        super.init(rootView: view)
        lifetime = view.recommendation.eraseToAnyPublisher()
            .sink { [weak self] recommendation in
                self?.onChange?(recommendation)
        }
    }

    @objc required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var onChange: ((TempBasalRecommendation?) -> Void)?
}
