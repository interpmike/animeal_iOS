import Foundation
import Services
import Amplify

final class AttachPhotoModel: AttachPhotoModelProtocol{
    // MARK: - Private properties
    private let mapper: AttachPhotoModelMapperProtocol
    
    typealias Context = NetworkServiceHolder & DataStoreServiceHolder & UserProfileServiceHolder
    private let context: Context
    
    // MARK: - DataStore properties
    let feedingPointId: String
    
    private var feedingPoint: FeedingPoint?
    
    // MARK: - Initialization
    init(
        pointId: String,
        mapper: AttachPhotoModelMapperProtocol = AttachPhotoModelMapper(),
        context: Context = AppDelegate.shared.context
    ) {
        self.feedingPointId = pointId
        self.mapper = mapper
        self.context = context
    }
    
    func fetchFeedingPoints(_ completion: ((AttachPhotoModel.PointContent) -> Void)?) {
        context.networkService.query(request: .get(FeedingPoint.self, byId: feedingPointId)) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let point):
                guard let point = point else {
                    return
                }
                self.feedingPoint = point
                Task {
                    DispatchQueue.main.async {
                        completion?(
                            self.mapper.map(point)
                        )
                    }
                }
            case .failure(let error):
                // TODO: Handele error
                print(error)
            }
        }
    }
    
    func fetchMediaContent(key: String, completion: ((Data?) -> Void)?) {
        context.dataStoreService.downloadData(
            key: key,
            options: .init(accessLevel: .guest)
        ) { result in
            switch result {
            case .success(let data):
                DispatchQueue.main.async {
                    completion?(data)
                }
            case .failure(let error):
                // TODO: Handele error
                print(error.localizedDescription)
            }
        }
    }
}

extension AttachPhotoModel {
    struct PointContent {
        let content: Content
    }
    
    struct Content {
        let cover: String?
        let title: String
    }
}