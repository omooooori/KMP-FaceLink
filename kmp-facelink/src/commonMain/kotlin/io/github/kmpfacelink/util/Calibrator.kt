package io.github.kmpfacelink.util

import io.github.kmpfacelink.model.BlendShape
import io.github.kmpfacelink.model.BlendShapeData

/**
 * Per-session calibration that learns per-user min/max ranges and normalizes values.
 *
 * During tracking, observed min/max values for each blend shape are recorded.
 * Values are then remapped from [observedMin, observedMax] to [0.0, 1.0].
 */
internal class Calibrator {

    private val minValues = mutableMapOf<BlendShape, Float>()
    private val maxValues = mutableMapOf<BlendShape, Float>()

    /**
     * Update observed ranges and return calibrated blend shape data.
     */
    fun calibrate(data: BlendShapeData): BlendShapeData {
        val calibrated = mutableMapOf<BlendShape, Float>()
        for ((shape, value) in data) {
            val currentMin = minValues[shape]
            val currentMax = maxValues[shape]

            val newMin = if (currentMin == null) value else minOf(currentMin, value)
            val newMax = if (currentMax == null) value else maxOf(currentMax, value)
            minValues[shape] = newMin
            maxValues[shape] = newMax

            val range = newMax - newMin
            calibrated[shape] = if (range > EPSILON) {
                ((value - newMin) / range).coerceIn(0f, 1f)
            } else {
                value
            }
        }
        return calibrated
    }

    fun reset() {
        minValues.clear()
        maxValues.clear()
    }

    private companion object {
        const val EPSILON = 0.01f
    }
}
