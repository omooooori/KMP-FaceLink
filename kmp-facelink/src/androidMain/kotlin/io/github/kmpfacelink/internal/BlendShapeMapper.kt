package io.github.kmpfacelink.internal

import io.github.kmpfacelink.model.BlendShape
import io.github.kmpfacelink.model.BlendShapeData

/**
 * Maps MediaPipe FaceLandmarker blend shape output to our [BlendShape] enum.
 *
 * MediaPipe outputs 53 categories (index 0 = "_neutral", which is skipped).
 * The remaining 52 use the same naming as ARKit.
 */
internal object BlendShapeMapper {

    /**
     * MediaPipe blend shape category name → [BlendShape] enum.
     * MediaPipe uses the exact same camelCase naming as ARKit.
     */
    private val nameToBlendShape: Map<String, BlendShape> by lazy {
        BlendShape.entries.associateBy { it.arKitName }
    }

    /**
     * Convert MediaPipe blend shape categories to [BlendShapeData].
     *
     * @param categories List of (name, score) pairs from MediaPipe FaceLandmarkerResult
     */
    fun mapFromMediaPipe(categories: List<Pair<String, Float>>): BlendShapeData {
        val result = mutableMapOf<BlendShape, Float>()
        for ((name, score) in categories) {
            if (name == "_neutral") continue
            val shape = nameToBlendShape[name] ?: continue
            result[shape] = score.coerceIn(0f, 1f)
        }

        // Fill missing shapes with 0.0 (e.g. tongueOut not supported by MediaPipe)
        for (shape in BlendShape.entries) {
            if (shape !in result) {
                result[shape] = 0f
            }
        }
        return result
    }
}
