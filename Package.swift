// swift-tools-version:5.7
import PackageDescription

@main
struct NoScrollPackage: Package {
    static var name: String = "NoScroll"
    static var defaultLocalization: String = "en"
    
    static var platforms: [SupportedPlatform] = [
        .iOS(.v15)
    ]
    
    static var products: [Product] = [
        .app(
            name: "NoScroll",
            targets: ["NoScroll"]
        )
    ]
    
    static var dependencies: [Package.Dependency] = []
    
    static var targets: [Target] = [
        .target(
            name: "NoScroll",
            dependencies: [],
            path: "NoScroll",
            exclude: [],
            resources: [],
            publicHeadersPath: nil,
            cSettings: nil,
            cxxSettings: nil,
            swiftSettings: nil,
            linkerSettings: nil
        )
    ]
}
