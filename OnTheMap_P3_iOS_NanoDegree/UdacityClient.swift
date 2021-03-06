//
//  UdacityClient.swift
//  OnTheMap_P3_iOS_NanoDegree
//
//  Created by Calum Harris on 06/05/2016.
//  Copyright © 2016 Calum Harris. All rights reserved.
//

import Foundation

struct UdacityClient {

  // Define completion handler typalias and Result enum for use throughout Authentication.
  
  typealias AuthenticationCompletionHandler = (Result) -> Void
  typealias CompletionHandlerForLogin = (LoginResult) -> Void


  enum Result {
    
    case Success(AnyObject?)
    case Failure(ErrorType)
  }
  
  
  enum LoginResult {
  
    case Success(UserModel)
    case Failure(ErrorType)
  }

  
   func taskForPost(action: String, jsonBody: String, postCompletionHandler: AuthenticationCompletionHandler) -> NSURLSessionDataTask {
    
    let session = NSURLSession.sharedSession()
    
    // Build URL and configure the request
    let request = NSMutableURLRequest(URL: URLFromAction(action))
    request.HTTPMethod = "POST"
    request.addValue(UdacityConstants.HTTPHeaderKeys.AddValueJson, forHTTPHeaderField: UdacityConstants.HTTPHeaderValues.Accept)
    request.addValue(UdacityConstants.HTTPHeaderKeys.AddValueJson, forHTTPHeaderField: UdacityConstants.HTTPHeaderValues.ContentType)
    request.HTTPBody = jsonBody.dataUsingEncoding(NSUTF8StringEncoding)
   
    
    // make request
    
    let task = session.dataTaskWithRequest(request) {(data, response, error) in
      
      func sendError(error: String) {
        let userInfo = [NSLocalizedDescriptionKey : error]
        postCompletionHandler(.Failure(NSError(domain: "taskForPOST", code: 1, userInfo: userInfo)))
      }

      
      // GUARD: Was there an error
      guard (error == nil) else {
        sendError("No Internet Connection")
        print(error)
        
        return
      }
      
      // GUARD: Did we get a successful 2XX response
      guard let statusCode = (response as? NSHTTPURLResponse)?.statusCode where statusCode >= 200 && statusCode <= 299 else {
        if (response as! NSHTTPURLResponse).statusCode == 403 {
          sendError("Invalid Login Details")
          return
        } else {
          sendError("Your request returned a status code other than 2xx" + "\(response)")
          return
        }
      }
      
      // GUARD: Was there any data returned?
      guard let data = data else {
        sendError("No data was returned by your request")
        return
      }
      
      // Parse the data and use the data (Happens in the completion handler)
      self.convertDataWithCompletionHander(data, completionHandler: postCompletionHandler)
    
    
    }
    task.resume()
    return task
  }

