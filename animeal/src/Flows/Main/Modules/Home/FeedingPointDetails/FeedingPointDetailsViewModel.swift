import Foundation
import CoreLocation
import UIComponents

final class FeedingPointDetailsViewModel: FeedingPointDetailsViewModelLifeCycle,
                                          FeedingPointDetailsViewInteraction,
                                          FeedingPointDetailsViewState {
    // MARK: - Dependencies
    private let model: (FeedingPointDetailsModelProtocol & FeedingPointDetailsDataStoreProtocol)
    private let coordinator: FeedingPointCoordinatable
    private let contentMapper: FeedingPointDetailsViewMappable

    // MARK: - State
    var onContentHaveBeenPrepared: ((FeedingPointDetailsViewMapper.FeedingPointDetailsViewItem) -> Void)?
    var onMediaContentHaveBeenPrepared: ((FeedingPointDetailsViewMapper.FeedingPointMediaContent) -> Void)?
    var onFavoriteMutationFailed: (() -> Void)?

    let isOverMap: Bool
    var showOnMapAction: ButtonView.Model? {
        if isOverMap { return .none }

        return ButtonView.Model(
            identifier: UUID().uuidString,
            viewType: TextButtonView.self,
            title: L10n.Action.showOnMap
        )
    }

    // MARK: - Initialization
    init(
        isOverMap: Bool,
        model: (FeedingPointDetailsModelProtocol & FeedingPointDetailsDataStoreProtocol),
        contentMapper: FeedingPointDetailsViewMappable,
        coordinator: FeedingPointCoordinatable
    ) {
        self.isOverMap = isOverMap
        self.model = model
        self.contentMapper = contentMapper
        self.coordinator = coordinator
        setup()
    }

    // MARK: - Life cycle
    func setup() { }

    func load() {
        model.fetchFeedingPoint { [weak self] content in
            DispatchQueue.main.async {
                self?.updateContent(content)
            }
        }
        model.onFeedingPointChange = { [weak self] content in
            DispatchQueue.main.async {
                self?.updateContent(content)
            }
        }
    }

    private func loadMediaContent(_ key: String?) {
        guard let key = key else { return }
        model.fetchMediaContent(key: key) { [weak self] content in
            if let mediaContent = self?.contentMapper.mapFeedingPointMediaContent(content) {
                DispatchQueue.main.async {
                    self?.onMediaContentHaveBeenPrepared?(mediaContent)
                }
            }
        }
    }

    private func updateContent(_ modelContent: FeedingPointDetailsModel.PointContent) {
        loadMediaContent(modelContent.content.header.cover)
        onContentHaveBeenPrepared?(contentMapper.mapFeedingPoint(modelContent))
    }

    // MARK: - Interaction
    func handleActionEvent(_ event: FeedingPointEvent) {
        switch event {
        case .tapAction:
            coordinator.routeTo(
                .feed(
                    FeedingPointFeedDetails(
                        identifier: model.feedingPointId,
                        coordinates: model.feedingPointLocation
                    )
                )
            )
        case .tapFavorite:
            Task { @MainActor [weak self] in
                guard let self else { return }
                do {
                    let success = try await model.mutateFavorite()
                    if !success {
                        self.onFavoriteMutationFailed?()
                    }
                } catch {
                    self.onFavoriteMutationFailed?()
                }
            }
        case .tapShowOnMap:
            coordinator.routeTo(
                .map(identifier: model.feedingPointId)
            )
        }
    }
}
