import Foundation
import AVFoundation
import UIKit
import Combine 


public class EasyNet{
    // Create a PassthroughSubject to broadcast status updates
    public var unauthorizedSubject = PassthroughSubject<Void, Never>()
    
    private let baseUrl : String
    private var token : String
    
    public init(baseUrl : String, token : String? = "") {
        self.baseUrl = baseUrl
        self.token = token ?? ""
    }
    
    
    
    public func fetchData<T : Codable>(endPoint : String, responseType : T.Type, extraHeaders : [String : String]? = nil) -> AnyPublisher<T, Error>{
        var request = URLRequest(url: URL(string: baseUrl+endPoint)!)
        request.httpMethod = HTTPMethods.get.rawValue
        request.allHTTPHeaderFields = getHeaders(extraHeaders)
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        
        let publisher =
        URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { (data: Data, response : URLResponse) in
                guard let httpResponse = response as? HTTPURLResponse else{
                    throw NetworkError.badServerResponse
                }
                if httpResponse.statusCode == 401 {
                    DispatchQueue.main.async {
                        self.unauthorizedSubject.send(())
                    }
                    throw NetworkError.unauthorized
                }
                guard httpResponse.statusCode == 200 else {
                    throw NetworkError.badServerResponse
                }
                print(data)
                return data
            }
            .decode(type: responseType.self, decoder: decoder)
            .retry(0)
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
        
        return publisher
    }
    
    public func postData<T: Codable, R: Codable>(endPoint: String, requestBody: R? = nil, responseType: T.Type, extraHeaders: [String: String]? = nil) -> AnyPublisher<T, Error> {
        var request = URLRequest(url: URL(string: baseUrl + endPoint)!)
        request.httpMethod = HTTPMethods.post.rawValue
        request.allHTTPHeaderFields = getHeaders(extraHeaders)
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        
        // Prepare request body
        do {
            let encoder = JSONEncoder()
            encoder.keyEncodingStrategy = .convertToSnakeCase
            request.httpBody = try encoder.encode(requestBody)
        } catch {
            return Fail(error: NetworkError.bodyPerseError)
                .eraseToAnyPublisher()
        }
        
        return URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { (data: Data, response: URLResponse) -> Data in
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw NetworkError.badServerResponse
                }
                if (200..<300).contains(httpResponse.statusCode) {
                    return data
                } else if httpResponse.statusCode == 422 {
                    throw NetworkError.validationError(data)
                } else if httpResponse.statusCode == 400 {
                    throw NetworkError.bodyPerseError
                } else {
                    throw NetworkError.unknown
                }
            }
            .mapError { $0 as Error }  // Convert any error to Error type
            .flatMap { data -> AnyPublisher<T, Error> in
                Just(data)
                    .decode(type: responseType, decoder: decoder)
                    .mapError { $0 as Error }  // Convert decoding errors to Error type
                    .eraseToAnyPublisher()
            }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    public func putData<T: Codable, R: Codable>(endPoint: String, requestBody: R? = nil, responseType: T.Type, extraHeaders: [String: String]? = nil) -> AnyPublisher<T, Error> {
        var request = URLRequest(url: URL(string: baseUrl + endPoint)!)
        request.httpMethod = HTTPMethods.put.rawValue
        request.allHTTPHeaderFields = getHeaders(extraHeaders)
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        
        // Prepare request body
        do {
            let encoder = JSONEncoder()
            encoder.keyEncodingStrategy = .convertToSnakeCase
            request.httpBody = try encoder.encode(requestBody)
        } catch {
            return Fail(error: NetworkError.bodyPerseError)
                .eraseToAnyPublisher()
        }
        
        let publisher =
        URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { (data: Data, response: URLResponse) in
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw NetworkError.badServerResponse
                }
                if (200..<300).contains(httpResponse.statusCode) {
                    return data
                } else {
                    if httpResponse.statusCode == 422 {
                        throw NetworkError.validationError(data)
                    } else {
                        throw NetworkError.unknown
                    }
                }
            }
            .decode(type: responseType, decoder: decoder)
            .retry(0)
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
        
