//
//  File.swift
//  
//
//  Created by Rezaul Islam on 5/1/25.
//

import Combine
import UIKit


public protocol EasyNetProtocol {
    var unauthorizedSubject: PassthroughSubject<Void, Never> { get }
    
    func setToken(_ token: String)
    
    func fetchData<T: Codable>(endPoint: String, responseType: T.Type, extraHeaders: [String: String]?) -> AnyPublisher<T, Error>
    
    func postData<T: Codable, R: Codable>(endPoint: String, requestBody: R?, responseType: T.Type, extraHeaders: [String: String]?) -> AnyPublisher<T, Error>
    
    func putData<T: Codable, R: Codable>(endPoint: String, requestBody: R?, responseType: T.Type, extraHeaders: [String: String]?) -> AnyPublisher<T, Error>
    
    func deleteData<T: Codable>(endPoint: String, responseType: T.Type, extraHeaders: [String: String]?) -> AnyPublisher<T, Error>
    
    func uploadMultipartFormData<T: Codable>(endPoint: String, responseType: T.Type, image: UIImage, keyForImage: String) -> AnyPublisher<T, Error>
}
