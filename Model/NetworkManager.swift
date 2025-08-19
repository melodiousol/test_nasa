//
//  NetworkManager.swift
//  test
//
//  Created by 黃盈雅 on 2025/8/13.
//

import Foundation

class NetworkManager {
    static let shared = NetworkManager()
    
    private init() {}
    
    func fetchNASAData(for date: String? = nil, completion: @escaping (Result<apiNASA, Error>) -> Void) {
        var urlString = "https://api.nasa.gov/planetary/apod?api_key=kddMeqEOGJDpcKlcbhyd3szvXCdu8l1N5QYuwvnq"
        if let date = date {
            urlString += "&date=\(date)"
        }
        guard let url = URL(string: urlString) else {
            completion(.failure(NSError(domain:"Invalid URL", code:0)))
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
                completion(.failure(NSError(domain: "HTTP Error", code: httpResponse.statusCode)))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain:"No data", code:0)))
                return
            }
            
            do {
                let decoder = JSONDecoder()
                let result = try decoder.decode(apiNASA.self, from: data)
                completion(.success(result))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
}
