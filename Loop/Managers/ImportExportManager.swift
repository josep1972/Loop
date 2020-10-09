//
//  ImportExportManager.swift
//  Loop
//
//  Created by Ivan Valkou on 22.02.2020.
//  Copyright © 2020 LoopKit Authors. All rights reserved.
//

import UIKit
import Combine
import LoopCore
import LoopKit
import LoopKitUI

protocol ImportExportManager {
    func exportSettings()
    func importSettings()
}

final class BaseImportExportManager: NSObject, UIDocumentPickerDelegate, ImportExportManager {
    weak var rootController: UITableViewController?
    let dataManager: DeviceDataManager

    private var importMessage: String?
    private var importCancellable: AnyCancellable?

    init(rootController: UITableViewController?, dataManager: DeviceDataManager) {
        self.rootController = rootController
        self.dataManager = dataManager
    }

    func exportSettings() {
        var settingsRaw = dataManager.loopManager.settings.rawValue
        settingsRaw["basalRateSchedule"] = dataManager.loopManager.basalRateSchedule?.rawValue
        settingsRaw["insulinModelSettings"] = dataManager.loopManager.insulinModelSettings?.rawValue
        settingsRaw["carbRatioSchedule"] = dataManager.loopManager.carbRatioSchedule?.rawValue
        settingsRaw["insulinSensitivitySchedule"] = dataManager.loopManager.insulinSensitivitySchedule?.rawValue

        do {
            let data = try NSKeyedArchiver.archivedData(withRootObject: settingsRaw, requiringSecureCoding: false)

            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd-HH-mm"
            let dateString = dateFormatter.string(from: Date())

            let url = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("settings-\(dateString).freeaps")

            try data.write(to: url)
            let picker = UIDocumentPickerViewController(url: url, in: .exportToService)
            picker.delegate = self

            rootController?.present(picker, animated: true)
        } catch let error {
            let alert = UIAlertController(
                title: "Export settings",
                message: error.localizedDescription,
                preferredStyle: .alert
            )
            alert.addAction(.init(title: "Ok", style: .cancel))
            rootController?.present(alert, animated: true) { self.rootController?.tableView.reloadData() }
        }
    }

