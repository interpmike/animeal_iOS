// System
import UIKit

// SDK
import Services

enum ProfileRoute {
    typealias ConfirmCompletion = () -> Void
    
    case done
    case cancel
    case confirm(UserProfileCodeDeliveryDetails, UserProfileAttribute, Bool, ConfirmCompletion?)
    case picker(@MainActor () -> UIViewController?)
    case dismiss
}
