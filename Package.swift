// swift-tools-version:5.3
import PackageDescription

let package = Package(
    name: "AttachmentInput",
    platforms: [.iOS(.v12)],
    products: [
        .library(
            name: "AttachmentInput",
            targets: ["AttachmentInput"]),
    ],
    dependencies: [
        .package(url: "https://github.com/ReactiveX/RxSwift.git", from: "5.1.1"),
        .package(url: "https://github.com/RxSwiftCommunity/RxDataSources.git", from: "4.0.1")
    ],
    targets: [
        .target(
            name: "AttachmentInput",
            dependencies: ["RxSwift",
                           .product(name: "RxCocoa", package: "RxSwift"),
                           "RxDataSources",
                          ],
            path: "./Sources",
            exclude:["AttachmentInput/Info.plist"],
            resources: [.copy("Resources/AttachmentInput.strings")]
        )
    ]
)
