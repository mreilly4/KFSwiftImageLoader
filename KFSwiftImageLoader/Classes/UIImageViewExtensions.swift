//
//  Created by Kiavash Faisali on 2015-03-17.
//  Copyright (c) 2015 Kiavash Faisali. All rights reserved.
//

import UIKit
import ImageIO

// MARK: - UIImageView Associated Object Keys
private var indexPathIdentifierAssociationKey: UInt8 = 0
private var completionHolderAssociationKey: UInt8 = 0

// MARK: - UIImageView Extension
public extension UIImageView {
    // MARK: - Associated Objects
    final internal var indexPathIdentifier: Int! {
        get {
            return objc_getAssociatedObject(self, &indexPathIdentifierAssociationKey) as? Int
        }
        set {
            objc_setAssociatedObject(self, &indexPathIdentifierAssociationKey, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    final internal var completionHolder: CompletionHolder! {
        get {
            return objc_getAssociatedObject(self, &completionHolderAssociationKey) as? CompletionHolder
        }
        set {
            objc_setAssociatedObject(self, &completionHolderAssociationKey, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    // MARK: - Image Loading Methods
    /**
        Asynchronously downloads an image and loads it into the `UIImageView` using a URL `String`.
        
        - parameter urlString: The image URL in the form of a `String`.
        - parameter placeholderImage: `UIImage?` representing a placeholder image that is loaded into the view while the asynchronous download takes place. The default value is `nil`.
        - parameter completion: An optional closure that is called to indicate completion of the intended purpose of this method. It returns two values: the first is a `Bool` indicating whether everything was successful, and the second is `NSError?` which will be non-nil should an error occur. The default value is `nil`.
    */
    final public func loadImage(urlString: String,
                         placeholderImage: UIImage? = nil,
                               completion: ((_ success: Bool, _ error: NSError?) -> Void)? = nil)
    {
        guard let url = URL(string: urlString) else {
            DispatchQueue.main.async {
                completion?(false, nil)
            }
            
            return
        }
        
        loadImage(url: url, placeholderImage: placeholderImage, completion: completion)
    }
    
    /**
        Asynchronously downloads an image and loads it into the `UIImageView` using a `URL`.
     
        - parameter url: The image `URL`.
        - parameter placeholderImage: `UIImage?` representing a placeholder image that is loaded into the view while the asynchronous download takes place. The default value is `nil`.
        - parameter completion: An optional closure that is called to indicate completion of the intended purpose of this method. It returns two values: the first is a `Bool` indicating whether everything was successful, and the second is `NSError?` which will be non-nil should an error occur. The default value is `nil`.
     */
    final public func loadImage(url: URL,
                   placeholderImage: UIImage? = nil,
                         completion: ((_ success: Bool, _ error: NSError?) -> Void)? = nil)
    {
        let cacheManager = KFImageCacheManager.sharedInstance
        
        var request = URLRequest(url: url, cachePolicy: cacheManager.session.configuration.requestCachePolicy, timeoutInterval: cacheManager.session.configuration.timeoutIntervalForRequest)
        request.addValue("image/*", forHTTPHeaderField: "Accept")
        
        loadImage(request: request, placeholderImage: placeholderImage, completion: completion)
    }
    
    /**
        Asynchronously downloads an image and loads it into the `UIImageView` using a `URLRequest`.
     
        - parameter request: The image URL in the form of a `URLRequest`.
        - parameter placeholderImage: `UIImage?` representing a placeholder image that is loaded into the view while the asynchronous download takes place. The default value is `nil`.
        - parameter completion: An optional closure that is called to indicate completion of the intended purpose of this method. It returns two values: the first is a `Bool` indicating whether everything was successful, and the second is `NSError?` which will be non-nil should an error occur. The default value is `nil`.
     */
    final public func loadImage(request: URLRequest,
                       placeholderImage: UIImage? = nil,
                             completion: ((_ success: Bool, _ error: NSError?) -> Void)? = nil)
    {
        self.completionHolder = CompletionHolder(completion: completion)
        self.indexPathIdentifier = -1
        
        guard let urlAbsoluteString = request.url?.absoluteString else {
            self.completionHolder.completion?(false, nil)
            print("about to return on 92")
            return
        }
        
        let cacheManager = KFImageCacheManager.sharedInstance
        let fadeAnimationDuration = cacheManager.fadeAnimationDuration
        let sharedURLCache = URLCache.shared
        
        func loadImage(_ image: UIImage) -> Void {
            print("about to loadImage on 101")
            DispatchQueue.main.async {
////                if initialIndexIdentifier == self.indexPathIdentifier {
                UIView.transition(with: self, duration: fadeAnimationDuration, options: .transitionCrossDissolve, animations: {
                    print("about to set Image on 105")
                    self.image = image
                    
                })
                self.completionHolder.completion?(true, nil)
//                }
            }
            
//            self.completionHolder.completion?(true, nil)
        }
        
        // If there's already a cached image, load it into the image view.
        if let image = cacheManager[urlAbsoluteString] {
            print("about to loadImage 116")
            loadImage(image)
            if urlAbsoluteString.contains(".gif")
            {
                if let cachedResponse = sharedURLCache.cachedResponse(for: request), let creationTimestamp = cachedResponse.userInfo?["creationTimestamp"] as? CFTimeInterval, (Date.timeIntervalSinceReferenceDate - creationTimestamp) < Double(cacheManager.diskCacheMaxAge)
                {
                    print("1 image data : \(cachedResponse.data)")
                    if let source = CGImageSourceCreateWithData(cachedResponse.data as CFData, nil)
                    {
                        print("1 IMAGE IS GIF! in cacheresponse")
                        loadImage(self.animatedImageWithSource(source)!)
                        cacheManager[urlAbsoluteString] = self.animatedImageWithSource(source)!
                    }
                    else
                    {
                        print("1 image doesn't exist")
                    }
                }
            }
            else
            {
//                loadImage(image)
                print("NOTHING TO DO.  WE HAVE IMAGE AND NOT GIFF")
            }
        }
        // If there's already a cached response, load the image data into the image view.
        else if let cachedResponse = sharedURLCache.cachedResponse(for: request), let image = UIImage(data: cachedResponse.data), let creationTimestamp = cachedResponse.userInfo?["creationTimestamp"] as? CFTimeInterval, (Date.timeIntervalSinceReferenceDate - creationTimestamp) < Double(cacheManager.diskCacheMaxAge) {
            if urlAbsoluteString.contains(".gif")
            {
                print("2 image data : \(cachedResponse.data)")
                if let source = CGImageSourceCreateWithData(cachedResponse.data as CFData, nil)
                {
                    print("2 IMAGE IS GIF! in cacheresponse")
                    loadImage(self.animatedImageWithSource(source)!)
                    cacheManager[urlAbsoluteString] = self.animatedImageWithSource(source)!
                }
                else
                {
                    print("2 image doesn't exist")
                }
            }
            else
            {
                loadImage(image)
                cacheManager[urlAbsoluteString] = image
            }
        }
        // Either begin downloading the image or become an observer for an existing request.
        else
        {
            // Remove the stale disk-cached response (if any).
            sharedURLCache.removeCachedResponse(for: request)
            
            // Set the placeholder image if it was provided.
            if let image = placeholderImage {
                self.image = image
            }
            
            // Should the image be shown in a cell, walk the view hierarchy to retrieve the index path from the tableview or collectionview.
            let tableView: UITableView
            let collectionView: UICollectionView
            var tableViewCell: UITableViewCell?
            var collectionViewCell: UICollectionViewCell?
            var parentView = self.superview
            
            while parentView != nil {
                if let view = parentView as? UITableViewCell {
                    tableViewCell = view
                }
                else if let view = parentView as? UITableView {
                    tableView = view
                    
                    if let cell = tableViewCell {
                        let indexPath = tableView.indexPathForRow(at: cell.center)
                        self.indexPathIdentifier = indexPath?.hashValue ?? -1
                    }
                    break
                }
                else if let view = parentView as? UICollectionViewCell {
                    collectionViewCell = view
                }
                else if let view = parentView as? UICollectionView {
                    collectionView = view
                    
                    if let cell = collectionViewCell {
                        let indexPath = collectionView.indexPathForItem(at: cell.center)
                        self.indexPathIdentifier = indexPath?.hashValue ?? -1
                    }
                    break
                }
                
                parentView = parentView?.superview
            }
            
            let initialIndexIdentifier = self.indexPathIdentifier as Int
            
            // If the image isn't already being downloaded, begin downloading the image.
            if cacheManager.isDownloadingFromURL(urlAbsoluteString) == false {
                cacheManager.setIsDownloadingFromURL(true, forURLString: urlAbsoluteString)
                let dataTask = cacheManager.session.dataTask(with: request) {
                    taskData, taskResponse, taskError in
                    
                    guard let data = taskData, let response = taskResponse, var image = UIImage(data: data), taskError == nil else {
                        DispatchQueue.main.async {
                            cacheManager.setIsDownloadingFromURL(false, forURLString: urlAbsoluteString)
                            cacheManager.removeImageCacheObserversForKey(urlAbsoluteString)
                            self.completionHolder.completion?(false, taskError as NSError?)
                        }
                        
                        return
                    }
                    print("3 urlAbsoluteString : \(urlAbsoluteString)")
                    if urlAbsoluteString.contains(".gif")
                    {
                        if let source = CGImageSourceCreateWithData(data as CFData, nil)
                        {
                            print("3 NEW IMAGE IS GIF!")
                            print("3 source : \(source)")
                            DispatchQueue.main.async {
                                if initialIndexIdentifier == self.indexPathIdentifier {
                                    UIView.transition(with: self, duration: fadeAnimationDuration, options: .transitionCrossDissolve, animations: {
                                        self.image = self.animatedImageWithSource(source)
                                    })
                                }
                                
                                cacheManager[urlAbsoluteString] = self.animatedImageWithSource(source)
                                
                                let responseDataIsCacheable = cacheManager.diskCacheMaxAge > 0 &&
                                    Double(data.count) <= 0.05 * Double(sharedURLCache.diskCapacity) &&
                                    (cacheManager.session.configuration.requestCachePolicy == .returnCacheDataElseLoad ||
                                        cacheManager.session.configuration.requestCachePolicy == .returnCacheDataDontLoad) &&
                                    (request.cachePolicy == .returnCacheDataElseLoad ||
                                        request.cachePolicy == .returnCacheDataDontLoad)
                                
                                if let httpResponse = response as? HTTPURLResponse, let url = httpResponse.url, responseDataIsCacheable {
                                    if var allHeaderFields = httpResponse.allHeaderFields as? [String: String] {
                                        allHeaderFields["Cache-Control"] = "max-age=\(cacheManager.diskCacheMaxAge)"
                                        if let cacheControlResponse = HTTPURLResponse(url: url, statusCode: httpResponse.statusCode, httpVersion: "HTTP/1.1", headerFields: allHeaderFields) {
                                            let cachedResponse = CachedURLResponse(response: cacheControlResponse, data: data, userInfo: ["creationTimestamp": Date.timeIntervalSinceReferenceDate], storagePolicy: .allowed)
                                            sharedURLCache.storeCachedResponse(cachedResponse, for: request)
                                        }
                                    }
                                }
                                
                                self.completionHolder.completion?(true, nil)
                            }
                        }
                        else
                        {
                            print("3 image doesn't exist")
                            
                        }
                        
                        //                            self.image = animatedImageWithSource(source)
                        //                            cacheManager[urlAbsoluteString] = self.image
                    }
                    else
                    {
                        print("3 else NOT a GIF")
                    DispatchQueue.main.async {
                        if initialIndexIdentifier == self.indexPathIdentifier {
                            UIView.transition(with: self, duration: fadeAnimationDuration, options: .transitionCrossDissolve, animations: {
                                self.image = image
                            })
                        }
                        
                        cacheManager[urlAbsoluteString] = image
                        
                        let responseDataIsCacheable = cacheManager.diskCacheMaxAge > 0 &&
                            Double(data.count) <= 0.05 * Double(sharedURLCache.diskCapacity) &&
                            (cacheManager.session.configuration.requestCachePolicy == .returnCacheDataElseLoad ||
                                cacheManager.session.configuration.requestCachePolicy == .returnCacheDataDontLoad) &&
                            (request.cachePolicy == .returnCacheDataElseLoad ||
                                request.cachePolicy == .returnCacheDataDontLoad)
                        
                        if let httpResponse = response as? HTTPURLResponse, let url = httpResponse.url, responseDataIsCacheable {
                            if var allHeaderFields = httpResponse.allHeaderFields as? [String: String] {
                                allHeaderFields["Cache-Control"] = "max-age=\(cacheManager.diskCacheMaxAge)"
                                if let cacheControlResponse = HTTPURLResponse(url: url, statusCode: httpResponse.statusCode, httpVersion: "HTTP/1.1", headerFields: allHeaderFields) {
                                    let cachedResponse = CachedURLResponse(response: cacheControlResponse, data: data, userInfo: ["creationTimestamp": Date.timeIntervalSinceReferenceDate], storagePolicy: .allowed)
                                    sharedURLCache.storeCachedResponse(cachedResponse, for: request)
                                }
                            }
                        }
                        
                        self.completionHolder.completion?(true, nil)
                    }
                    }
                }
                
                dataTask.resume()
            }
            // Since the image is already being downloaded and hasn't been cached, register the image view as a cache observer.
            else {
                weak var weakSelf = self
                cacheManager.addImageCacheObserver(weakSelf!, withInitialIndexIdentifier: initialIndexIdentifier, forKey: urlAbsoluteString)
            }
        }
    }
    
    func delayForImageAtIndex(_ index: Int, source: CGImageSource!) -> Double {
        var delay = 0.1
        print("source : \(source!)")
        let cfProperties = CGImageSourceCopyPropertiesAtIndex(source!, index, nil)
        print("cfProperties : \(cfProperties!)")
        if let gifProperties: CFDictionary = unsafeBitCast(
            CFDictionaryGetValue(cfProperties!,
                                 Unmanaged.passUnretained(kCGImagePropertyGIFDictionary).toOpaque()),
            to: CFDictionary.self)
        {
            //need to input this data if image doe not have it....

//            print("kcgImagePropertyGIFDictionary         : \(CFDictionaryContainsKey(cfProperties, "{GIF}"))")
//
//            let customGifProperties = [kCGImagePropertyGIFDictionary as String: [kCGImagePropertyGIFDelayTime as String: 0.1, kCGImagePropertyGIFUnclampedDelayTime as String: 0.1]] as! CFDictionary
//            print("gifProperties : \(String(describing: customGifProperties))")
//            let customGifPropertiesDict = unsafeBitCast(CFDictionaryGetValue(customGifProperties, Unmanaged.passUnretained(kCGImagePropertyGIFDictionary).toOpaque()), to: CFDictionary.self)
            
            
            
            
        var delayObject: AnyObject = unsafeBitCast(
            CFDictionaryGetValue(gifProperties as CFDictionary,
                                 Unmanaged.passUnretained(kCGImagePropertyGIFUnclampedDelayTime).toOpaque()),
            to: AnyObject.self)
        
        if delayObject.doubleValue == 0 {
            delayObject = unsafeBitCast(CFDictionaryGetValue(gifProperties,
                                                             Unmanaged.passUnretained(kCGImagePropertyGIFDelayTime).toOpaque()), to: AnyObject.self)
        }
        
        delay = delayObject as! Double
        }
        else
        {
            delay = 0.1
        }
        if delay < 0.1 {
            delay = 0.1
        }
        
        return delay
    }
    
    func gcdForPair(_ a: Int?, _ b: Int?) -> Int {
        var a = a
        var b = b
        if b == nil || a == nil {
            if b != nil {
                return b!
            } else if a != nil {
                return a!
            } else {
                return 0
            }
        }
        
        if a! < b! {
            let c = a
            a = b
            b = c
        }
        
        var rest: Int
        while true {
            rest = a! % b!
            
            if rest == 0 {
                return b!
            } else {
                a = b
                b = rest
            }
        }
    }
    
    func gcdForArray(_ array: Array<Int>) -> Int {
        if array.isEmpty {
            return 1
        }
        
        var gcd = array[0]
        
        for val in array {
            gcd = gcdForPair(val, gcd)
        }
        
        return gcd
    }
    
    func animatedImageWithSource(_ source: CGImageSource) -> UIImage? {
        let count = CGImageSourceGetCount(source)
        var images = [CGImage]()
        
        var delays = [Int]()
        
        for i in 0..<count {
            if let image = CGImageSourceCreateImageAtIndex(source, i, nil) {
                images.append(image)
            }
            
            let delaySeconds = delayForImageAtIndex(Int(i),
                                                    source: source)
            delays.append(Int(delaySeconds * 1000.0)) // Seconds to ms
        }
        
        let duration: Int = {
            var sum = 0
            
            for val: Int in delays {
                sum += val
            }
            
            return sum
        }()
        
        
        
        let gcd = gcdForArray(delays)
        var frames = [UIImage]()
        
        var frame: UIImage
        var frameCount: Int
        for i in 0..<count {
            frame = UIImage(cgImage: images[Int(i)])
            frameCount = Int(delays[Int(i)] / gcd)
            
            for _ in 0..<frameCount {
                frames.append(frame)
            }
        }
        
        let animation = UIImage.animatedImage(with: frames,
                                              duration: Double(duration) / 1000.0)
        
        return animation
    }
}