        return publisher
    }
    
    
    func uploadMultipartFormData<T: Codable>(endPoint: String, responseType: T.Type, image: UIImage, keyForImage: String) -> AnyPublisher<T, Error> {
        
        guard let url = URL(string: baseUrl + endPoint) else {
            return Fail(error: NetworkError.invalidURL)
                .eraseToAnyPublisher()
        }
        
        var formDataFields = [(String, String)]()
        
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            return Fail(error: NetworkError.bodyPerseError)
                .eraseToAnyPublisher()
        }
        
        
        let boundary = UUID().uuidString
        let contentType = "multipart/form-data; boundary=\(boundary)"
        
        var request = URLRequest(url: url)
        request.httpMethod = HTTPMethods.post.rawValue
        request.allHTTPHeaderFields = getHeaders()
        request.setValue(contentType, forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        
        // Generate a unique filename for the image
        let uniqueFilename = "\(UUID().uuidString).JPEG"
        
        // Append image data
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"\(keyForImage)\"; filename=\"\(uniqueFilename)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/JPEG\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n".data(using: .utf8)!)
        
        
        
        // Close the multipart form data body
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
         
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        
        
        return URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { (data: Data, response: URLResponse) in
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw NetworkError.responseError
                }
                if httpResponse.statusCode == 401 {
                    throw NetworkError.unknown
                }
                return data
            }
            .decode(type: T.self, decoder: decoder)
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    
    
    func compressVideo(inputURL: URL, outputURL: URL, completion: @escaping (URL?) -> Void) {
        let asset = AVAsset(url: inputURL)
        guard let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetMediumQuality) else {
            completion(nil)
            return
        }
        
        exportSession.outputURL = outputURL
        exportSession.outputFileType = .mp4
        exportSession.shouldOptimizeForNetworkUse = true
        
        exportSession.exportAsynchronously {
            switch exportSession.status {
            case .completed:
                completion(outputURL)
            default:
                completion(nil)
            }
        }
    }
    
    func uploadMultipartFormDataWithCompressedVideo<T: Codable>(
        endPoint: String,
        responseType: T.Type,
        images: [UIImage],
        keyForImages: String,
        videoURL: URL,
        keyForVideo: String,
        textFields: [String: String]
    ) -> AnyPublisher<T, Error> {
        
        // Create a temporary URL for the compressed video
        let compressedVideoURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString).appendingPathExtension("mp4")
        
        // Compress the video
        return Future<URL?, Never> { promise in
            self.compressVideo(inputURL: videoURL, outputURL: compressedVideoURL) { compressedURL in
                promise(.success(compressedURL))
            }
        }
        .compactMap { $0 }
        .flatMap { compressedURL -> AnyPublisher<T, Error> in
            guard let url = URL(string: self.baseUrl + endPoint) else {
                return Fail(error: NetworkError.invalidURL).eraseToAnyPublisher()
            }
            
            let boundary = UUID().uuidString
            let contentType = "multipart/form-data; boundary=\(boundary)"
            
            var request = URLRequest(url: url)
            request.httpMethod = HTTPMethods.post.rawValue
            request.allHTTPHeaderFields = self.getHeaders()
            request.setValue(contentType, forHTTPHeaderField: "Content-Type")
            
            var body = Data()
            
            // Append images
            for (index, image) in images.enumerated() {
                guard let imageData = image.jpegData(compressionQuality: 0.5) else {
                    return Fail(error: NetworkError.bodyPerseError).eraseToAnyPublisher()
                }
                
                let uniqueFilename = "\(UUID().uuidString).jpg"
                body.append("--\(boundary)\r\n".data(using: .utf8)!)
                body.append("Content-Disposition: form-data; name=\"\(keyForImages)[\(index)]\"; filename=\"\(uniqueFilename)\"\r\n".data(using: .utf8)!)
                body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
                body.append(imageData)
                body.append("\r\n".data(using: .utf8)!)
            }
            
            // Append compressed video
            if let videoData = try? Data(contentsOf: compressedURL) {
                let uniqueFilename = "\(UUID().uuidString).mp4"
                body.append("--\(boundary)\r\n".data(using: .utf8)!)
                body.append("Content-Disposition: form-data; name=\"\(keyForVideo)\"; filename=\"\(uniqueFilename)\"\r\n".data(using: .utf8)!)
                body.append("Content-Type: video/mp4\r\n\r\n".data(using: .utf8)!)
                body.append(videoData)
                body.append("\r\n".data(using: .utf8)!)
            } else {
                return Fail(error: NetworkError.bodyPerseError).eraseToAnyPublisher()
            }
            
            // Append text fields
            for (key, value) in textFields {
                body.append("--\(boundary)\r\n".data(using: .utf8)!)
                body.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n".data(using: .utf8)!)
                body.append("\(value)\r\n".data(using: .utf8)!)
            }
            
            // Close the multipart form data body
            body.append("--\(boundary)--\r\n".data(using: .utf8)!)
            
            request.httpBody = body
            
            // Debug logging
            print("Request URL: \(url)")
            print("Request Headers: \(request.allHTTPHeaderFields ?? [:])")
            print("Request Body Length: \(body.count) bytes")
            
            return URLSession.shared.dataTaskPublisher(for: request)
                .tryMap { (data: Data, response: URLResponse) in
                    if let httpResponse = response as? HTTPURLResponse {
                        print("Response Status Code: \(httpResponse.statusCode)")
                        if httpResponse.statusCode != 200 {
                            let responseString = String(data: data, encoding: .utf8) ?? "Unknown response"
                            print("Response: \(responseString)")
                            throw NetworkError.responseError
                        }
                    } else {
                        throw NetworkError.responseError
                    }
                    return data
                }
                .decode(type: T.self, decoder: JSONDecoder())
                .receive(on: DispatchQueue.main)
                .eraseToAnyPublisher()
        }
        .eraseToAnyPublisher()
    }
    
    
    private func getHeaders(_ extraHeaders : [String : String]? = nil) -> [String: String] {
        var headers: [String: String] = [:]
        
        if let extraHeader = extraHeaders {
            headers.merge(extraHeader) { _, new in new }
        }
        
        headers["Content-Type"] = "application/json"
        headers["Accept"] = "application/json"
        headers["Authorization"] = token
       
        
        
        return headers
    }
}
