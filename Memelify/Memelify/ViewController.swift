//
//  ViewController.swift
//  Memelify
//
//  Created by Will J on 11/15/18.
//  Copyright © 2018 Memelify. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let temp = UITableViewCell()
        return temp
    }
    
    
    @IBOutlet weak var memeTable: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        memeTable.dataSource = self
        // Do any additional setup after loading the view, typically from a nib.
    }

}