    func importSettings() {
        let picker = UIDocumentPickerViewController(documentTypes: ["freeaps.settings"], in: .import)
        picker.delegate = self
        picker.allowsMultipleSelection = false
        rootController?.present(picker, animated: true)
    }

    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        rootController?.tableView.reloadData()
    }

    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard controller.documentPickerMode == .import, let url = urls.last else {
            rootController?.tableView.reloadData()
            return
        }

        do {
            let data = try Data(contentsOf: url)
            let objects = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data)

            if let rawData = objects as? LoopSettings.RawValue, let settings = LoopSettings(rawValue: rawData) {
                dataManager.loopManager.settings = settings

                if let rawValue = rawData["basalRateSchedule"] as? BasalRateSchedule.RawValue,
                    let basalRateSchedule = BasalRateSchedule(rawValue: rawValue) {
                    dataManager.loopManager.basalRateSchedule = basalRateSchedule
                }

                if let rawValue = rawData["insulinModelSettings"] as? InsulinModelSettings.RawValue,
                    let insulinModelSettings = InsulinModelSettings(rawValue: rawValue) {
                    dataManager.loopManager.insulinModelSettings = insulinModelSettings
                }

                if let rawValue = rawData["carbRatioSchedule"] as? CarbRatioSchedule.RawValue,
                    let carbRatioSchedule = CarbRatioSchedule(rawValue: rawValue) {
                    dataManager.loopManager.carbRatioSchedule = carbRatioSchedule
                }

                if let rawValue = rawData["insulinSensitivitySchedule"] as? InsulinSensitivitySchedule.RawValue,
                    let insulinSensitivitySchedule = InsulinSensitivitySchedule(rawValue: rawValue) {
                    dataManager.loopManager.insulinSensitivitySchedule = insulinSensitivitySchedule
                }

                let syncAlert = UIAlertController(
                    title: "Pump synchronization in progress",
                    message: "Saving delivery limits and basal schedule to pump. Don't close the app!\n\n",
                    preferredStyle: .alert
                )

                let indicator = UIActivityIndicatorView()
                indicator.translatesAutoresizingMaskIntoConstraints = false
                syncAlert.view.addSubview(indicator)
                syncAlert.view.addConstraints([
                    indicator.bottomAnchor.constraint(equalTo: syncAlert.view.bottomAnchor, constant: -10),
                    indicator.centerXAnchor.constraint(equalTo: syncAlert.view.centerXAnchor)
                ])
                indicator.startAnimating()

                self.importMessage = "✅ Settings import completed successfully. "

                rootController?.present(syncAlert, animated: true) {
                    self.importCancellable = self.syncDeliveryLimits()
                        .receive(on: DispatchQueue.main)
                        .flatMap { self.syncBasalSchedule() }
                        .receive(on: DispatchQueue.main)
                        .sink {
                            syncAlert.dismiss(animated: true) {
                                let paragraphStyle = NSMutableParagraphStyle()
                                paragraphStyle.alignment = .left

                                let messageText = NSMutableAttributedString(
                                    string: self.importMessage!,
                                    attributes: [
                                        .paragraphStyle: paragraphStyle,
                                        .font: UIFont.systemFont(ofSize: UIFont.systemFontSize)
                                    ]
                                )

                                let successAlert = UIAlertController(
                                    title: "Done!",
                                    message: nil,
                                    preferredStyle: .alert
                                )
                                successAlert.setValue(messageText, forKey: "attributedMessage")

                                successAlert.addAction(.init(title: "Ok", style: .cancel))
                                self.rootController?.present(successAlert, animated: true)
                            }
                    }
                }

            }
        } catch let error {
            let alert = UIAlertController(
                title: "Import settings",
                message: error.localizedDescription,
                preferredStyle: .alert
            )
            alert.addAction(.init(title: "OK", style: .cancel))
            rootController?.present(alert, animated: true) { self.rootController?.tableView.reloadData() }
        }

        rootController?.tableView.reloadData()
    }

    private func syncBasalSchedule() -> Future<(), Never> {
        Future { promise in
            guard let pumpManager = self.dataManager.pumpManager,
                let profile = self.dataManager.loopManager.basalRateSchedule else {
                promise(.success(()))
                return
            }

            // TODO: change protocol to not use view controller
            let vc = BasalScheduleTableViewController(
                allowedBasalRates: pumpManager.supportedBasalRates,
                maximumScheduleItemCount: pumpManager.maximumBasalScheduleEntryCount,
                minimumTimeInterval: pumpManager.minimumBasalScheduleEntryDuration
            )

            vc.scheduleItems = profile.items
            vc.timeZone = profile.timeZone

            pumpManager.syncScheduleValues(for: vc) { result in
                switch result {
                case .success:
                    self.importMessage = self.importMessage
                        .map { $0 + "\n\n✅ Basal schedule saved to pump." }
                case let .failure(error):
                    self.importMessage = self.importMessage
                        .map { $0 + "\n\n❌ Basal schedule not saved to pump: \(error.localizedDescription)." }
                }
                promise(.success(()))
            }
        }
    }

    private func syncDeliveryLimits() -> Future<(), Never> {
        Future { promise in
            guard let pumpManager = self.dataManager.pumpManager else {
                promise(.success(()))
                return
            }

            // TODO: change protocol to not use view controller
            let vc = DeliveryLimitSettingsTableViewController(style: .grouped)
            vc.maximumBasalRatePerHour = self.dataManager.loopManager.settings.maximumBasalRatePerHour
            vc.maximumBolus = self.dataManager.loopManager.settings.maximumBolus

            pumpManager.syncDeliveryLimitSettings(for: vc) { result in
                switch result {
                case .success:
                    self.importMessage = self.importMessage
                        .map { $0 + "\n\n✅ Delivery limits saved to pump." }
                case let .failure(error):
                    self.importMessage = self.importMessage
                        .map { $0 + "\n\n❌ Delivery limits not saved to pump: \(error.localizedDescription)." }
                }
                promise(.success(()))
            }
        }
    }
}
