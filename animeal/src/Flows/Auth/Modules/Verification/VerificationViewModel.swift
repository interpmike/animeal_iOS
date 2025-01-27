import Foundation

final class VerificationViewModel: VerificationViewModelLifeCycle, VerificationViewInteraction, VerificationViewState {
    // MARK: - Private properties
    private lazy var timeFormatter: DateComponentsFormatter = {
         let formatter = DateComponentsFormatter()
         formatter.allowedUnits = [.minute, .second]
         formatter.unitsStyle = .positional
         formatter.zeroFormattingBehavior = []
         return formatter
     }()

    // MARK: - Dependencies
    private let model: VerificationModelProtocol
    private let coordinator: VerificationCoordinatable
    private let completion: (() -> Void)?

    // MARK: - State
    var onHeaderHasBeenPrepared: ((VerificationViewHeader) -> Void)?
    var onCodeHasBeenPrepared: ((VerificationViewCode, Bool) -> Void)?
    var onResendCodeHasBeenPrepared: ((VereficationViewResendCode) -> Void)?

    // MARK: - Initialization
    init(
        model: VerificationModelProtocol,
        coordinator: VerificationCoordinatable,
        completion: (() -> Void)? = nil
    ) {
        self.model = model
        self.coordinator = coordinator
        self.completion = completion
        setup()
    }

    // MARK: - Life cycle
    func setup() {
        model.requestNewCodeTimeLeft = { modelTimeLeft in
            Task { [weak self] in
                guard let self else { return }
                let text = modelTimeLeft.time > 0 ?
                    L10n.Verification.ResendCode.titleTime :
                    L10n.Verification.ResendCode.title
                let time = modelTimeLeft.time > 0 ? self.timeFormatter.string(
                    from: TimeInterval(modelTimeLeft.time)
                ) : nil
                self.onResendCodeHasBeenPrepared?(
                    VereficationViewResendCode(
                        title: text,
                        timeLeft: time
                    )
                )
            }
        }
    }

    func load() {
        let modelDeliveryDestination = model.fetchDestination()
        onHeaderHasBeenPrepared?(.default(modelDeliveryDestination))

        let modelCode = model.fetchCode()
        onCodeHasBeenPrepared?(
            VerificationViewCode(
                state: VerificationViewCodeState.normal,
                items: modelCode.items.map {
                    VerificationViewCodeItem(identifier: $0.identifier, text: $0.text)
                }
            ),
            true
        )
    }

    // MARK: - Interaction
    func handleActionEvent(_ event: VerificationViewActionEvent) {
        switch event {
        case .tapResendCode:
            handleResendNewCode(force: false)
        case .changeCode(let viewCodeItems):
            handleChangeCode(viewCodeItems: viewCodeItems)
        }
    }

    private func handleResendNewCode(force: Bool) {
        coordinator.displayActivityIndicator { [weak self] in
            do {
                try await self?.model.requestNewCode(force: force)
            } catch VerificationModelCodeError.codeRequestTimeLimitExceeded {
                return
            } catch {
                throw error
            }
        }
    }

    private func handleChangeCode(viewCodeItems: [VerificationViewCodeItem]) {
        let modelCode = VerificationModelCode(
            items: viewCodeItems.map {
                VerificationModelCodeItem(identifier: $0.identifier, text: $0.text)
            }
        )
        do {
            try model.validateCode(modelCode)
            coordinator.displayActivityIndicator { [weak self] in
                do {
                    try await self?.model.verifyCode(modelCode)
                    self?.onCodeHasBeenPrepared?(
                        VerificationViewCode(
                            state: VerificationViewCodeState.normal,
                            items: viewCodeItems
                        ),
                        false
                    )
                    self?.completion?()
                    self?.coordinator.moveFromVerification(to: .finish)
                } catch let error as VerificationModelCodeError where error == .codeTriesCountLimitExceeded {
                    let viewAlert = ViewAlert(
                        title: error.localizedDescription,
                        actions: [
                            .cancel(),
                            .resend { [weak self] in
                                self?.handleResendNewCode(force: false)
                            }
                        ]
                    )
                    self?.coordinator.displayAlert(viewAlert)
                } catch {
                    let emptyCode = VerificationModelCode.empty()
                    let items = emptyCode.items.map {
                        VerificationViewCodeItem(identifier: $0.identifier, text: $0.text)
                    }
                    self?.onCodeHasBeenPrepared?(
                        VerificationViewCode(
                            state: VerificationViewCodeState.error,
                            items: items
                        ),
                        true
                    )
                }
            }
        } catch { }
    }
}

private extension VerificationViewHeader {
    static func `default`(
        _ destination: VerificationModelDeliveryDestination? = nil
    ) -> VerificationViewHeader {
        let subtitle: String
        if let destination = destination?.value {
            subtitle = "\(L10n.Verification.Subtitle.filled) \(destination)"
        } else {
            subtitle = L10n.Verification.Subtitle.empty
        }

        return VerificationViewHeader(
            title: L10n.Verification.title,
            subtitle: subtitle
        )
    }
}

private extension ViewAlertAction {
    static func cancel(_ handler: @escaping () -> Void = { }) -> ViewAlertAction {
        ViewAlertAction(
            title: L10n.Verification.Alert.cancel,
            style: .inverted,
            handler: handler
        )
    }

    static func resend(_ handler: @escaping () -> Void = { }) -> ViewAlertAction {
        ViewAlertAction(
            title: L10n.Verification.Alert.resend,
            style: .accent,
            handler: handler
        )
    }
}
