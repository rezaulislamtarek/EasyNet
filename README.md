# EasyNet

`EasyNet` is a simple and efficient networking library for iOS/macOS, built in Swift. It supports making HTTP requests using the most common HTTP methods (GET, POST, PUT, DELETE), integrates with the `Combine` framework for reactive programming, and makes it easy to work with JSON responses, multipart form uploads, and custom headers.

---

## Features

- **GET, POST, PUT, DELETE Requests**: Support for standard HTTP methods.
- **Codable Encoding/Decoding**: Automatically encodes and decodes JSON data using Swift's `Codable`.
- **Multipart File Uploads**: Upload images using `multipart/form-data`.
- **Authorization Header**: Support for adding authorization tokens for secure communication.
- **Combine Integration**: Built-in support for Combine framework to handle asynchronous responses.
- **Custom Headers**: Allows the addition of custom headers to requests.
- **Error Handling**: Handles HTTP errors like unauthorized access, validation errors, and server errors.

---

## Installation

You can integrate `EasyNet` into your iOS or macOS project using Swift Package Manager.

### Swift Package Manager

1. Open your Xcode project.
2. Go to `File` → `Swift Packages` → `Add Package Dependency`.
3. Enter the URL of this repository:  
   `https://github.com/rezaulislamtarek/EasyNet.git`

4. Choose the version and complete the integration.

---

## Usage

### Initializing `EasyNet`

To start using `EasyNet`, initialize it with your base URL and optionally with an authorization token.

```
let easyNet = EasyNet(baseUrl: "https://api.example.com", token: "your-api-token")
```
### Making a GET Request
Fetch data using a GET request. Here’s an example of how to decode the response into a Codable object:


```
easyNet.fetchData(endPoint: "users", responseType: User.self)
    .sink(receiveCompletion: { completion in
        switch completion {
        case .finished:
            print("Request successful")
        case .failure(let error):
            print("Error: \(error)")
        }
    }, receiveValue: { response in
        print("User Data: \(response)")
    })
    
  ```
### Making a POST Request
Send a POST request with a request body. Here's how to send data and receive a response:

```
let user = User(name: "John Doe", email: "johndoe@example.com")
easyNet.postData(endPoint: "users", requestBody: user, responseType: UserResponse.self)
    .sink(receiveCompletion: { completion in
        switch completion {
        case .finished:
            print("Request successful")
        case .failure(let error):
            print("Error: \(error)")
        }
    }, receiveValue: { response in
        print("User Created: \(response)")
    })

```
### Making a PUT Request
Update an existing resource with a PUT request:

```
easyNet.putData(endPoint: "users/1", requestBody: updatedUser, responseType: UserResponse.self)
    .sink(receiveCompletion: { completion in
        switch completion {
        case .finished:
            print("Request successful")
        case .failure(let error):
            print("Error: \(error)")
        }
    }, receiveValue: { response in
        print("User Updated: \(response)")
    })

```
### Making a DELETE Request
Delete a resource with a DELETE request:

```
easyNet.deleteData(endPoint: "users/1", responseType: UserResponse.self)
    .sink(receiveCompletion: { completion in
        switch completion {
        case .finished:
            print("Request successful")
        case .failure(let error):
            print("Error: \(error)")
        }
    }, receiveValue: { response in
        print("User Deleted: \(response)")
    })

```
### Uploading Files (Multipart POST)
To upload an image (multipart form-data):

```
let image = UIImage(named: "profile.jpg")!
easyNet.uploadMultipartFormData(endPoint: "upload", responseType: UploadResponse.self, image: image, keyForImage: "file")
    .sink(receiveCompletion: { completion in
        switch completion {
        case .finished:
            print("Request successful")
        case .failure(let error):
            print("Error: \(error)")
        }
    }, receiveValue: { response in
        print("File Uploaded: \(response)")
    })

 ```

### Error Handling

```
EasyNet handles various types of errors through the EasyNetError enum:

invalidURL: The URL provided is invalid.
badServerResponse: The server response is not valid.
unauthorized: The request returns a 401 Unauthorized error.
validationError: The request returns a 422 Validation error.
bodyParseError: Issue encoding/decoding the request body.
unknown: Any other error not covered by the above.
```

### Handling Errors:

```
easyNet.fetchData(endPoint: "your-endpoint", responseType: YourResponseType.self)
    .sink(receiveCompletion: { completion in
        switch completion {
        case .finished:
            print("Request successful")
        case .failure(let error):
            if let easyNetError = error as? EasyNetError {
                switch easyNetError {
                case .unauthorized:
                    print("Unauthorized request")
                case .validationError:
                    print("Validation error")
                default:
                    print("Error: \(easyNetError)")
                }
            }
        }
    }, receiveValue: { response in
        print("Response: \(response)")
    })
```

 
### Contributing
We welcome contributions to EasyNet! If you find a bug or want to add a feature, feel free to fork the repository and submit a pull request.

#### Steps to Contribute:
```
Fork the repository.
Create a new branch (git checkout -b feature-branch).
Make your changes (git commit -am 'Add new feature').
Push to your branch (git push origin feature-branch).
Open a pull request.
```

### Author
Rezaul Islam
