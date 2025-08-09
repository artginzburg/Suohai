//
//  SuohaiController.swift
//  AudioSwitcher
//
//  Created by Sunnyyoung on 2017/8/2.
//  Copyright © 2017年 Sunnyyoung. All rights reserved.
//

import Cocoa
import CoreServices
import CoreAudio
import LoginServiceKit

class SuohaiController: NSObject {
    private var menu: NSMenu!
    private var statusItem: NSStatusItem!

    override init() {
        super.init()
        self.prepareItems()
        self.reloadStatusItem()
        NotificationCenter.addObserver(observer: self, selector: #selector(reloadMenu), name: .audioDevicesDidChange)
    }

    deinit {
        NotificationCenter.removeObserver(observer: self, name: .audioDevicesDidChange)
    }

    private func reloadStatusItem() {
        let listener = SuohaiListener.shared
        let shouldHide = listener.devices.count <= 2
        self.statusItem.isVisible = !shouldHide
    }

    // Mark: Notification handler
    @objc
    func reloadMenu(openedManually: Bool = false) {
        if !openedManually { reloadStatusItem() }
        let listener = SuohaiListener.shared
        self.menu.removeAllItems()
        self.menu.addItem(NSMenuItem(title: NSLocalizedString("OutputDevices", comment: "")))
        listener.devices.forEach { (device) in
            guard device.type == .output else {
                return
            }
            self.menu.addItem({
                let item = NSMenuItem(title: device.name, target: self, action: #selector(selectOutputDeviceAction(_:)))
                item.tag = Int(device.id)
                item.state = listener.selectedOutputDeviceID == device.id ? .on : .off
                return item
                }())
        }
        self.menu.addItem(NSMenuItem.separator())
        self.menu.addItem(NSMenuItem(title: NSLocalizedString("InputDevices", comment: "")))
        listener.devices.forEach { (device) in
            guard device.type == .input else {
                return
            }
            self.menu.addItem({
                let item = NSMenuItem(title: device.name, target: self, action: #selector(selectInputDeviceAction(_:)))
                item.tag = Int(device.id)
                item.state = listener.selectedInputDeviceID == device.id ? .on : .off
                return item
            }())
        }
        self.menu.addItem(NSMenuItem.separator())
        self.menu.addItem({
            let item = NSMenuItem(title: NSLocalizedString("LaunchAtLogin", comment: ""), target: self, action: #selector(toggleLaunchAtLoginAction(_:)))
            item.state = LoginServiceKit.isExistLoginItems() ? .on : .off
            return item
        }())
        self.menu.addItem(NSMenuItem.separator())
        self.menu.addItem(NSMenuItem(title: NSLocalizedString("Quit", comment: ""), target: self, action: #selector(quitAction(_:)), keyEquivalent: "q"))
        self.menu.update()
    }

    // MARK: Event method
    @objc
    private func selectOutputDeviceAction(_ sender: NSMenuItem) {
        let listener = SuohaiListener.shared
        guard let device = listener.devices.first(where: {$0.id == UInt32(sender.tag)}) else {
            return
        }
        listener.selectedOutputDeviceID = listener.selectedOutputDeviceID != device.id ? device.id : nil
    }

    @objc
    private func selectInputDeviceAction(_ sender: NSMenuItem) {
        let listener = SuohaiListener.shared
        guard let device = listener.devices.first(where: {$0.id == UInt32(sender.tag)}) else {
            return
        }
        listener.selectedInputDeviceID = listener.selectedInputDeviceID != device.id ? device.id : nil
    }

    @objc
    private func toggleLaunchAtLoginAction(_ sender: NSMenuItem) {
        if LoginServiceKit.isExistLoginItems() {
            LoginServiceKit.removeLoginItems()
        } else {
            LoginServiceKit.addLoginItems()
        }
    }

    @objc
    private func quitAction(_ sender: NSMenuItem) {
        NSApplication.shared.terminate(nil)
    }

    // MARK: UI method
    private func prepareItems() {
        self.menu = {
            let menu = NSMenu()
            menu.delegate = self
            return menu
        }()
        self.statusItem = {
            let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
            item.image = #imageLiteral(resourceName: "StatusItem")
            item.target = self
            item.menu = self.menu
            item.isVisible = true
            return item
        }()
    }

#if DEBUG
    private var timesHandledReopen = 0
#endif
}

extension SuohaiController: NSMenuDelegate {
    func menuWillOpen(_ menu: NSMenu) {
        self.reloadMenu(openedManually: true)
    }
    func menuDidClose(_ menu: NSMenu) {
        self.reloadStatusItem()
    }
}

extension SuohaiController {
#if DEBUG
    private func isRunningInXcode() -> Bool {
        return ProcessInfo.processInfo.environment["IDE_DISABLED_OS_ACTIVITY_DT_MODE"] != nil
    }
#endif

    func handleReopen() {
#if DEBUG
        guard !isRunningInXcode() || timesHandledReopen >= 2 else {
            timesHandledReopen += 1
            return
        }
#endif

        statusItem.isVisible = true
        Timer.scheduledTimer(withTimeInterval: 0.01, repeats: false) { _ in
            DispatchQueue.main.async {
                self.statusItem.button?.performClick(nil)
            }
        }
    }
}
