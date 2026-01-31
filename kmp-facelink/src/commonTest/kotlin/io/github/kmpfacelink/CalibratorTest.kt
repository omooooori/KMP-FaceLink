package io.github.kmpfacelink

import io.github.kmpfacelink.model.BlendShape
import io.github.kmpfacelink.util.Calibrator
import kotlin.math.abs
import kotlin.test.Test
import kotlin.test.assertTrue

class CalibratorTest {

    private fun assertApprox(expected: Float, actual: Float, epsilon: Float = 0.05f) {
        assertTrue(abs(expected - actual) < epsilon, "Expected $expected but was $actual")
    }

    @Test
    fun firstCallReturnsInputDirectly() {
        val calibrator = Calibrator()
        val input = mapOf(BlendShape.JAW_OPEN to 0.5f)
        val result = calibrator.calibrate(input)
        // First call: min=max=0.5, range < EPSILON, so value is returned as-is
        assertApprox(0.5f, result[BlendShape.JAW_OPEN]!!)
    }

    @Test
    fun normalizesAfterRangeIsEstablished() {
        val calibrator = Calibrator()

        // Frame 1: value = 0.2 → min=0.2, max=0.2
        calibrator.calibrate(mapOf(BlendShape.JAW_OPEN to 0.2f))

        // Frame 2: value = 0.8 → min=0.2, max=0.8, range=0.6
        // normalized = (0.8 - 0.2) / 0.6 = 1.0
        val result = calibrator.calibrate(mapOf(BlendShape.JAW_OPEN to 0.8f))
        assertApprox(1.0f, result[BlendShape.JAW_OPEN]!!)
    }

    @Test
    fun midRangeValueNormalizesToHalf() {
        val calibrator = Calibrator()

        calibrator.calibrate(mapOf(BlendShape.JAW_OPEN to 0.0f))
        calibrator.calibrate(mapOf(BlendShape.JAW_OPEN to 1.0f))

        // value=0.5, min=0.0, max=1.0 → normalized = 0.5
        val result = calibrator.calibrate(mapOf(BlendShape.JAW_OPEN to 0.5f))
        assertApprox(0.5f, result[BlendShape.JAW_OPEN]!!)
    }

    @Test
    fun resetClearsRange() {
        val calibrator = Calibrator()

        calibrator.calibrate(mapOf(BlendShape.JAW_OPEN to 0.0f))
        calibrator.calibrate(mapOf(BlendShape.JAW_OPEN to 1.0f))
        calibrator.reset()

        // After reset, first call should return value as-is
        val result = calibrator.calibrate(mapOf(BlendShape.JAW_OPEN to 0.7f))
        assertApprox(0.7f, result[BlendShape.JAW_OPEN]!!)
    }
}
