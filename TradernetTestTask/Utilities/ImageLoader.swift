//
//  ImageLoader.swift
//  TradernetTestTask
//

import UIKit

final class ImageLoader {

    static let shared = ImageLoader()

    private let cache = NSCache<NSURL, UIImage>()
    private let session = URLSession.shared

    private init() {}

    @discardableResult
    func loadImage(from url: URL, completion: @escaping (UIImage?) -> Void) -> URLSessionDataTask? {
        if let cached = cache.object(forKey: url as NSURL) {
            completion(cached)
            return nil
        }

        let task = session.dataTask(with: url) { [weak self] data, _, _ in
            guard let data = data, let image = UIImage(data: data) else {
                DispatchQueue.main.async { completion(nil) }
                return
            }
            self?.cache.setObject(image, forKey: url as NSURL)
            DispatchQueue.main.async { completion(image) }
        }
        task.resume()
        return task
    }
}
