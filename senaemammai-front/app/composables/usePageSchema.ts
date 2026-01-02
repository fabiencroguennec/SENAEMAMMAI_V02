export const usePageSchema = (page: any, sections: any[]) => {
    return computed(() => {
        if (!page) return {}

        // Base Schema: WebPage
        const schema: any = {
            "@context": "https://schema.org",
            "@type": "WebPage",
            "name": page.title,
            "description": page.seo_description || page.description || '',
            "url": `https://senaemammai.com/${page.slug === 'home' ? '' : page.slug}`, // TODO: Dynamic URL
            "isPartOf": {
                "@type": "WebSite",
                "name": "SENAEMAMMAI",
                "url": "https://senaemammai.com"
            },
            "hasPart": []
        }

        // Generate Schema for Sections
        if (sections && sections.length > 0) {
            schema.hasPart = sections
                .filter(s => s.is_visible)
                .map(section => {
                    const content = section.content_data

                    // Basic CreativeWork schema for generic sections
                    const part: any = {
                        "@type": "CreativeWork",
                        "name": content.title || "Section",
                        "headline": content.title,
                        "description": content.description || ''
                    }

                    // If section has modules, try to extract more specific info
                    if (content.modules && content.modules.length > 0) {
                        const texts = content.modules
                            .filter((m: any) => m.type === 'text')
                            .map((m: any) => m.content)
                            .join(' ')

                        if (texts) {
                            part.text = texts
                        }

                        const images = content.modules
                            .filter((m: any) => m.type === 'image')
                            .map((m: any) => m.url)

                        if (images.length > 0) {
                            part.image = images
                        }
                    }

                    return part
                })
        }

        return schema
    })
}
