// System
import Foundation
import Combine

// SDK
import Services

final class VerificationModel: VerificationModelProtocol {
    // MARK: - Constants
    enum Constants {
        static let timeInterval = 1
        static let timerTimeout = 30
    }

    // MARK: - Private properties
    private var code: VerificationModelCode

    @Published
    private var isResendActive = false
    private let timeLeft: CurrentValueSubject<Int, Never>
    private let timerInterval: Int
    private let timerTimeout: Int
    private var timer: Cancellable?

    private var cancellables: Set<AnyCancellable>

    // MARK: - Dependencies
    private let attribute: VerificationModelAttribute
    private let deliveryDestination: VerificationModelDeliveryDestination
    private let worker: VerificationModelWorker

    // MARK: - Responses
    var requestNewCodeTimeLeft: ((VerificationModelTimeLeft) -> Void)?

    // MARK: - Initialization
    init(
        worker: VerificationModelWorker,
        attribute: VerificationModelAttribute,
        deliveryDestination: VerificationModelDeliveryDestination,
        code: VerificationModelCode = .empty(),
        timerInterval: Int = Constants.timeInterval,
        timerTimeout: Int = Constants.timerTimeout
    ) {
        self.worker = worker
        self.attribute = attribute
        self.deliveryDestination = deliveryDestination
        self.timeLeft = CurrentValueSubject<Int, Never>(timerTimeout)
        self.timerInterval = timerInterval
        self.timerTimeout = timerTimeout
        self.cancellables = []
        self.code = code
        setup()
        schedule()
    }

    // MARK: - Deinit
    deinit {
        cancellables.forEach { $0.cancel() }
    }

    // MARK: - Requests
    func fetchDestination() -> VerificationModelDeliveryDestination { deliveryDestination }

    func fetchCode() -> VerificationModelCode { code }

    func requestNewCode() async throws {
        guard isResendActive else { throw VerificationModelCodeError.codeRequestTimeLimitExceeded }
        schedule()
        try await worker.resendCode(forAttribute: attribute)
    }

    func validateCode(_ code: VerificationModelCode) throws {
       try code.validate()
    }

    func verifyCode(_ code: VerificationModelCode) async throws {
        let nextStep = try await worker.confirmCode(code, forAttribute: attribute)
        switch nextStep {
        case .confirmSignInWithSMSMFACode,
                .confirmSignInWithCustomChallenge,
                .confirmSignInWithNewPassword,
                .resetPassword,
                .confirmSignUp:
            throw VerificationModelCodeError.codeUnsupportedNextStep
        case .done: return
        }
    }
}

private extension VerificationModel {
    func schedule() {
        timeLeft.send(timerTimeout)
        timer?.cancel()
        timer = Timer
            .publish(every: TimeInterval(timerInterval), on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard
                    let self = self,
                    self.timeLeft.value > .zero
                else {
                    self?.timer?.cancel()
                    return
                }
                self.timeLeft.value -= self.timerInterval
            }
    }

    func setup() {
        timeLeft
            .map { $0 == .zero }
            .assign(to: &$isResendActive)
        timeLeft
            .sink { [weak self] time in
                self?.requestNewCodeTimeLeft?(
                    VerificationModelTimeLeft(time: time)
                )
            }
            .store(in: &cancellables)
    }
}
