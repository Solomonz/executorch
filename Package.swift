// swift-tools-version:5.9
/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree.
 */

import PackageDescription

let version = "0.6.0"
let url = "https://ossci-ios.s3.amazonaws.com/executorch/"
let debug = "_debug"
let deliverables = [
  "backend_coreml": [
    "sha256": "768fe0532e41cd8121c9e9b60d9a1bdff15a5d78c84f6ffee5124daf862d23b0",
    "sha256" + debug: "d37d99413b2a892526cfef833182be02db37e7a700cefbf884846d44efe30e5d",
    "frameworks": [
      "Accelerate",
      "CoreML",
    ],
    "libraries": [
      "sqlite3",
    ],
  ],
  "backend_mps": [
    "sha256": "9ddc29a290fa0e4c428574d07eb110e0b2faef60e4ad06ac874b49bb3291b756",
    "sha256" + debug: "b915ddb3e99e59312fa88dff2bd4981ea9d668cef5e86a4408d3c99e51fca257",
    "frameworks": [
      "Metal",
      "MetalPerformanceShaders",
      "MetalPerformanceShadersGraph",
    ],
  ],
  "backend_xnnpack": [
    "sha256": "d9e6828c1d06be0774dfbc201214554ce8dd797a86dc93f235b355f493fa0ea5",
    "sha256" + debug: "b69599cdde29da8deb31f30a30270626fc20d93743ea1f6c710d566b915edb67",
  ],
  "executorch": [
    "sha256": "2355f3ed13c9e10852166e2b153fc358e34eb188387d0c6b691c28a3de145b5f",
    "sha256" + debug: "5013b027ad19424e1b095dcbf17a3b40319a7252df7a8352c3edf317bc040eee",
  ],
  "kernels_custom": [
    "sha256": "1d9fbcd13c8b1a8b995ad42e2489792f6ee136ee887319ec08c7f80c085078ed",
    "sha256" + debug: "82e8141667feb39e22a99a58a3160c4a00b19be658c9817834d88e0f23b8726e",
  ],
  "kernels_optimized": [
    "sha256": "022489c8600a6a502a6c127f0d053157ea36663708024367faa8e5146957b377",
    "sha256" + debug: "85d2316a7663907660bd50d4c0f50b62289d9ceb88fce33a128e30de35c723d3",
  ],
  "kernels_portable": [
    "sha256": "c1a799f2e7c9e2a3aa8fdde6c70da6e3e17baa1a0baab9cd5493bfae6dd582a8",
    "sha256" + debug: "a6986d15ee4fb1a7c041a383f97e2b24adb45956e1567093c06b573495a3b051",
  ],
  "kernels_quantized": [
    "sha256": "da068878bf5c066d7cc60911d460aacf6addbf9c2ae6e9e244750b42af57093a",
    "sha256" + debug: "86d417ec131efb0abb6f94d31852b2dc0f646680699715440500ec997835104d",
  ],
].reduce(into: [String: [String: Any]]()) {
  $0[$1.key] = $1.value
  $0[$1.key + debug] = $1.value
}
.reduce(into: [String: [String: Any]]()) {
  var newValue = $1.value
  if $1.key.hasSuffix(debug) {
    $1.value.forEach { key, value in
      if key.hasSuffix(debug) {
        newValue[String(key.dropLast(debug.count))] = value
      }
    }
  }
  $0[$1.key] = newValue.filter { key, _ in !key.hasSuffix(debug) }
}

let package = Package(
  name: "executorch",
  platforms: [
    .iOS(.v17),
    .macOS(.v10_15),
  ],
  products: deliverables.keys.map { key in
    .library(name: key, targets: ["\(key)_dependencies"])
  }.sorted { $0.name < $1.name },
  targets: deliverables.flatMap { key, value -> [Target] in
    [
      .binaryTarget(
        name: key,
        url: "\(url)\(key)-\(version).zip",
        checksum: value["sha256"] as? String ?? ""
      ),
      .target(
        name: "\(key)_dependencies",
        dependencies: [.target(name: key)],
        path: ".Package.swift/\(key)",
        linkerSettings:
          (value["frameworks"] as? [String] ?? []).map { .linkedFramework($0) } +
          (value["libraries"] as? [String] ?? []).map { .linkedLibrary($0) }
      ),
    ]
  }
)
