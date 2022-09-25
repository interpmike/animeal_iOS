// System
import Foundation

// SDK
import Common

final class CustomAuthViewModel: CustomAuthViewModelProtocol {
    // MARK: - Private properties
    private var viewItems: [CustomAuthViewItem]
    private var viewActions: [CustomAuthViewAction]

    // MARK: - Dependencies
    private let model: CustomAuthModelProtocol
    private let coordinator: CustomAuthCoordinatable
    private let mapper: CustomAuthViewItemMappable

    // MARK: - State
    var onHeaderHasBeenPrepared: ((CustomAuthViewHeader) -> Void)?
    var onItemsHaveBeenPrepared: (([CustomAuthViewItem]) -> Void)?
    var onActionsHaveBeenPrepared: (([CustomAuthViewAction]) -> Void)?

    // MARK: - Initialization
    init(
        model: CustomAuthModelProtocol,
        coordinator: CustomAuthCoordinatable,
        mapper: CustomAuthViewItemMappable
    ) {
        self.model = model
        self.coordinator = coordinator
        self.mapper = mapper
        self.viewItems = []
        self.viewActions = [.next()]
    }

    // MARK: - Life cycle
    func setup() { }

    func load() {
        let viewHeader = CustomAuthViewHeader(
            title: L10n.Phone.title
        )
        onHeaderHasBeenPrepared?(viewHeader)

        updateViewItems()
        updateViewActions()
    }

    // MARK: - Interaction
    @discardableResult
    func handleTextEvent(_ event: CustomAuthViewTextEvent) -> CustomAuthViewText {
        switch event {
        case let .beginEditing(identifier, text):
            guard let formatter = viewItems.first(where: { $0.identifier == identifier })?.formatter
            else {
                return CustomAuthViewText(
                    caretOffset: text?.count ?? .zero,
                    formattedText: text
                )
            }
            let offset = formatter.getCaretOffset(for: text ?? "")
            return CustomAuthViewText(caretOffset: offset, formattedText: text)
        case let .didChange(identifier, text):
            guard let formatter = viewItems.first(where: { $0.identifier == identifier })?.formatter
            else {
                defer {
                    Task { [weak self] in
                        self?.model.updateItem(text, forIdentifier: identifier)
                        self?.updateViewActions()
                    }
                }
                return CustomAuthViewText(
                    caretOffset: text?.count ?? .zero,
                    formattedText: text
                )
            }
            defer {
                Task { [weak self] in
                    let unformattedText = formatter.unformat(text ?? "")
                    self?.model.updateItem(unformattedText, forIdentifier: identifier)
                    self?.updateViewActions()
                }
            }
            return CustomAuthViewText(
                caretOffset: text?.count ?? .zero,
                formattedText: text
            )
        case let .shouldChangeCharactersIn(identifier, text, range, replacementString):
            guard let formatter = viewItems.first(where: { $0.identifier == identifier })?.formatter
            else {
                let text = (text ?? "") + replacementString
                return CustomAuthViewText(
                    caretOffset: text.count,
                    formattedText: text
                )
            }
            let result = formatter.formatInput(
                currentText: text ?? "",
                range: range,
                replacementString: replacementString
            )
            return CustomAuthViewText(
                caretOffset: result.caretBeginOffset,
                formattedText: result.formattedText
            )
        case let .endEditing(identifier, text):
            guard let formatter = viewItems.first(where: { $0.identifier == identifier })?.formatter
            else {
                defer {
                    model.updateItem(text, forIdentifier: identifier)
                }
                return CustomAuthViewText(
                    caretOffset: text?.count ?? .zero,
                    formattedText: text
                )
            }
            defer {
                let unformattedText = formatter.unformat(text ?? "")
                model.updateItem(unformattedText, forIdentifier: identifier)
                updateViewActions()
            }
            let offset = formatter.getCaretOffset(for: text ?? "")
            return CustomAuthViewText(caretOffset: offset, formattedText: text)
        }
    }

    func handleActionEvent(_ event: CustomAuthViewActionEvent) {
        switch event {
        case .tapInside:
            Task { [weak self] in
                do {
                    guard let self = self else { return }
                    self.model.clearErrors()
                    self.updateViewItems()
                    let result = try await self.model.authenticate()
                    self.processAuthenticationFeedback(result)
                } catch {
                    // show alert with error
                }
            }
        }
    }
}

private extension CustomAuthViewModel {
    private func processAuthenticationFeedback(
        _ nextStep: CustomAuthModelNextStep
    ) {
        switch nextStep {
        case .setNewPassword:
            coordinator.moveFromCustomAuth(to: CustomAuthRoute.setNewPassword)
        case .resetPassword:
            coordinator.moveFromCustomAuth(to: CustomAuthRoute.resetPassword)
        case .done:
            coordinator.moveFromCustomAuth(to: CustomAuthRoute.done)
        case .confirm:
            coordinator.moveFromCustomAuth(to: CustomAuthRoute.codeConfirmation)
        case .unknown:
            break
        }
    }

    private func updateViewItems() {
        let modelItems = model.fetchItems()
        viewItems = mapper.mapItems(modelItems)
        onItemsHaveBeenPrepared?(viewItems)
    }

    private func updateViewActions() {
        let isActionEnabled = model.validate()
        viewActions = viewActions.map {
            var newAction = $0
            newAction.isEnabled = isActionEnabled
            return newAction
        }
        onActionsHaveBeenPrepared?(viewActions)
    }
}