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
    dynamic var enableInverted = true

    func applicationDidFinishLaunching(aNotification: NSNotification) {
        statusView.inverted = false
        statusView.enabled = true
        push(nil)
    }

    func applicationWillTerminate(aNotification: NSNotification) {
        // Insert code here to tear down your application
    }

    @IBAction func invert(sender: NSButton) {
        statusView.inverted = Bool(sender.state)
    }
    
    @IBAction func enable(sender: NSButton) {
        statusView.enabled = Bool(sender.state)
    }
    
    @IBAction func saveDocument(sender: NSButton) {
        if let imageRep = statusView.bitmapImageRepForCachingDisplayInRect(statusView.bounds) {
            statusView.cacheDisplayInRect(statusView.bounds, toBitmapImageRep:imageRep)
            let data = imageRep.TIFFRepresentation!
            let UUID = NSUUID().UUIDString
            let desktop = NSHomeDirectory().stringByAppendingPathComponent("Desktop")
            data.writeToFile("\(desktop)/\(UUID).tif", atomically: true)
        }
    }
    
    @IBAction func push(sender : NSButton!)
    {
        statusCounter++
        if statusCounter == 5 { statusCounter = 0 }
        switch statusCounter {
        case 0: statusView.status = .None
        case 1: statusView.status = .Processing
        case 2: statusView.status = .Failed
        case 3: statusView.status = .Caution
        case 4: statusView.status = .Success
        default :
            statusView.status = .None
        }
        enableInverted = statusView.status != .Processing
    }
}

