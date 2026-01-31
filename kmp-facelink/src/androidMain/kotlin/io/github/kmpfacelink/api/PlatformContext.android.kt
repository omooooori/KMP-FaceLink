package io.github.kmpfacelink.api

import android.content.Context
import androidx.lifecycle.LifecycleOwner

/**
 * Android platform context wrapping [Context] and [LifecycleOwner].
 */
public actual class PlatformContext(
    public val context: Context,
    public val lifecycleOwner: LifecycleOwner,
)
