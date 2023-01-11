// System
import UIKit

// SDK
import Common
import Style

final class AttachPhotoViewModel: AttachPhotoViewModelProtocol {

    // MARK: - Properties
    private var snapshot = DataSourceSnapshot()
    private let viewSection = AttachPhotoViewSection.main
    private var placeTitle: String?
    private var coordinator: AttachPhotoCoordinatable & AttachPhotoCoordinatorEventHandlerProtocol

    // MARK: - Dependencies
    private let model: AttachPhotoModelProtocol
    private let contentMapper: AttachPhotoViewMappable

    // MARK: - State
    var onContentHasBeenPrepared: ((AttachPhotoViewContent) -> Void)?
    var onSnapshotHasBeenPrepared: ((DataSourceSnapshot) -> Void)?

    // MARK: - Initialization
    public init(
        model: AttachPhotoModelProtocol,
        contentMapper: AttachPhotoViewMappable,
        coordinator: AttachPhotoCoordinatable & AttachPhotoCoordinatorEventHandlerProtocol
    ) {
        self.model = model
        self.contentMapper = contentMapper
        self.coordinator = coordinator
    }

    // MARK: - Life cycle
    func setup() { }

    func load() {
        fetchContent()
        createSnapshot()
    }

    private func createSnapshot() {
        snapshot.appendSections([viewSection])
    }

    // MARK: - Interaction
    func handleActionEvent(_ event: AttachPhotoViewActionEvent) {
        switch event {
        case .removeImage(let image):
            coordinator.routeTo(.deletePhoto(image: image))
            coordinator.deletePhotoEvent = { [weak self] in
                self?.updateSnapshot(with: .removeImage(image: image))
            }
        case .addImage(let image):
            updateSnapshot(with: .addImage(image: image))
        }
    }
}

private extension AttachPhotoViewModel {
    func updateSnapshot(with event: AttachPhotoViewActionEvent) {
        switch event {
        case .addImage(let image):
            let item = AttachPhotoViewItem.common(image: image)
            snapshot.appendItems([item], toSection: viewSection)
        case .removeImage(let image):
            let item = AttachPhotoViewItem.common(image: image)
            snapshot.deleteItems([item])
        }
        onSnapshotHasBeenPrepared?(snapshot)
    }

    private func fetchContent() {
        model.fetchFeedingPoints { [weak self] response in
            guard let self = self else { return }
            self.loadMediaContent(response.content.cover)
            self.placeTitle = self.contentMapper.mapFeedingPoint(response).name
        }
    }

    private func loadMediaContent(_ key: String?) {
        guard let key = key else { return }
        model.fetchMediaContent(key: key) { [weak self] content in
            guard let self = self else { return }

            if let mediaContent = self.contentMapper.mapFeedingPointMediaContent(content) {
                let image = mediaContent.placeIcon
                let viewContent = AttachPhotoViewContent(
                    placeTitle: self.placeTitle,
                    placeImage: image,
                    hintTitle: L10n.Attach.Photo.Hint.text,
                    buttonTitle: L10n.Action.finish,
                    isActive: false)

                self.onContentHasBeenPrepared?(viewContent)
            }
        }
    }
}