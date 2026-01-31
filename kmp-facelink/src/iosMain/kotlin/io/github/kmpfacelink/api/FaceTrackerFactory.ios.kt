package io.github.kmpfacelink.api

import io.github.kmpfacelink.internal.ARKitFaceTracker
import io.github.kmpfacelink.model.FaceTrackerConfig

public actual fun createFaceTracker(
    platformContext: PlatformContext,
    config: FaceTrackerConfig,
): FaceTracker = ARKitFaceTracker(config)
