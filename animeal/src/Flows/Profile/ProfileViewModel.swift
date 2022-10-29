// System
import Foundation

// SDK
import Common

final class ProfileViewModel: ProfileViewModelProtocol {
    // MARK: - Private properties
    private var viewItems: [ProfileViewItem]

    // MARK: - Dependencies
    private let model: ProfileModelProtocol
    private let coordinator: ProfileCoordinatable
    private let mapper: ProfileViewItemMappable
    private let dateFormatter: DateFormatter

    // MARK: - State
    var onHeaderHasBeenPrepared: ((ProfileViewHeader) -> Void)?
    var onItemsHaveBeenPrepared: (([ProfileViewItem]) -> Void)?
    var onActionsHaveBeenPrepared: (([ProfileViewAction]) -> Void)?
    var onActivityIsNeededToDisplay: ((@escaping @MainActor () async throws -> Void) -> Void)?

    // MARK: - Initialization
    init(
        model: ProfileModelProtocol,
        coordinator: ProfileCoordinatable,
        mapper: ProfileViewItemMappable,
        dateFormatter: DateFormatter = .default
    ) {
        self.model = model
        self.coordinator = coordinator
        self.mapper = mapper
        self.dateFormatter = dateFormatter
        self.viewItems = []
    }

    // MARK: - Life cycle
    func setup() { }

    func load() {
        let viewHeader = ProfileViewHeader(
            title: L10n.Profile.header,
            subtitle: L10n.Profile.subHeader
        )
        onHeaderHasBeenPrepared?(viewHeader)

        updateViewItems(model.fetchPlaceholderItems)
        updateViewItems(model.fetchItems)
        updateViewActions()
    }

    // MARK: - Interaction
    @discardableResult
    func handleItemEvent(_ event: ProfileViewItemEvent) -> ProfileViewText {
        switch event {
        case .changeText(let textEvent):
            return handleTextEvent(textEvent)
        case let .changeDate(identifier, date):
            let text = dateFormatter.string(from: date)
            model.updateItem(text, forIdentifier: identifier)
            return ProfileViewText(caretOffset: text.count, formattedText: text)
        }
    }

    func handleTextEvent(_ event: ProfileViewTextEvent) -> ProfileViewText {
        switch event {
        case let .beginEditing(identifier, text):
            guard let formatter = viewItems.first(where: { $0.identifier == identifier })?.formatter
            else {
                return ProfileViewText(
                    caretOffset: text?.count ?? .zero,
                    formattedText: text
                )
            }
            let offset = formatter.getCaretOffset(for: text ?? .empty)
            return ProfileViewText(caretOffset: offset, formattedText: text)
        case let .didChange(identifier, text):
            guard let formatter = viewItems.first(where: { $0.identifier == identifier })?.formatter
            else {
                defer {
                    Task { [weak self] in
                        self?.model.updateItem(text, forIdentifier: identifier)
                        self?.updateViewActions()
                    }
                }
                return ProfileViewText(
                    caretOffset: text?.count ?? .zero,
                    formattedText: text
                )
            }
            defer {
                Task { [weak self] in
                    let unformattedText = formatter.unformat(text ?? .empty)
                    self?.model.updateItem(unformattedText, forIdentifier: identifier)
                    self?.updateViewActions()
                }
            }
            return ProfileViewText(
                caretOffset: text?.count ?? .zero,
                formattedText: text
            )
        case let .shouldChangeCharactersIn(identifier, text, range, replacementString):
            guard let formatter = viewItems.first(where: { $0.identifier == identifier })?.formatter
            else {
                let text = (text ?? .empty) + replacementString
                return ProfileViewText(
                    caretOffset: text.count,
                    formattedText: text
                )
            }
            let result = formatter.formatInput(
                currentText: text ?? .empty,
                range: range,
                replacementString: replacementString
            )
            return ProfileViewText(
                caretOffset: result.caretBeginOffset,
                formattedText: result.formattedText
            )
        case let .endEditing(identifier, text):
            guard let formatter = viewItems.first(where: { $0.identifier == identifier })?.formatter
            else {
                defer {
                    model.updateItem(text, forIdentifier: identifier)
                }
                return ProfileViewText(
                    caretOffset: text?.count ?? .zero,
                    formattedText: text
                )
            }
            defer {
                let unformattedText = formatter.unformat(text ?? .empty)
                model.updateItem(unformattedText, forIdentifier: identifier)
                updateViewActions()
            }
            let offset = formatter.getCaretOffset(for: text ?? .empty)
            return ProfileViewText(caretOffset: offset, formattedText: text)
        }
    }

    func handleActionEvent(_ event: ProfileViewActionEvent) {
        switch event {
        case .tapInside(let identifier):
            guard let intermediateStep = model.executeAction(identifier) else { return }
            switch intermediateStep {
            case .update:
                updateViewItems(model.fetchPlaceholderItems)
                updateViewActions()
            case .proceed:
                guard model.validateItems() else {
                    updateViewItems(model.fetchPlaceholderItems)
                    updateViewActions()
                    return
                }
                updateViewItems(model.fetchPlaceholderItems)
                updateViewActions()
                onActivityIsNeededToDisplay?({ [weak self] in
                    guard let self else { return }
                    let nextStep = try await self.model.proceedAction(identifier)
                    self.processNextStep(nextStep)
                })
            }
        case .itemWasTapped(let identifier):
            guard let requiredAction = model.fetchRequiredAction(forIdentifier: identifier) else { return }
            switch requiredAction {
            case .openPicker(let openPickerComponents):
                let completion = { [weak self] in
                    guard let self = self else { return }
                    self.model.updateItem(nil, forIdentifier: identifier)
                    self.updateViewItems(self.model.fetchPlaceholderItems)
                }
                coordinator.move(to: .picker({ openPickerComponents.maker(completion) }))
            }
        }
    }
}

private extension ProfileViewModel {
    private func processNextStep(
        _ nextStep: ProfileModelNextStep
    ) {
        switch nextStep {
        case .done:
            coordinator.move(to: ProfileRoute.done)
        case let .confirm(details, attribute):
            coordinator.move(to: ProfileRoute.confirm(details, attribute))
        }
    }

    private func updateViewItems(
        _ operation: @escaping () async throws -> [ProfileModelItem]
    ) {
        onActivityIsNeededToDisplay?({ [weak self] in
            guard let self else { return }
            let modelItems = try await operation()
            self.viewItems = self.mapper.mapItems(modelItems)
            self.onItemsHaveBeenPrepared?(self.viewItems)
        })
    }

    private func updateViewActions() {
        let modelActions = model.fetchActions()
        let viewActions = modelActions.map(ProfileViewAction.init)
        onActionsHaveBeenPrepared?(viewActions)
    }
}

private extension DateFormatter {
    static let `default`: DateFormatter = {
        let item = DateFormatter()
        item.dateFormat = "dd MMM, yyyy"
        return item
    }()
}
