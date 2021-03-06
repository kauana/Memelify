//
//  TrendingViewController.swift
//  Memelify
//
//  Created by Kauana, William and Dat.
//  Copyright © 2018 Memelify. All rights reserved.
//

import UIKit
import Alamofire

class TrendingViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, MemeSharingProtocol, refreshProtocol {

    //refresh specific row based on favorite click
    func refreshFavs(row: Int) {
        let index = NSIndexPath(row: row, section: 0)
        self.memeTable.reloadRows(at: [index as IndexPath], with: UITableView.RowAnimation.none)
    }

    //pull down to refresh ui element
    lazy var refreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action:
                #selector(HomeViewController.handleRefresh(_:)),
            for: UIControl.Event.valueChanged)
        refreshControl.tintColor = UIColor.init(red: 0, green: 133 / 255, blue: 145 / 255, alpha: 1.0)

        return refreshControl
    }()

    @IBOutlet weak var memeTable: UITableView!

    var memes = [MemeObject]()
    var favorites: [String?] = []
    var darkMode: DarkMode?
    var offset = 0

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return memes.count
    }

    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return memes[indexPath.row].height!
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let currentImage = memes[indexPath.row].image
        memes[indexPath.row].height = (memes[indexPath.row].image?.size.height)! + CGFloat(40)
        let ratio = currentImage!.cropRatio()
        return (tableView.frame.width / ratio) + 40
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MemeTilePrototype", for: indexPath) as! MemeTile

        self.favorites = UserDefaults.standard.stringArray(forKey: "favs")!
        cell.row = indexPath.row
        cell.memeSharingDelegate = self
        cell.trendingrefreshDelegate = self
        cell.obj = memes[indexPath.row]
        cell.meme.image = cell.obj?.image
        cell.karma.text = String(cell.obj?.likes ?? 0)
        if cell.fav() {
            cell.favorite.setImage(UIImage(named: "selected-heart"), for: .normal)
        } else {
            cell.favorite.setImage(UIImage(named: "unselected-heart"), for: .normal)
        }
        return cell
    }

    // handles adding more memes once the user scrolls to the bottom of the table
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        let bottom: CGFloat = scrollView.contentSize.height - scrollView.frame.size.height
        let buffer: CGFloat = 100
        let scrollPosition = scrollView.contentOffset.y

        // Reached the bottom of the list
        if scrollPosition > bottom - buffer {
            print("natural making additional request...")
            makeAdditionalRequest()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.darkMode = DarkMode(navigationController: navigationController!, tabBarController: tabBarController!, views: [memeTable])
        self.memeTable.addSubview(self.refreshControl)
        self.favorites = UserDefaults.standard.stringArray(forKey: "favs")!

        memeTable.dataSource = self
        memeTable.delegate = self

        makeRequest(api: "https://memelify.herokuapp.com/api/memes/hot")
    }

    func getData(from url: URL, completion: @escaping (Data?, URLResponse?, Error?) -> ()) {
        URLSession.shared.dataTask(with: url, completionHandler: completion).resume()
    }

    func makeRequest(api: String) {
        let sv = UIViewController.displaySpinner(onView: self.view)

        Alamofire.request(api).responseJSON { response in
            if let json = response.result.value as? [String: Any] {
                guard let memes = json["memes"] as? [[String: Any]] else {
                    return
                }
                self.memes.removeAll()
                for meme in memes {
                    guard let url = URL(string: meme["url"] as! String) else {
                        continue
                    }

                    let id = meme["id"] as? String
                    let date = meme["created"] as? String
                    let title = meme["title"] as? String
                    let likes = meme["likes"] as? Int

                    self.getData(from: url) { data, response, error in
                        guard let data = data, error == nil else { return }
                        DispatchQueue.main.async() {
                            let newMeme = MemeObject(id: id!, created: date!, title: title!, likes: likes!, pic: data)
                            self.memes.append(newMeme)
                            self.memeTable.reloadData()
                            UIViewController.removeSpinner(spinner: sv)
                        }
                    }
                }
            }
        } // end of alomafire request
    }

    func makeAdditionalRequest() {
        offset = offset + 10

        let request = "https://memelify.herokuapp.com/api/memes/hot?offset=" + String(offset) + "&limit=10"

        Alamofire.request(request).responseJSON { response in
            if let json = response.result.value as? [String: Any] {
                guard let memes = json["memes"] as? [[String: Any]] else {
                    return
                }

                for meme in memes {
                    guard let url = URL(string: meme["url"] as! String) else {
                        continue
                    }

                    let id = meme["id"] as? String
                    let date = meme["created"] as? String
                    let title = meme["title"] as? String
                    let likes = meme["likes"] as? Int

                    self.getData(from: url) { data, response, error in
                        guard let data = data, error == nil else { return }
                        DispatchQueue.main.async() {
                            let newMeme = MemeObject(id: id!, created: date!, title: title!, likes: likes!, pic: data)
                            self.memes.append(newMeme)

                            self.memeTable.reloadData()
                        }
                    }
                }
            }
        }
    }

    // Shows Memelify logo on the navigation bar
    override func viewDidAppear(_ animated: Bool) {
        self.favorites = UserDefaults.standard.stringArray(forKey: "favs")!
        self.memeTable.reloadData()
        let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 50, height: 50))
        imageView.contentMode = .scaleAspectFit
        imageView.image = UIImage(named: "Memelify-transparent.png")
        navigationItem.titleView = imageView
    }

    @objc func handleRefresh(_ refreshControl: UIRefreshControl) {
        makeRequest(api: "https://memelify.herokuapp.com/api/memes/hot")
        self.memeTable.reloadData()
        refreshControl.endRefreshing()
    }

    func share(meme: UIImage, message: String) {
        print("Sharing in VC")
        let shareMemeVC = UIActivityViewController(activityItems: [meme, message], applicationActivities: nil)
        shareMemeVC.popoverPresentationController?.sourceView = self.view
        self.present(shareMemeVC, animated: true, completion: nil)
    }
}
