//
//  AppDelegate.swift
//  StatusView
//
//  Created by Stefan Klieme on 08.01.15.
//  Copyright (c) 2015 Stefan Klieme. All rights reserved.
//

import AppKit

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    @IBOutlet weak var window: NSWindow!
    @IBOutlet weak var statusView: StatusView!

    var statusCounter : Int = 1
    @objc dynamic var enableInverted = true

    func applicationDidFinishLaunching(aNotification: NSNotification) {
        statusView.inverted = false
        statusView.enabled = true
        push(nil)
    }

    func applicationWillTerminate(aNotification: NSNotification) {
        // Insert code here to tear down your application
    }

    @IBAction func invert(_ sender: NSButton) {
        statusView.inverted = sender.state == .on ? true : false
    }
    
    @IBAction func enable(_ sender: NSButton) {
        statusView.enabled = sender.state == .on ? true : false
    }
    
    @IBAction func saveDocument(_ sender: NSButton) {
        if let imageRep = statusView.bitmapImageRepForCachingDisplay(in: statusView.bounds) {
            statusView.cacheDisplay(in: statusView.bounds, to:imageRep)
            let data = imageRep.tiffRepresentation!
            let uuid = UUID().uuidString
            let desktop = URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Desktop")
            try? data.write(to: desktop.appendingPathComponent("\(uuid).tif"))
        }
    }
    
    @IBAction func push(_ sender : NSButton!)
    {
        statusCounter += 1
        if statusCounter == 5 { statusCounter = 0 }
        switch statusCounter {
        case 0: statusView.status = .none
        case 1: statusView.status = .processing
        case 2: statusView.status = .failed
        case 3: statusView.status = .caution
        case 4: statusView.status = .success
        default :
            statusView.status = .none
        }
        enableInverted = statusView.status != .processing
    }
}

