# Swift-DispatchGroup-VS-Semaphore

[https://medium.com/@dkw5877/more-gcd-semaphores-and-dispatch-groups-5b767c700a03](https://medium.com/@dkw5877/more-gcd-semaphores-and-dispatch-groups-5b767c700a03)


[DispatchGroup vs Semaphore Youtube Resource](https://www.youtube.com/watch?v=6rJN_ECd1XM)

# Semaphore

- An object that controls access to a resource across multiple execution contexts through use of a traditional counting semaphore.
- A dispatch semaphore is an efficient implementation of a traditional counting semaphore. Dispatch semaphores call down to the kernel only when the calling thread needs to be blocked. If the calling semaphore does not need to block, no kernel call is made.

You increment a semaphore count by calling the [signal()](apple-reference-documentation://hsJnXMIUyC) method, and decrement a semaphore count by calling [wait()](apple-reference-documentation://hsDeWmIZaU) or one of its variants that specifies a timeout.

- Semaphores allow you to block access to a given code block until the block completes.

```swift
var semaphore = DispatchSemaphore(value: 0)

someMethodThatTakesABlock { (data) in
    //do stuff with the data that has been returned
    semaphore.signal()
}

semaphore.wait(timeout: DispatchTime.distantFuture)
```

⇒ First we create the semaphore and initialize it with a value of zero. A semaphore blocks when the value of the semaphore is less then zero. In the above example calling semaphore.wait(timeout:) decrements the counting semaphore reducing the value to -1 and causes any other process trying to run the code to wait until the completion block finishes. An important point to remember is to signal the semaphore (increment) using semaphore.signal() once the block or task completes. This allows any pending processes to enter and execute the code block.

- SharedResource Example.

```swift
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
```

ℹ️  Shared Resource가 있을 때 더욱 효과적.

# DispatchGroup

- having a series of asynchronous tasks executing on different threads and needing a way to perform some task after all the asynchronous tasks have completed.
- “A dispatch group is a mechanism for monitoring a set of blocks. Your application can monitor the blocks in the group synchronously or asynchronously depending on your needs. By extension, a group can be useful for synchronizing for code that depends on the completion of other tasks.

- `dispatchGroup.wait`  ⇒  Like semaphore, prevents other process from running for a while.

```swift
let dispatchQueue = DispatchQueue(label: "dispatchQueue", qos:.userInitiated)
let dispatchGroup = DispatchGroup.init()

dispatchGroup.enter()
dispatchQueue.async(group: dispatchGroup) {
    someMethodThatTakesABlock { [unowned self] (data) in
        //do stuff with the data that has been returned
        dispatchGroup.leave()
    }
}

dispatchGroup.wait(timeout: DispatchTime.distantFuture)
```

⇒ First we create the dispatch queue and group. We then send any asynchronous tasks to the dispatch group and queue using the dispatchGroup.async(group:) call. We can then wait for the asynchronous tasks to complete using dispatchGroup.wait(timeout:). There is an alternative way that I found a little easier to use that is shown below.

- `dispatchGroup.notify()`

```swift
let dispatchQueue = DispatchQueue(label: "dispatchQueue", qos:.userInitiated)
let dispatchGroup = DispatchGroup.init()

dispatchGroup.enter()
someMethodThatTakesABlock { [unowned self] (data) in
    //do stuff with the data that has been returned
    dispatchGroup.leave()
}

dispatchGroup.notify(queue: dispatchQueue) {
    //code to execute once all asynchronous code is complete
}
```

⇒ First, we create a queue for the dispatch group callback method and then create the dispatch group itself. We then use dispatchGroup.enter()/leave() methods to indicate when a particular asynchronous task is added to the dispatch group and removed from the group when it completes. You can then wait for all the tasks to complete using the dispatchGroup.notify(...) method. When all tasks have completed the dispatchGroup.notify(...) block is then executed. This approach requires that the dispatchGroup.enter()/leave() calls be balanced or your app will crash, so you need to be certain to account for all situations where the asynchronous task completes or fails. For example, if you have a completion and failure block as is common in accessing web services then you would also need to call dispatchGroup.leave() in the failure block.

```swift
//
//  ViewController.swift
//  Semaphore vs DispatchGroup
//
//  Created by shin seunghyun on 2020/07/01.
//  Copyright © 2020 shin seunghyun. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    var sharedResource: [String] = [String]()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let dispatchGroup = DispatchGroup()
        
        dispatchGroup.enter()
        fetchImage { (_, _) in
            print("Finished fetching image 1")
            dispatchGroup.leave()
        }
        
        dispatchGroup.enter()
        fetchImage { (_, _) in
            print("Finished fetching image 2")
            dispatchGroup.leave()
        }
        
        dispatchGroup.enter()
        fetchImage { (_, _) in
            print("Finished fetching image 3")
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
```

- DispatchGroup with `SharedResource`

❗️ It can crash your app!

```swift
//
//  ViewController.swift
//  Semaphore vs DispatchGroup
//
//  Created by shin seunghyun on 2020/07/01.
//  Copyright © 2020 shin seunghyun. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
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
```
