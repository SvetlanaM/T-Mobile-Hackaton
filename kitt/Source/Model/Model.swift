//
//  Model.swift
//  kitt
//
//  Created by Ondřej Mařík on 29/11/2016.
//  Copyright © 2016 Ondřej Mařík. All rights reserved.
//

import Foundation
import MojioSDK
import Alamofire
import CoreLocation

class Model {
    
    // Singleton property
    static let instance = Model()
    
    private let authClient: AuthClient
    private var restClient: RestClient {
        return RestClient(clientEnvironment: ClientEnvironment.SharedInstance)
    }
    
    private var authToken: AuthToken?
    
    // MARK: Class private constructor
    private init() {
        
        authClient = AuthClient(clientId: "0b655654-4021-43d3-b556-5da5f8ec4d90", clientSecretKey: "fbb2113a-9260-4c4a-8be3-2e0e7573a6f9", clientRedirectURI: "https://margetova.eu")
        
    }
    
    // MARK: Public functions
    public func login(username: String?, password: String?, success: @escaping () -> Void, failure: @escaping (ModelError) -> Void ) {
    
        guard let username = username, let password = password else {
            failure(.MissingParams)
            return
        }
        
        authClient.login(username, password: password, completion: { token in
            self.authClient.saveAuthToken(token)
            success()
        }, failure: { error in
            failure(.WrongCredentials)
        })
        
    }
    
    public func logout() {
        
        authClient.logout()
        authToken = nil
        
    }
    
    public func userCars(success: ([Vehicle]) -> Void, failure: @escaping (ModelError) -> Void) {
        
        restClient.get().vehicles(nil).run({ (vehicles) in
            print(vehicles)
        }, failure: { error in
            failure(self.parsedError(error: error))
        }
        )
        
    }
    
    public func userInfo(success: (User) -> Void, failure: @escaping (ModelError) -> Void) {
        
        restClient.get().me().run({ (user) in
            print(user)
        }, failure: { error in
            failure(self.parsedError(error: error))
        })
        
    }
    
    // Gas stations
    public func travelPath(start: CLLocation, end: CLLocation, success: ([String : AnyObject]) -> Void, failure: (ModelError) -> Void) {
        
        let parameters = ["action" : "getDirectionsAndPumps",
                          "startPlace" : "\(start.coordinate.latitude),\(start.coordinate.longitude)",
                          "endPlace" : "\(end.coordinate.latitude),\(end.coordinate.longitude)"]
        
        Alamofire.request("https://fleetheroapi.ccs.cz/index.php", method: .post, parameters: parameters, encoding: JSONEncoding.default)
            .validate()
            .responseJSON { (response) in
                print(response)
        }
        
        
    }
    
    public func gasStations(success: ([String : AnyObject]) -> Void, failure: (ModelError) -> Void) {
        
        let parameters = ["action" : "getAllAggPumpsWithPositionNoLevels"]
        
        Alamofire.request("https://fleetheroapi.ccs.cz/index.php", method: .post, parameters: parameters, encoding: JSONEncoding.default)
            .validate()
            .responseJSON { (response) in
                print(response)
        }
        
    }
    
    // Weather
    public func getCurrentWeather(location: CLLocation, success: ([String : AnyObject]) -> Void, failure: (ModelError) -> Void) {
        
        let parameters = ["key":"39e772ad39c34c81afa113737160212",
                          "q":"\(location.coordinate.latitude),\(location.coordinate.longitude)"]
        
        Alamofire.request("https://api.apixu.com/v1/current.json", method: .get, parameters: parameters)
        .validate()
        .responseJSON { (response) in
            print(response)
        }
        
    }
    
    // MARK: Private stuff
    private func parsedError(error: Any?) -> ModelError {
        
        if let message = (error as? [String: Any])?["Message"] as? String {
            return .APIError(message)
        } else if let message = error as? String {
            return .APIError(message)
        } else {
            return .APIError(nil)
        }
    }
    
    
}

enum ModelError: Error {
    case MissingParams
    case APIError(String?)
    case WrongCredentials
    
    func localizedDescription() -> String {
        switch self {
        case .MissingParams:
            return "Missing input values"
        case .APIError(let message):
            return message ?? "General API error"
        case .WrongCredentials:
            return "Incorrect login information"
        }
        
    }
    
}
