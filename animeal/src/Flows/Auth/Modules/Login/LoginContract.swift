import UIKit

// MARK: - View
@MainActor
protocol LoginViewable: AnyObject {
    func applyOnboarding(_ onboardingSteps: [LoginViewOnboardingStep])
    func applyActions(_ actions: [LoginViewAction])
}

// MARK: - ViewModel
typealias LoginViewModelProtocol = LoginViewModelLifeCycle
    & LoginViewInteraction
    & LoginViewState

@MainActor
protocol LoginViewModelLifeCycle: AnyObject {
    func setup()
    func load()
}

@MainActor
protocol LoginViewInteraction: AnyObject {
    func handleActionEvent(_ event: LoginViewActionEvent)
}

@MainActor
protocol LoginViewState: AnyObject {
    var onOnboardingStepsHaveBeenPrepared: (([LoginViewOnboardingStep]) -> Void)? { get set }
    var onActionsHaveBeenPrepaped: (([LoginViewAction]) -> Void)? { get set }
}

// MARK: - Model
// sourcery: AutoMockable
protocol LoginModelProtocol: AnyObject {
    func fetchOnboardingSteps() -> [LoginModelOnboardingStep]
    func fetchActions() -> [LoginModelAction]
    func proceedAuthentication(_ type: LoginActionType) async throws -> LoginModelStatus
}

// MARK: - Coordinator
// sourcery: AutoMockable
@MainActor
protocol LoginCoordinatable: Coordinatable {
    func moveFromLogin(to route: LoginRoute)
}
