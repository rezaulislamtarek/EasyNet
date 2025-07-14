//
//  EasyNet.swift
//  Created by Rezaul Islam on 4/12/24.
//

import Foundation
import AVFoundation
import UIKit
import Combine


public class EasyNet : EasyNetProtocol {
    // Create a PassthroughSubject to broadcast status updates
    public var unauthorizedSubject = PassthroughSubject<Void, Never>()
    
    private let baseUrl : String
    private var token : String
    
    public init(baseUrl : String, token : String? = "") {
        self.baseUrl = baseUrl
        self.token = token ?? ""
    }
    
    public func setToken(_ token: String) {
        self.token = token
    }
    

    public func fetchData<T : Codable>(endPoint : String, responseType : T.Type, extraHeaders : [String : String]? = nil) -> AnyPublisher<T, Error>{
        guard var request = createRequest(withEndPoint: endPoint, httpMethod: .get) else {
            return Fail(error: EasyNetError.invalidURL).eraseToAnyPublisher()
        }
        return handelRequest(request: &request, extraHeaders: extraHeaders, responseType: responseType)
    }
    
    public func postData<T: Codable, R: Codable>(endPoint: String, requestBody: R? = nil, responseType: T.Type, extraHeaders: [String: String]? = nil) -> AnyPublisher<T, Error> {
        
        guard var request = createRequest(withEndPoint: endPoint, httpMethod: .post) else {
            return Fail(error: EasyNetError.invalidURL).eraseToAnyPublisher()
        }
        
        // Prepare request body
        do {
            let encoder = JSONEncoder()
            encoder.keyEncodingStrategy = .convertToSnakeCase
            request.httpBody = try encoder.encode(requestBody)
        } catch {
            return Fail(error: EasyNetError.bodyPerseError)
                .eraseToAnyPublisher()
        }
        
        return handelRequest(request: &request, extraHeaders: extraHeaders, responseType: responseType)
        
    }
    
    public func putData<T: Codable, R: Codable>(endPoint: String, requestBody: R? = nil, responseType: T.Type, extraHeaders: [String: String]? = nil) -> AnyPublisher<T, Error> {
        
        guard var request = createRequest(withEndPoint: endPoint, httpMethod: .put) else {
            return Fail(error: EasyNetError.invalidURL).eraseToAnyPublisher()
        }
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        
        // Prepare request body
        do {
            let encoder = JSONEncoder()
            encoder.keyEncodingStrategy = .convertToSnakeCase
            request.httpBody = try encoder.encode(requestBody)
        } catch {
            return Fail(error: EasyNetError.bodyPerseError)
                .eraseToAnyPublisher()
        }
        return handelRequest(request: &request, extraHeaders: extraHeaders, responseType: responseType)
    }
    
    public func deleteData<T: Codable>(endPoint: String, responseType: T.Type, extraHeaders: [String: String]? = nil) -> AnyPublisher<T, Error> {
        guard var request = createRequest(withEndPoint: endPoint, httpMethod: .delete) else {
            return Fail(error: EasyNetError.invalidURL).eraseToAnyPublisher()
        }
        
        return handelRequest(request: &request, extraHeaders: extraHeaders, responseType: responseType)
    }
    
    public func uploadMultipartFormData<T: Codable>(endPoint: String, responseType: T.Type, image: UIImage, keyForImage: String) -> AnyPublisher<T, Error> {
        
        guard var request = createRequest(withEndPoint: endPoint, httpMethod: .post) else {
            return Fail(error: EasyNetError.invalidURL).eraseToAnyPublisher()
        }
        
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            return Fail(error: EasyNetError.bodyPerseError)
                .eraseToAnyPublisher()
        }
        
        let boundary = UUID().uuidString
        let contentType = "multipart/form-data; boundary=\(boundary)"
        
        request.setValue(contentType, forHTTPHeaderField: "Content-Type")
        request.httpBody = prepareMultipartBody(boundary: boundary, imageData: imageData, keyForImage: keyForImage)
        
        return handelRequest(request: &request, responseType: responseType)
    }
    
    
    private func prepareMultipartBody(boundary : String, imageData : Data, keyForImage : String) -> Data{
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
        return body
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
    
    private func handelRequest<T: Codable>( request : inout URLRequest, extraHeaders : [String : String]? = nil, responseType : T.Type) -> AnyPublisher<T, Error>{
        request.allHTTPHeaderFields = getHeaders(extraHeaders)
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        
        let publisher =
        URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { [weak self] (data: Data, response: URLResponse) in
                guard let self = self else { throw EasyNetError.badServerResponse }
                guard let httpResponse = response as? HTTPURLResponse else{
                    throw EasyNetError.badServerResponse
                }
                if httpResponse.statusCode == 401 {
                    DispatchQueue.main.async {
                        self.unauthorizedSubject.send(())
                    }
                    throw EasyNetError.unauthorized
                }
                else if (200..<300).contains(httpResponse.statusCode) {
                    return data
                } else if httpResponse.statusCode == 422 {
                    throw EasyNetError.validationError(data)
                } else if httpResponse.statusCode == 400 {
                    // 👇 LOG the raw body data here
                           if let bodyString = String(data: data, encoding: .utf8) {
                               print("🔴 Body parse error. Server response body:\n\(bodyString)")
                           } else {
                               print("🔴 Body parse error. Could not decode server response body.")
                           }
                    throw EasyNetError.bodyPerseError
                } else {
                    throw EasyNetError.unknown
                }
                
            }
            .decode(type: responseType.self, decoder: decoder)
            .retry(0)
            .receive(on: DispatchQueue.main)
            .subscribe(on: DispatchQueue.global())
            .eraseToAnyPublisher()
        return publisher
    }
    
    
    private func createRequest(withEndPoint endPoint: String, httpMethod: EasyNetMethod) -> URLRequest? {
        guard let url = URL(string: baseUrl + endPoint) else {
            return nil
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = httpMethod.rawValue
        return request
    }
}
