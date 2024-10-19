//
//  File.swift
//  
//
//  Created by Rezaul Islam on 30/6/24.
//

import Foundation

enum NetworkError : Error{
    case invalidURL
    case badServerResponse
    case responseError
    case unknown
    case unauthorized
    case bodyPerseError
    case validationError(Data)
}
