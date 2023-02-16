import MapboxMaps

class CustomHttpService: HttpServiceInterface {
    func setMaxRequestsPerHostForMax(_ max: UInt8) {
        print("Calling setMaxRequestsPerHostForMax \(max)")
    }
    
    func cancelRequest(forId id: UInt64, callback: @escaping ResultCallback) {
        print("Calling cancelRequest")
    }
    
    func supportsKeepCompression() -> Bool {
        print("Calling supportsKeepCompression")
        return true
    }
    
    func download(for options: DownloadOptions, callback: @escaping DownloadStatusCallback) -> UInt64 {
        print("Calling download")
        return 0
    }
    
    func setInterceptorForInterceptor(_ interceptor: HttpServiceInterceptorInterface?) {
        print("Calling setInterceptorForInterceptor")
    }

    
    func request(for request: HttpRequest, callback: @escaping HttpResponseCallback) -> UInt64 {
        // Make an API request
        var urlRequest = URLRequest(url: URL(string: request.url)!)
        print("URL request is \(request.url)")
        if let urlComponents = URLComponents(url: URL(string: request.url)!, resolvingAgainstBaseURL: true) {
            print("Host is \(urlComponents.host!)")
        }


        let methodMap: [HttpMethod: String] = [
            .get: "GET",
            .head: "HEAD",
            .post: "POST"
        ]

        urlRequest.httpMethod          = methodMap[request.method]!
        urlRequest.httpBody            = request.body
        urlRequest.allHTTPHeaderFields = request.headers

        let task = URLSession.shared.dataTask(with: urlRequest) { (data, response, error) in

            let result: Result<HttpResponseData, HttpRequestError>

            if let error = error {
                // Map NSURLError to HttpRequestErrorType
                let requestError = HttpRequestError(type: .otherError, message: error.localizedDescription)
                result = .failure(requestError)
            } else if let response = response as? HTTPURLResponse,
                    let data = data {

                // Keys are expected to be lowercase
                var headers: [String: String] = [:]
                for (key, value) in response.allHeaderFields {
                    guard let key = key as? String,
                        let value = value as? String else {
                        continue
                    }

                    headers[key.lowercased()] = value
                }

                let responseData = HttpResponseData(headers: headers, code: Int64(response.statusCode), data: data)
                result = .success(responseData)
            } else {
                // Error
                let requestError = HttpRequestError(type: .otherError, message: "Invalid response")
                result = .failure(requestError)
            }

            let response = HttpResponse(request: request, result: result)
            callback(response)
        }

        task.resume()

        // Handle used to cancel requests
        return UInt64(task.taskIdentifier)
    }
}
