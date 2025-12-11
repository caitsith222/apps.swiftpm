// swift-tools-version: 5.8

import PackageDescription

let package = Package(
    name: "MyApp",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .iOSApplication(
            name: "MyApp",
            targets: ["AppModule"],
            displayVersion: "1.0",
            bundleVersion: "1",
            appIcon: .placeholder(icon: .cloud),
            accentColor: .presetColor(.blue),
            supportedDeviceFamilies: [
                .pad,
                .phone
            ],
            supportedInterfaceOrientations: [
                .portrait,
                .landscapeRight,
                .landscapeLeft,
                .portraitUpsideDown(.when(deviceFamilies: [.pad]))
            ]
        )
    ],
    targets: [
        .executableTarget(
            name: "AppModule",
            path: "."
        )
    ]
)
