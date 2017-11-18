//
//  ViewController.swift
//  DOPFileInspector
//
//  Created by 纬洲 冯 on 17/11/2017.
//  Copyright © 2017 fengweizhou. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        let btn = UIButton(type: .custom)
        btn.setTitle("open", for: .normal)
        btn.setTitleColor(UIColor.black, for: .normal)
        btn.addTarget(self, action: #selector(openFileInspector(_:)), for: .touchUpInside)
        self.view.addSubview(btn)
        btn.frame = CGRect(x: 0, y: 0, width: 100, height: 100)
        btn.center = self.view.center
        
        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        let filePath = documentsPath + "/user.log"
        FileManager.default.createFile(atPath: filePath, contents: nil, attributes: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @objc func openFileInspector(_ sender: UIButton) {
        let vc = DOPFileInspectorController()
        let nvc = UINavigationController(rootViewController: vc)
        self.show(nvc, sender: nil)
    }

}

