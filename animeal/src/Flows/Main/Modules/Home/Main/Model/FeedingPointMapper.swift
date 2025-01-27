import Foundation

// sourcery: AutoMockable
protocol FeedingPointMappable {
    func mapFeedingPoint(_ input: animeal.FeedingPoint, isFavorite: Bool) -> HomeModel.FeedingPoint
}

final class FeedingPointMapper: FeedingPointMappable {
    func mapFeedingPoint(_ input: animeal.FeedingPoint, isFavorite: Bool) -> HomeModel.FeedingPoint {
        return HomeModel.FeedingPoint(
            identifier: input.id,
            location: HomeModel.Location(
                latitude: input.location.lat,
                longitude: input.location.lon,
                radius: .init(value: input.distance, unit: .meters)
            ),
            pet: convert(categoryTag: input.category?.tag ?? .dogs),
            hungerLevel: conver(pointStatus: input.status),
            isFavorite: isFavorite
        )
    }

    private func conver(pointStatus: FeedingPointStatus) -> HomeModel.HungerLevel {
        switch pointStatus {
        case .starved:
            return .high
        case .pending:
            return .mid
        case .fed:
            return .low
        }
    }

    private func convert(categoryTag: animeal.CategoryTag) -> HomeModel.Pet {
        switch categoryTag {
        case .cats:
            return HomeModel.Pet.cats
        case .dogs:
            return HomeModel.Pet.dogs
        }
    }
}
