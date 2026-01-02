
import { serverSupabaseServiceRole } from '#supabase/server'

export default defineEventHandler(async (event) => {
    const client = serverSupabaseServiceRole(event)

    // Simple query to verify DB is awake
    // We query the 'pages' table (assuming it exists and has data) just to read *something*
    // Limit 1 is efficient.
    const { data, error } = await client.from('pages').select('id').limit(1)

    if (error) {
        throw createError({
            statusCode: 500,
            statusMessage: 'Database Error',
            data: error.message,
        })
    }

    return {
        status: 'ok',
        timestamp: new Date().toISOString(),
        message: 'Pong! Database is active.',
    }
})
