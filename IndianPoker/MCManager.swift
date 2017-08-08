//
//  MCManager.swift
//  IndianPoker
//
//  Created by 설윤아 on 2017. 8. 8..
//  Copyright © 2017년 noriteo. All rights reserved.
//

import UIKit
import MultipeerConnectivity

class MCManager: NSObject, MCSessionDelegate {
    
    var peerID: MCPeerID!
    var session: MCSession!
    var browser: MCBrowserViewController!
    var advertiser: MCAdvertiserAssistant!
    var serviceType = "Indian-Poker"
    
    var foundPeers = [MCPeerID]()
    var invitationHandler: ((Bool, MCSession?) -> Void)!
    
    override init() {
        super.init()
        peerID = nil
        session = nil
        browser = nil
        advertiser = nil
    }
    
    func setupPeerAndSessionWithDisplayName(name: String) {
        self.peerID = MCPeerID(displayName: name)
        self.session = MCSession(peer: self.peerID)
        self.session.delegate = self
    }
    
    func setupMCBrowser() {
        self.browser = MCBrowserViewController(serviceType: serviceType, session: self.session)
    }
    
    func advertiseMyself(shouldAdvertise: Bool) {
        if shouldAdvertise {
            self.advertiser = MCAdvertiserAssistant(serviceType: serviceType, discoveryInfo: nil, session: self.session)
            self.advertiser.start()
        }
    }
    
    func stopAdvertise() {
        if self.advertiser != nil {
            self.advertiser.stop()
            self.advertiser = nil
        }
    }
    
    
    // 블루투스 상대에게 NSData가 보내져왔을때
    // 0: Game Start
    // 1~20: Card Pick for new game set
    // 21~40: Card Pick for choosing First
    // 100: Bet Over    101: One Chip Bet
    func session(_ session: MCSession, didReceive data: Data,
                 fromPeer peerID: MCPeerID)  {
        DispatchQueue.main.async() {
            
            let data = NSData(data: data)
            var num : NSInteger = 0
            data.getBytes(&num, length: data.length)
            if (num == 50) {
                touchPossible = true
            }
            else if (num == 0) {
                let startNotification = Notification.Name("GameStartNotification")
                NotificationCenter.default.post(name: startNotification, object: nil)
            }
            
            else {
                let notificationName = Notification.Name("CardNotification")
                let cardData: NSDictionary = [
                    "type": 0,
                    "number": num,
                    ]
                NotificationCenter.default.post(name: notificationName, object: nil, userInfo: cardData as? [String : NSInteger])
            }

        }
    }
    
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress)  {
        // Called when a peer starts sending a file to us
    }
    
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL, withError error: Error?)  {
        // Called when a file has finished transferring from another peer
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID)  {
        // Called when a peer establishes a stream with us
    }
    
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState)  {
        // Called when a connected peer changes state (for example, goes offline)
    }
    
    
}
