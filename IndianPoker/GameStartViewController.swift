//
//  GameStartViewController.swift
//  IndianPoker
//
//  Created by 설윤아 on 2017. 8. 7..
//  Copyright © 2017년 noriteo. All rights reserved.
//

import UIKit
import MultipeerConnectivity

class GameStartViewController: UIViewController, MCBrowserViewControllerDelegate {

    @IBOutlet weak var gameStartButton: UIButton!

    var appDelegate : AppDelegate!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Setting for MC
        appDelegate = UIApplication.shared.delegate as! AppDelegate
        self.appDelegate.mcManager.setupPeerAndSessionWithDisplayName(name: UIDevice.current.name)
        self.appDelegate.mcManager.advertiseMyself(shouldAdvertise: true)
        
        let notificationName = Notification.Name("GameStartNotification")
        NotificationCenter.default.addObserver(self, selector: #selector(didReceiveStartCode(notification:)), name: notificationName, object: nil)
    }
    
    @IBAction func gameStart(_ sender: Any) {
        sendStartCode()
        moveToGame()
    }
    
    @IBAction func browserBtnTab(_ sender: Any) {
        appDelegate.mcManager.setupMCBrowser()
        appDelegate.mcManager.browser.delegate = self
        self.present(appDelegate.mcManager.browser, animated: true, completion: nil)
    }
    
    func browserViewControllerDidFinish(
        _ browserViewController: MCBrowserViewController)  {
        // Called when the browser view controller is dismissed (ie the Done button was tapped)
        gameStartButton.isEnabled = true
        self.dismiss(animated: true, completion: nil)
    }
    
    func browserViewControllerWasCancelled(
        _ browserViewController: MCBrowserViewController)  {
        // Called when the browser view controller is cancelled
        gameStartButton.isEnabled = false
        self.dismiss(animated: true, completion: nil)
    }
    
    // send number to other player
    func sendStartCode() {
        var temp = 0
        let data = NSData(bytes: &temp, length: MemoryLayout<NSInteger>.size)
        do {
            try appDelegate.mcManager.session.send(data as Data, toPeers: appDelegate.mcManager.session.connectedPeers, with: MCSessionSendDataMode.reliable)
        } catch {
            print(error)
        }
    }
    
    func didReceiveStartCode(notification: NSNotification) {
        moveToGame()
    }
    
    func moveToGame() {
        currentGame = Game()
        self.performSegue(withIdentifier: "toGameSegue", sender: self)
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}
