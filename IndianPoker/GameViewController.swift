//
//  GameViewController.swift
//  IndianPoker
//
//  Created by 설윤아 on 2017. 8. 7..
//  Copyright © 2017년 noriteo. All rights reserved.
//

import UIKit
import CoreMotion
import MultipeerConnectivity
import AVFoundation

enum resultType {
    case win
    case loose
}

var currentGame = Game()
var touchPossible = false
var cntTouch = 0
var result : Bool?

class GameViewController: UIViewController, UITextFieldDelegate {

    var appDelegate : AppDelegate!

    // audio sound
    var audioPlayer = AVAudioPlayer()
    let systemSoundID_betting: SystemSoundID = 1113
    let systemSoundID_cardChange: SystemSoundID = 1106
    let systemSoundID_finishBetting: SystemSoundID = 1004
    
    let tapRec = UITapGestureRecognizer()
    let swipeDownRec = UISwipeGestureRecognizer()
    
    @IBOutlet weak var chooseFirstButton: UIButton!
    
    @IBOutlet weak var myView: UIView!
    @IBOutlet weak var yourView: UIView!
    @IBOutlet weak var cardView: UIImageView!
    
    @IBOutlet weak var yourName: UILabel!
    @IBOutlet weak var myName: UILabel!
    @IBOutlet weak var myChips: UILabel!
    @IBOutlet weak var yourChips: UILabel!
    @IBOutlet weak var myBet: UILabel!
    @IBOutlet weak var yourBet: UILabel!
    @IBOutlet weak var seeCard: UILabel!
    
    //CoreMotion
    let manager = CMMotionManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        appDelegate = UIApplication.shared.delegate as! AppDelegate

        myView.layer.borderWidth=2
        myView.layer.borderColor=UIColor.clear.cgColor
        yourView.layer.borderWidth=2
        yourView.layer.borderColor=UIColor.clear.cgColor
        myName.text = UIDevice.current.name
        yourName.text = appDelegate.mcManager.session.connectedPeers[0].displayName
        updateBetAndChips()
        
