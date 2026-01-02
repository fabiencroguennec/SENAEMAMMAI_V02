export type Json =
    | string
    | number
    | boolean
    | null
    | { [key: string]: Json | undefined }
    | Json[]

export interface Database {
    public: {
        Tables: {
            contacts: {
                Row: {
                    id: string
                    created_at: string
                    updated_at: string
                    full_name: string
                    email: string | null
                    phone: string | null
                    type: 'individual' | 'company' | 'employee' | 'supplier'
                    profile_data: Json
                    user_id: string | null
                }
                Insert: {
                    id?: string
                    created_at?: string
                    updated_at?: string
                    full_name: string
                    email?: string | null
                    phone?: string | null
                    type?: 'individual' | 'company' | 'employee' | 'supplier'
                    profile_data?: Json
                    user_id?: string | null
                }
                Update: {
                    id?: string
                    created_at?: string
                    updated_at?: string
                    full_name?: string
                    email?: string | null
                    phone?: string | null
                    type?: 'individual' | 'company' | 'employee' | 'supplier'
                    profile_data?: Json
                    user_id?: string | null
                }
            }
            products: {
                Row: {
                    id: string
                    created_at: string
                    updated_at: string
                    name: string
                    description: string | null
                    sku: string | null
                    price: number | null
                    stock_quantity: number | null
                    supplier_id: string | null
                    attributes: Json
                }
                Insert: {
                    id?: string
                    created_at?: string
                    updated_at?: string
                    name: string
                    description?: string | null
                    sku?: string | null
                    price?: number | null
                    stock_quantity?: number | null
                    supplier_id?: string | null
                    attributes?: Json
                }
                Update: {
                    id?: string
                    created_at?: string
                    updated_at?: string
                    name?: string
                    description?: string | null
                    sku?: string | null
                    price?: number | null
                    stock_quantity?: number | null
                    supplier_id?: string | null
                    attributes?: Json
                }
            }
            page_sections: {
                Row: {
                    id: string
                    created_at: string
                    page_slug: string
                    component_type: string
                    order_index: number
                    content_data: Json
                    is_visible: boolean | null
                }
                Insert: {
                    id?: string
                    created_at?: string
                    page_slug?: string
                    component_type: string
                    order_index?: number
                    content_data?: Json
                    is_visible?: boolean | null
                }
                Update: {
                    id?: string
                    created_at?: string
                    page_slug?: string
                    component_type?: string
                    order_index?: number
                    content_data?: Json
                    is_visible?: boolean | null
                }
            }
            ui_config: {
                Row: {
                    id: string
                    section_id: string | null
                    animation_type: string | null
                    animation_speed: number | null
                    parallax_intensity: number | null
                    background_color: string | null
                    custom_classes: string | null
                    theme_variant: string | null
                }
                Insert: {
                    id?: string
                    section_id?: string | null
                    animation_type?: string | null
                    animation_speed?: number | null
                    parallax_intensity?: number | null
                    background_color?: string | null
                    custom_classes?: string | null
                    theme_variant?: string | null
                }
                Update: {
                    id?: string
                    section_id?: string | null
                    animation_type?: string | null
                    animation_speed?: number | null
                    parallax_intensity?: number | null
                    background_color?: string | null
                    custom_classes?: string | null
                    theme_variant?: string | null
                }
            }
            posts: {
                Row: {
                    id: string
                    created_at: string
                    updated_at: string
                    title: string
                    slug: string
                    content: string | null
                    excerpt: string | null
                    cover_image_url: string | null
                    published_at: string | null
                    is_published: boolean | null
                    author_id: string | null
                }
                Insert: {
                    id?: string
                    created_at?: string
                    updated_at?: string
                    title: string
                    slug: string
                    content?: string | null
                    excerpt?: string | null
                    cover_image_url?: string | null
                    published_at?: string | null
                    is_published?: boolean | null
                    author_id?: string | null
                }
                Update: {
                    id?: string
                    created_at?: string
                    updated_at?: string
                    title?: string
                    slug?: string
                    content?: string | null
                    excerpt?: string | null
                    cover_image_url?: string | null
                    published_at?: string | null
                    is_published?: boolean | null
                    author_id?: string | null
                }
            }
        }
        Views: {
            [_ in never]: never
        }
        Functions: {
            [_ in never]: never
        }
        Enums: {
            contact_type: 'individual' | 'company' | 'employee' | 'supplier'
        }
    }
}
