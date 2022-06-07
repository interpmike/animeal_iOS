//
//  LoginViewModel.swift
//  animeal
//
//  Created by Диана Тынкован on 1.06.22.
//

import Foundation

final class LoginViewModel: LoginViewModelLifeCycle, LoginViewInteraction, LoginViewState {
    // MARK: - Private properties
    private var viewActions: [LoginViewAction]

    // MARK: - Dependencies
    private let model: LoginCombinedModel
    private let actionsMapper: LoginViewActionMappable
    private let onboardingMapper: LoginViewOnboardingStepsMappable

    // MARK: - State
    var onOnboardingStepsHaveBeenPrepared: (([LoginViewOnboardingStep]) -> Void)?
    var onActionsHaveBeenPrepaped: (([LoginViewAction]) -> Void)?

    // MARK: - Initialization
    init(
        model: LoginCombinedModel,
        actionsMapper: LoginViewActionMappable,
        onboardingMapper: LoginViewOnboardingStepsMappable
    ) {
        self.model = model
        self.actionsMapper = actionsMapper
        self.onboardingMapper = onboardingMapper
        self.viewActions = []
    }

    // MARK: - Life cycle
    func setup() { }

    func load() {
        let modelOnboardingSteps = model.fetchOnboardingSteps()
        let modelActions = model.fetchActions()

        let viewOnboardingsStep = onboardingMapper.map(modelOnboardingSteps)
        let viewActions = actionsMapper.map(modelActions)

        onOnboardingStepsHaveBeenPrepared?(viewOnboardingsStep)
        onActionsHaveBeenPrepaped?(viewActions)
    }

    // MARK: - Interaction
    func handleActionEvent(_ event: LoginViewActionEvent) {
        switch event {
        case .tapInside:
            break
        }
    }
}
