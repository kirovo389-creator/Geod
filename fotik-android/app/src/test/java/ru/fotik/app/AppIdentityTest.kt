package ru.fotik.app

import org.junit.Assert.assertEquals
import org.junit.Test

class AppIdentityTest {
    @Test
    fun appHasExpectedNameAndMediaFolder() {
        assertEquals("Фотик", AppIdentity.APP_NAME)
        assertEquals("Fotik", AppIdentity.MEDIA_FOLDER)
    }
}