        // swipedown
        swipeDownRec.addTarget(self, action: #selector(GameViewController.finishBetting(_:)))
        swipeDownRec.direction = .down
        self.view!.addGestureRecognizer(swipeDownRec)
        // touch
        tapRec.addTarget(self, action:#selector(GameViewController.touchBet))
        tapRec.numberOfTouchesRequired = 1
        tapRec.numberOfTapsRequired = 1
        self.view!.addGestureRecognizer(tapRec)
        NotificationCenter.default.addObserver(self, selector: #selector(didReceiveCardInfo), name: Notification.Name("CardNotification"), object: nil)
    }
    
    @IBAction func chooseFirst(_ sender: Any) {
        pickFirstCards()
        chooseFirstButton.isHidden = true
        chooseFirstButton.isEnabled = false
    }
    
    // send number to other player
    func sendNum(_ num: Int) {
        var temp = num
        let data = NSData(bytes: &temp, length: MemoryLayout<NSInteger>.size)
        do {
            try appDelegate.mcManager.session.send(data as Data, toPeers: appDelegate.mcManager.session.connectedPeers, with: MCSessionSendDataMode.reliable)
        } catch {
            print(error)
        }
    }
    
    func pickFirstCards() {
        var nums = [1,2,3,4,5,6,7,8,9,10]
        let myFirstCard = nums.remove(at: Int(arc4random_uniform(UInt32(10))))
        let yourFirstCard = nums.remove(at: Int(arc4random_uniform(UInt32(9))))
        
        if (myFirstCard > yourFirstCard) {  // 내가 먼저면 상대카드+20 전송
            sendNum(yourFirstCard+20)
            currentGame.meFirst = true
            self.updateTurn(myturn: true)
        } else {                            // 상대방이 먼저면 상대카드+30 전송
            sendNum(yourFirstCard+30)
            currentGame.meFirst = false
            self.updateTurn(myturn: false)
        }
        startMotion()
        updateCardImage(myFirstCard)
        pickCards()
    }
    
    // 카드를 각각 뽑아 전송하기 함수
    func pickCards() {
        let myNewCard = currentGame.pickCard()
        let yourNewCard = currentGame.pickCard()
        currentGame.nextSet = false
        currentGame.myCard = myNewCard
        currentGame.yourCard = yourNewCard
        
        // 자신의 카드, 상대에게는 상대의 카드
        sendNum(myNewCard)
        // 상대의 카드, 상대에게는 자신의 카드
        sendNum(yourNewCard+10)
    }
    
    // touch 되었을 때 함수
    func touchBet() {
        if (currentGame.myturn == true && (currentGame.myBet - currentGame.yourBet < currentGame.yourChips) && currentGame.myChips > 0 && currentGame.newSet == false && currentGame.myBet != 0 && touchPossible){
            // 첫 배팅은 무조건 myBet과 yourBet이 같도록 하는것
            if (currentGame.myBet < currentGame.yourBet){
                let diff: Int = currentGame.yourBet - currentGame.myBet
                cntTouch += diff
                currentGame.myBet += diff
                currentGame.myChips -= diff
            }else{                      //일반적인 경우
                cntTouch += 1
                currentGame.myBet += 1
                currentGame.myChips -= 1
            }
            AudioServicesPlaySystemSound (systemSoundID_betting)
            
            myBet.text = currentGame.myBet.description
            myChips.text = currentGame.myChips.description
            // 화면 터치는 101을 보냄
            sendNum(101)
        }
    }
    
    // update card image
    func updateCardImage(_ num: Int) {
        //AudioServicesPlaySystemSound (self.systemSoundID_cardChange)
        let currentCard = UIImage(named: "card\(num).png")
        self.cardView.image = currentCard
    }
    
    // 초록색 부분의 bet과 chips 수를 update
    func updateBetAndChips() {
        myBet.text = currentGame.myBet.description
        yourBet.text = currentGame.yourBet.description
        myChips.text = currentGame.myChips.description
        yourChips.text = currentGame.yourChips.description
    }
    
    func updateTurn(myturn: Bool) {
        if myturn {
            currentGame.myturn = true
            myView.layer.borderColor=UIColor.black.cgColor
            yourView.layer.borderColor=UIColor.clear.cgColor
        } else {
            currentGame.myturn = false
            yourView.layer.borderColor=UIColor.black.cgColor
            myView.layer.borderColor=UIColor.clear.cgColor
        }
    }
    
    // 기본으로 하나씩 배팅하는 것
    func initialBet() {
        currentGame.myBet += 1
        currentGame.yourBet += 1
        currentGame.myChips -= 1
        currentGame.yourChips -= 1
    }
    
    // 아래 swipe로 배팅을 종료시키는 것,
    func finishBetting(_ sender: UISwipeGestureRecognizer) {
        // 배팅 종료할 때 사운드
        if currentGame.myturn {
            AudioServicesPlaySystemSound (self.systemSoundID_finishBetting)
            if let result = currentGame.myTurn(){
                if (result){
//                    self.finalResultLabel.text = "승리"
//                    moveToResult(result: resultType.win)
                    gameResult = resultType.win
                } else{
//                    self.finalResultLabel.text = "패배"
//                    moveToResult(result: resultType.loose)
                    gameResult = resultType.loose
                }
            }
            if (currentGame.newSet==true) {
                seeCard.isHidden = false
            }
            // 상대에게 100을 보냄
            sendNum(100)
            
            updateTurn(myturn: false)
            cntTouch = 0
            
            // 게임을 이긴사람이 카드를 각각 뽑아 전송하기
            if (currentGame.nextSet == true){
                updateTurn(myturn: true)
                self.pickCards()
            }
        }
    }
    
    func initializecurrentGame() {
        currentGame.cardSet = [1,1,2,2,3,3,4,4,5,5,6,6,7,7,8,8,9,9,10,10]
        currentGame.myBet = 0
        currentGame.yourBet = 0
        currentGame.myChips = 30
        currentGame.yourChips = 30
        currentGame.myturn = false
        currentGame.newSet = false
        currentGame.nextSet = false
        updateCardImage(0)
    }
    
    func startMotion() {
        // 핸드폰을 머리 위로 올리면 카드가 보이게 하는 것
        manager.accelerometerUpdateInterval = 0.6
        manager.startAccelerometerUpdates(to: OperationQueue.current!) { (data, error) in
            if let myData1 = data
            {
                // 들었을 때
                if myData1.acceleration.y < -0.85 {
                    self.sendNum(50)
                    if (currentGame.myBet == 0 && currentGame.yourBet == 0 && currentGame.newSet == false) {
                        self.updateCardImage(currentGame.myCard)
                        self.initialBet()
                        self.updateBetAndChips()
                    }
                }
                else if myData1.acceleration.y > -0.3 {
                    touchPossible = false
                    //                    if self.result != nil {
                    //    self.finalResultLabel.isHidden = false
                    //                    }
                    if (currentGame.newSet == true) {
                        currentGame.newSet = false
                        self.seeCard.isHidden = true
                        sleep(1)
                        self.updateBetAndChips()
                        
                        if (currentGame.myChips == 0) {
                            self.moveToResult(result: .loose)
                        } else if (currentGame.yourChips==0) {
                            self.moveToResult(result: .win)
                        }
                    }
                }
            }
        }
    }

    
    func didReceiveCardInfo(notification: NSNotification) {
        if let cardInfo = notification.userInfo as! [String: Int]?
        {
            if let num = cardInfo["number"] {
                if (num <= 10) {       // 상대 카드 숫자 (1~10)
                    currentGame.yourCard = num
                    if let index = currentGame.cardSet.index(of : currentGame.yourCard){
                        currentGame.cardSet.remove(at: index)
                    }
                }
                else if (num <= 20) {       // 내 카드 숫자+10 (11~20)
                    currentGame.myCard = num - 10
                    if let index = currentGame.cardSet.index(of : currentGame.myCard){
                        currentGame.cardSet.remove(at: index)
                    }
                }
                else if (num <= 30) {       // 상대방이 선플레이어일때 카드숫자+20 (21~30)
                    self.startMotion()
                    self.updateCardImage(num-20)
                    currentGame.meFirst = false
                    self.updateTurn(myturn: false)
                }
                else if (num <= 40) {       // 내가 선플레이어일때 카드숫자+30 (31~40)
                    self.startMotion()
                    self.updateCardImage(num-30)
                    currentGame.meFirst = true
                    self.updateTurn(myturn: true)
                }
                else if (num == 100) {            // 상대방 배팅이 끝났을 때
                    if let result = currentGame.yourTurn(){
                        if (result){
                            gameResult = resultType.win
//                            moveToResult(result: resultType.win)
//                            self.finalResultLabel.text = "승리"
                        } else{
                            gameResult = resultType.loose
//                            moveToResult(result: resultType.loose)
//                        self.finalResultLabel.text = "패배"
                        }
                    }
                    self.updateTurn(myturn: true)
                    if (currentGame.newSet) {
                        self.seeCard.isHidden = false
                        if !(currentGame.nextSet) {
                            self.updateTurn(myturn: false)
                        }
                    }
                    
                    // 게임을 이긴사람이 카드를 각각 뽑아 전송하기
                    if (currentGame.nextSet == true){
                        self.pickCards()
                    }
                }
                    // 상대가 배팅을 하나씩 했을 때
                else if (num == 101) {
                    //첫 배팅일 경우 숫자를 맞추는 배팅
                    if (currentGame.myBet > currentGame.yourBet){
                        let diff: Int = currentGame.myBet - currentGame.yourBet
                        currentGame.yourBet += diff
                        currentGame.yourChips -= diff
                    }else{                      //일반적인 경우
                        currentGame.yourBet += 1
                        currentGame.yourChips -= 1
                    }
                    self.yourBet.text = currentGame.yourBet.description
                    self.yourChips.text = currentGame.yourChips.description
                }
            }
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func moveToResult(result: resultType) {
        gameResult = result
        self.performSegue(withIdentifier: "toResultSegue", sender: self)
    }

}
