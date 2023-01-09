import Foundation

// MARK: - View
protocol FavouritesViewModelOutput: AnyObject {
    func populateFavourites(_ viewState: FavouriteViewContentState)
    func applyFavouriteMediaContent(_ content: FavouriteMediaContent)
}

// MARK: - Model
protocol FavouritesModelProtocol: AnyObject {
    func fetchFavourites() async throws -> [FavouritesModel.FavouriteContent]
    func fetchMediaContent(key: String, completion: ((Data?) -> Void)?)
}

// MARK: - ViewModel
typealias FavouritesCombinedViewModel = FavouritesViewModelLifeCycle &
                                        FavouritesViewInteraction &
                                        FavouritesViewState

protocol FavouritesViewModelLifeCycle: AnyObject {
    func load()
}

protocol FavouritesViewInteraction: AnyObject {
    func handleActionEvent(_ event: FavouritesViewActionEvent)
}

protocol FavouritesViewState: AnyObject {
}

enum FavouritesViewActionEvent {
    case tapFeedingPoint(String)
}

// MARK: - Coordinator
protocol FavouritesCoordinatable {
    func routeTo(_ route: FavouritesRoute)
}

enum FavouritesRoute {
    case details(String)
}