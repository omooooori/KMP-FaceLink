package io.github.kmpfacelink.api

import io.github.kmpfacelink.model.FaceTrackerConfig

/**
 * Platform-specific factory for creating [FaceTracker] instances.
 *
 * Each platform (Android/iOS) provides its own implementation via `expect`/`actual`.
 */
public expect fun createFaceTracker(
    platformContext: PlatformContext,
    config: FaceTrackerConfig = FaceTrackerConfig(),
): FaceTracker

/**
 * Platform-specific context required to initialize the face tracker.
 *
 * - Android: wraps `android.content.Context` + `LifecycleOwner`
 * - iOS: no context needed (empty object)
 */
public expect class PlatformContext
