import Foundation

// MARK: - AboutModel
final class AboutModel: AboutModelProtocol, ObservableObject {

    // MARK: - Published properties
    @Published var contentText: String
    @Published var links: [AboutLink]
    @Published var appVersion: String

    // MARK: - Initialization
    init(contentText: String = "", links: [AboutLink] = [], appVersion: String = "") {
        self.contentText = contentText
        self.links = links
        self.appVersion = appVersion
    }
}

// MARK: - Preview
extension AboutModel {
    static var previewModel: AboutModel {
        // swiftlint:disable line_length
        return AboutModel(
            contentText: "Lorem ipsum dolor sit amet, consectetuer adipiscing elit. Aenean commodo ligula eget dolor. Aenean massa. Cum sociis natoque penatibus et magnis dis parturient montes, nascetur ridiculus mus. Donec quam felis, ultricies nec, pellentesque eu, pretium quis, sem. Nulla consequat massa quis enim. \n\n\n\nLorem ipsum dolor sit amet, consectetuer adipiscing elit. Aenean commodo ligula eget dolor. Aenean massa. Cum sociis natoque penatibus et magnis dis parturient montes, nascetur ridiculus mus. Donec quam felis, ultricies nec, pellentesque eu, pretium quis, sem. Nulla consequat massa quis enim.\n\n\n\nLorem ipsum dolor sit amet, consectetuer adipiscing elit. Aenean commodo ligula eget dolor. Aenean massa. Cum sociis natoque penatibus et magnis dis parturient montes, nascetur ridiculus mus. Donec quam felis, ultricies nec, pellentesque eu, pretium quis, sem. Nulla consequat massa quis enim.",
            links: AboutLink.allCases,
            appVersion: "App version \(AppInfo.appVersion)"
            // swiftlint:enable line_length
        )
    }
}
