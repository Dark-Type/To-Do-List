//
//  TodoAPIServiceTests.swift
//  To-Do-List
//
//  Created by dark type on 12.05.2025.
//


import Foundation
import Testing
@testable import To_Do_List

struct TodoAPIServiceTests {
    // MARK: - API Request Tests
    
    @Test("API request construction with boundary values")
    func testAPIRequestConstruction() async throws {
        URLProtocolMock.testURLs = [:]
        URLProtocolMock.response = HTTPURLResponse(url: URL(string: "https://test-api.com/todo")!,
                                                   statusCode: 200,
                                                   httpVersion: nil,
                                                   headerFields: nil)!
        
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [URLProtocolMock.self]
        let mockSession = URLSession(configuration: config)
        
        let sut = TodoAPIService(baseURLString: "https://test-api.com/todo", session: mockSession)
        
        let title = "Test Todo"
        var todo = Todo(id: 1, title: title, priority: .high)
        
        let testCases = [
            ("Test", true),
            ("Tes", false),
            (String(repeating: "A", count: 100), true),
        ]
        
        for (testTitle, shouldPass) in testCases {
            todo.title = testTitle
            URLProtocolMock.error = shouldPass ? nil : NSError(domain: "TestError", code: 400, userInfo: nil)
            
            do {
                _ = try await sut.updateTodo(todo)
                #expect(shouldPass, "Expected to fail for title: \(testTitle), but it succeeded")
                
                if shouldPass {
                    #expect(URLProtocolMock.lastURL?.absoluteString.contains("https://test-api.com/todo/1") ?? false)
                }
            } catch {
                #expect(!shouldPass, "Expected success for title: \(testTitle), but got error: \(error)")
            }
        }
    }
}

// MARK: - URLProtocol Mock

class URLProtocolMock: URLProtocol {
    static var testURLs = [URL?: Data]()
    
    static var response: URLResponse?
    
    static var error: Error?
    
    static var lastURL: URL?
    static var lastRequest: URLRequest?
    
    override class func canInit(with request: URLRequest) -> Bool {
        return true
    }
    
    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }
    
    override func startLoading() {
        URLProtocolMock.lastRequest = request
        URLProtocolMock.lastURL = request.url
        
        if let error = URLProtocolMock.error {
            client?.urlProtocol(self, didFailWithError: error)
            return
        }
        
        if let response = URLProtocolMock.response {
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        }
        
        let data = URLProtocolMock.testURLs[request.url] ?? Data()
        client?.urlProtocol(self, didLoad: data)
        client?.urlProtocolDidFinishLoading(self)
    }
    
    override func stopLoading() {}
}
