//
//  File.swift
//  
//
//  Created by Rezaul Islam on 5/12/24.
//

import Foundation

public enum EasyNetError : Error{
    case invalidURL
    case badServerResponse
    case responseError
    case unknown
    case unauthorized
    case bodyPerseError
    case decodeError(Error)
    case validationError(Data)
    case badRequest(String?)
}