  private func convertDataWithCompletionHander(data: NSData, completionHandler: AuthenticationCompletionHandler) {
    
    var parsedResult: AnyObject!
    do {
      
      let newData = data.subdataWithRange(NSMakeRange(5, data.length - 5))
      
      parsedResult = try NSJSONSerialization.JSONObjectWithData(newData, options: .AllowFragments)
    } catch {
      
      let userInfo = [NSLocalizedDescriptionKey : "Could not parse the data as JSON: '\(data)'"]
      completionHandler(.Failure(NSError(domain: "convertDataWithCompletionHander", code: 1, userInfo: userInfo)))
    }
    
    completionHandler(.Success(parsedResult))
  
  }
  
  
    func getUserKeyAndReturnUserModel(jsonData: Result, getUserKeyCompletionHander: CompletionHandlerForLogin) {
    
    if case let .Success(jsonData) = jsonData {
    
      guard let accountDetail = jsonData?[UdacityConstants.JSONResponseKeys.AccountDetail] as? [String : AnyObject] else {
        print("error")
        let userInfo = [NSLocalizedDescriptionKey : "accountDetail not found"]
        getUserKeyCompletionHander(.Failure(NSError(domain: "getUserKey", code: 1, userInfo: userInfo)))
        return
      }

      guard let userKey = accountDetail[UdacityConstants.JSONResponseKeys.UserKey] as? String else {
        print("error")
        let userInfo = [NSLocalizedDescriptionKey : "UserKey not found"]
        getUserKeyCompletionHander(.Failure(NSError(domain: "getUserKey", code: 1, userInfo: userInfo)))
        return
      }
      
      var userModel = UserModel()
      userModel.userKey = userKey
      getUserKeyCompletionHander(.Success(userModel))
      
    }
  }
  

  
   func taskForGet(action: String, additionalParameter: String, getCompletionHandler: AuthenticationCompletionHandler) -> NSURLSessionDataTask {
    
    let session = NSURLSession.sharedSession()
    
    // Build URL and configure the request
    let request = NSMutableURLRequest(URL: URLFromAction(action, additionalParameter: additionalParameter))
    
    // make request
    
    let task = session.dataTaskWithRequest(request) {(data, response, error) in
      
      func sendError(error: String) {
        print(error)
        let userInfo = [NSLocalizedDescriptionKey : error]
        getCompletionHandler(.Failure(NSError(domain: "taskForGET", code: 1, userInfo: userInfo)))
      }
      
      // GUARD: Was there an error
      guard (error == nil) else {
        sendError("There was an error with your request \(error)")
        return
      }
      
      // GUARD: Did we get a successful 2XX response
      guard let statusCode = (response as? NSHTTPURLResponse)?.statusCode where statusCode >= 200 && statusCode <= 299 else {
        sendError("Your request returned a status code other than 2xx \(response)")
        return
      }
      
      // GUARD: Was there any data returned?
      guard let data = data else {
        sendError("No data was returned by your request")
        return
      }
      
      // Parse the data and use the data (Happens in the completion handler)
      self.convertDataWithCompletionHander(data, completionHandler: getCompletionHandler)
      
    }
    task.resume()
    return task
  }

  
   func returnUserModelFullyPopulated(userModelWithKey: UserModel, jsonData: Result, returnUserModelCompletionHandler: CompletionHandlerForLogin) {
    
    switch jsonData {
    case let .Success(json):
      
      guard let userDetails = json?[UdacityConstants.JSONResponseKeys.UserDetails] as? [String : AnyObject] else {
        print("error")
        let userInfo = [NSLocalizedDescriptionKey : "userDetail not found"]
        returnUserModelCompletionHandler(.Failure(NSError(domain: "getUserKey", code: 1, userInfo: userInfo)))
        return
      }
      
      
      guard let firstName = userDetails[UdacityConstants.JSONResponseKeys.FirstName] as? String, lastName = userDetails[UdacityConstants.JSONResponseKeys.LastName] as? String else {
        print("error")
        let userInfo = [NSLocalizedDescriptionKey : "first name and/or last name not found"]
        returnUserModelCompletionHandler(.Failure(NSError(domain: "getUserKey", code: 1, userInfo: userInfo)))
        return
      }

      var populateUserModel = userModelWithKey
      populateUserModel.firstName = firstName
      populateUserModel.lastName = lastName
      
      returnUserModelCompletionHandler(.Success(populateUserModel))
      
      
    case let .Failure(error):
      returnUserModelCompletionHandler(.Failure(error))
    }
    
    
  }
  
  func taskForDelete(action: String, taskForDeleteCompletionHandler: AuthenticationCompletionHandler) {
    
    let session = NSURLSession.sharedSession()
    let request = NSMutableURLRequest(URL: URLFromAction(action))
    request.HTTPMethod = "DELETE"
    
    var xsrfCookie: NSHTTPCookie? = nil
    let sharedCookieStorage = NSHTTPCookieStorage.sharedHTTPCookieStorage()
    for cookie in sharedCookieStorage.cookies! {
      if cookie.name == "XSRF-TOKEN" { xsrfCookie = cookie }
    }
    if let xsrfCookie = xsrfCookie {
      request.setValue(xsrfCookie.value, forHTTPHeaderField: "X-XSRF-TOKEN")
    }
    
    let task = session.dataTaskWithRequest(request) { data, response, error in
      
      func sendError(error: String) {
        print(error)
        let userInfo = [NSLocalizedDescriptionKey : error]
        taskForDeleteCompletionHandler(.Failure(NSError(domain: "taskForGET", code: 1, userInfo: userInfo)))
      }
      
      // GUARD: Was there an error
      guard (error == nil) else {
        sendError("There was an error with your request \(error)")
        return
      }
      
      // GUARD: Did we get a successful 2XX response
      guard let statusCode = (response as? NSHTTPURLResponse)?.statusCode where statusCode >= 200 && statusCode <= 299 else {
        sendError("Your request returned a status code other than 2xx \(response)")
        return
      }
      
      // GUARD: Was there any data returned?
      guard let data = data else {
        sendError("No data was returned by your request")
        return
      }
      
      // Parse the data and use the data (Happens in the completion handler)
      self.convertDataWithCompletionHander(data, completionHandler: taskForDeleteCompletionHandler)
    }
    task.resume()
  }
  
  private func URLFromAction(action: String, additionalParameter: String? = nil) -> NSURL {
    
    
    let components = NSURLComponents()
    components.scheme = UdacityConstants.APIScheme
    components.host = UdacityConstants.APIHost
    components.path = UdacityConstants.APIPath + action + (additionalParameter ?? "")
  
    print(components.URL!)
    
    return components.URL!
    
  }

  
  
}

  