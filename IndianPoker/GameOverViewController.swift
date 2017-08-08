//
//  GameOverViewController.swift
//  IndianPoker
//
//  Created by 설윤아 on 2017. 8. 7..
//  Copyright © 2017년 noriteo. All rights reserved.
//

import UIKit

var gameResult = resultType.win

class GameOverViewController: UIViewController {

    @IBOutlet weak var finalResultLabel: UILabel!
    @IBOutlet weak var playAgainButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if gameResult == .win {
            finalResultLabel.text = "승리"
        } else if gameResult == .loose {
            finalResultLabel.text = "패배"
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func playAgain(_ sender: Any) {
        currentGame = Game()
        self.view.removeFromSuperview()
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
