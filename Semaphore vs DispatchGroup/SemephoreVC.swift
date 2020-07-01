//
//  SemephoreVC.swift
//  Semaphore vs DispatchGroup
//
//  Created by shin seunghyun on 2020/07/01.
//  Copyright © 2020 shin seunghyun. All rights reserved.
//

import UIKit

class SemaphoreVC: UIViewController {
    
    var sharedResource: [String] = [String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        print("Hello world")
        
        let semaphore: DispatchSemaphore = DispatchSemaphore(value: 0)
        
        let dispatchQueue: DispatchQueue = DispatchQueue.global(qos: .background)
        
        //DispatchQueue.async를 적용하지 않아도 되긴 된다. 그냥 concurrent하게하려고 추가한 것
        dispatchQueue.async {
            self.fetchImage { (_, _) in
                print("Finished fetching image 1")
                self.sharedResource.append("1")
                semaphore.signal()
            }
            semaphore.wait()
            self.fetchImage { (_, _) in
                print("Finished fetching image 2")
                self.sharedResource.append("2")
                semaphore.signal()
            }
            semaphore.wait()
            self.fetchImage { (_, _) in
                print("Finished fetching image 3")
                self.sharedResource.append("3")
                semaphore.signal()
            }
            semaphore.wait()
        }
        
        print("Start fetching images")
        
    }
    
    func fetchImage(completion: @escaping(UIImage?, Error?) -> ()) {
        guard let url: URL = URL(string: "https://encrypted-tbn0.gstatic.com/images?q=tbn%3AANd9GcQQ7CoqlHVkGqkv8cjCtNYY9pI99vjRVpugZg&usqp=CAU") else { return }
        URLSession.shared.dataTask(with: url) { (data, response, error) in
            completion(UIImage(data: data ?? Data()), nil)
        }.resume()
    }
    
}
