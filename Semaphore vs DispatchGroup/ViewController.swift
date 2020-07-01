//
//  ViewController.swift
//  Semaphore vs DispatchGroup
//
//  Created by shin seunghyun on 2020/07/01.
//  Copyright © 2020 shin seunghyun. All rights reserved.
//

import UIKit

class DispatchGroupVC: UIViewController {
    
    var sharedResource: [String] = [String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let dispatchGroup = DispatchGroup()
        
        dispatchGroup.enter()
        fetchImage { (_, _) in
            print("Finished fetching image 1")
            self.sharedResource.append("1")
            dispatchGroup.leave()
        }
        
        dispatchGroup.enter()
        fetchImage { (_, _) in
            print("Finished fetching image 2")
            self.sharedResource.removeAll()
            dispatchGroup.leave()
        }
        
        dispatchGroup.enter()
        fetchImage { (_, _) in
            print("Finished fetching image 3")
            self.sharedResource += ["3", "4", "5", "6"]
            dispatchGroup.leave()
        }
        
        dispatchGroup.notify(queue: .main) {
            print("Finished fetching images...")
        }
        
        print("Waiting for images to finish fetching...")
        
    }

    func fetchImage(completion: @escaping(UIImage?, Error?) -> ()) {
        guard let url: URL = URL(string: "https://encrypted-tbn0.gstatic.com/images?q=tbn%3AANd9GcQQ7CoqlHVkGqkv8cjCtNYY9pI99vjRVpugZg&usqp=CAU") else { return }
        URLSession.shared.dataTask(with: url) { (data, response, error) in
            completion(UIImage(data: data ?? Data()), nil)
        }.resume()
    }
    

}

