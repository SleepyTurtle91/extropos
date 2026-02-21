package com.extrotarget.extropos

import org.junit.Assert.*
import org.junit.Test

class PrinterPluginUnitTest {

    @Test
    fun buildStructuredReceipt_withStringNumericFields_doesNotThrow() {
        val plugin = PrinterPlugin()
        val item = mapOf<String, Any>("name" to "Test Item", "quantity" to "2", "total" to "15.50")
        val data = mapOf(
            "businessName" to "Test Store",
            "items" to listOf(item),
            "subtotal" to "15.50",
            "tax" to "1.50",
            "serviceCharge" to "0.00",
            "total" to "17.00",
            "content" to "Test content fallback"
        )

        val result = plugin.buildStructuredReceiptSafe(data, 48)
        assertNotNull(result)
        assertTrue(result.isNotEmpty())
    }

    @Test
    fun buildStructuredReceipt_withMissingFields_fallsBackToContent() {
        val plugin = PrinterPlugin()
        val data = mapOf<String, Any>(
            "businessName" to "Test Store",
            "content" to "Simple content fallback"
        )

        val result = plugin.buildStructuredReceiptSafe(data, 48)
        assertNotNull(result)
        assertTrue(result.isNotEmpty())
    }
}
