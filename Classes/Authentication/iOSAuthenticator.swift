//
//  AuthenticationErrors.swift
//  iOSAuthentication
//
//  Copyright (c) 2018 Luigi Aiello
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

import UIKit
import LocalAuthentication

public enum iOSBiometryType {
    case touchID
    case faceID
    case notAvailable
}

/// Success block
public typealias AuthenticationSuccess = (() -> ())

/// Failure block
public typealias AuthenticationFailure = ((AuthenticationError) -> ())

/// Fallback
public typealias Fallback = () -> Void

public class iOSAuthenticator: NSObject {
    
    //MARK:- Singleton
    public static let shared = iOSAuthenticator()
    
    //MARK:- Variables
    private var authenticationContext: LAContext?
    
    /**
     Returns a value that indicate if device is unlockable by: Passcode, Touch ID or Face ID
     
     - returns: Boolean value that indicate if device is unlockable by: Passcode, Touch ID or Face ID
     */
    public class func canAuthenticate() -> Bool {
        
        var isBiometricAuthenticationAvailable = false
        var authError: NSError? = nil
        
        if LAContext().canEvaluatePolicy(.deviceOwnerAuthentication, error: &authError) {
            isBiometricAuthenticationAvailable = (authError == nil)
        }
        return isBiometricAuthenticationAvailable
    }
    
    /**
     Returns a value that indicate if device is unlockable by: Touch ID or Face ID
     
     - returns: Boolean value that indicate if device is unlockable by: Touch ID or Face ID
     */
    public class func canAuthenticateWithBiometric() -> Bool {
        
        var isBiometricAuthenticationAvailable = false
        var authError: NSError? = nil
        
        if LAContext().canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &authError) {
            isBiometricAuthenticationAvailable = (authError == nil)
        }
        return isBiometricAuthenticationAvailable
    }
    
    /**
     Returns a value that indicate if Face ID is available
     
     - returns: Boolean value that indicate if Face ID is available
     */
    public class func faceIDAvailable() -> Bool {
        if #available(iOS 11.0, *) {
            let context = LAContext()
            return (context.canEvaluatePolicy(LAPolicy.deviceOwnerAuthentication, error: nil) && context.biometryType == .faceID)
        }
        return false
    }
    
    /**
     Returns a value that specify if the biometric authenticator is: Available, Touch ID or Face ID
     
     - returns: A custom enum (iOSBiometryType) that specify if the biometric authenticator is: Available, Touch ID or Face ID
     */
    public class func biometricType() -> iOSBiometryType {
        
        var type: iOSBiometryType = .notAvailable
        
        if LAContext().canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil) {
            if #available(iOS 11.0, *) {
                switch LAContext().biometryType {
                case .touchID:
                    type = .touchID
                case .faceID:
                    type = .faceID
                case .none:
                    type = .notAvailable
                }
            } else {
                return .touchID
            }
        }
        
        return type
    }
    
    /**
     Invalidate authetication
    */
    public class func invalidate() {
        guard let authContext = iOSAuthenticator.shared.authenticationContext else {
            return
        }
        authContext.invalidate()
    }
    
    /**
     Check if you can authenticate with a biometric method and in the case of an affirmative answer perform authentication.
     
     - Parameter authPolicy:        An enum that specify if use passcode or custom fallback.
     - Parameter reason:            The string that rappresent the reason to use biometric authorization.
     - Parameter fallbackTitle:     If use custom fallback, you can personalize the title of the button.
     - Parameter cancelTitle:       The string that rappresent the cancel title.
     - Parameter success:           Callback if authentication is successful.
     - Parameter failure:           Callback if authentication is not successful.
     */
    public class func authenticateWithPasscode(reason: String, cancelTitle: String? = "", success successBlock:@escaping AuthenticationSuccess, failure failureBlock:@escaping AuthenticationFailure) {
        
        let context = LAContext()
        iOSAuthenticator.shared.authenticationContext = context

        //Cancel button title
        if #available(iOS 10.0, *) {
            context.localizedCancelTitle = cancelTitle
        }
        
        //Authenticate
        iOSAuthenticator.shared.evaluate(policy: .deviceOwnerAuthentication, with: context, reason: reason, success: successBlock, failure: failureBlock)
    }
    
    /**
     Check if you can authenticate with a biometric method and in the case of an affirmative answer perform authentication.
     
     - Parameter authPolicy:        An enum that specify if use passcode or custom fallback.
     - Parameter reason:            The string that rappresent the reason to use biometric authorization.
     - Parameter fallbackTitle:     If use custom fallback, you can personalize the title of the button.
     - Parameter cancelTitle:       The string that rappresent the cancel title.
     - Parameter fallback:          Custom action if you want personalize the fallback.
     - Parameter success:           Callback if authentication is successful.
     - Parameter failure:           Callback if authentication is not successful.
     */
    public class func authenticateWithBiometrics(reason: String, fallbackTitle: String? = "", cancelTitle: String? = "", fallback: Fallback?, success successBlock:@escaping AuthenticationSuccess, failure failureBlock:@escaping AuthenticationFailure) {
        
        let context = LAContext()
        iOSAuthenticator.shared.authenticationContext = context
        
        context.localizedFallbackTitle = fallbackTitle

        //Cancel button title
        if #available(iOS 10.0, *) {
            context.localizedCancelTitle = cancelTitle
        }
        
        //Authenticate
        iOSAuthenticator.shared.evaluate(policy: .deviceOwnerAuthenticationWithBiometrics, with: context, reason: reason, fallback: fallback, success: successBlock, failure: failureBlock)
    }
    
    
    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    //TO DO - Improve
    public class func preventBackgroundSnapshot() {
        iOSAuthenticator.shared.registerNotification()
    }
    private func registerNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(applicationDidEnterBackground(_:)), name: NSNotification.Name.UIApplicationDidEnterBackground, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(applicationDidBecomeActive(_:)), name: NSNotification.Name.UIApplicationDidBecomeActive, object: nil)
    }
    
    @objc private func applicationDidEnterBackground(_ notification: NSNotification) {
        guard let window = UIApplication.shared.windows.first else {
            return
        }
        window.isHidden = true
    }
    @objc private func applicationDidBecomeActive(_ notification: NSNotification) {
        guard let window = UIApplication.shared.windows.first else {
            return
        }
        window.isHidden = false
    }
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
}

//MARK:- Private
extension iOSAuthenticator {
    /// evaluate policy
    private func evaluate(policy: LAPolicy, with context: LAContext, reason: String, fallback: Fallback? = nil, success successBlock:@escaping AuthenticationSuccess, failure failureBlock:@escaping AuthenticationFailure) {
        
        context.evaluatePolicy(policy, localizedReason: reason) { (success, err) in
            DispatchQueue.main.async {
                if success { successBlock() }
                else {
                    let errorType = AuthenticationError(error: err as! LAError, fallback: fallback)
                    
                    failureBlock(errorType)
                }
            }
        }
    }
}