#!/bin/bash
# setup.sh - Automate Senaemammai Frontend Init

echo "🚀 Initializing Senaemammai Frontend..."

# 1. Check if directory exists
if [ -d "senaemammai-front" ]; then
    echo "⚠️ Directory 'senaemammai-front' already exists."
    read -p "Do you want to continue and install dependencies? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
    cd senaemammai-front
else
    # 2. Init Nuxt
    echo "📦 Creating Nuxt project..."
    npx nuxi@latest init senaemammai-front
    cd senaemammai-front
fi

# 3. Install Dependencies
echo "📥 Installing dependencies (Supabase, Tailwind, GSAP)..."
npm install @nuxtjs/supabase @nuxtjs/tailwindcss gsap

# 4. Create .env example
if [ ! -f ".env" ]; then
    echo "📝 Creating .env file..."
    cat <<EOT >> .env
SUPABASE_URL="REPLACE_WITH_YOUR_URL"
SUPABASE_KEY="REPLACE_WITH_YOUR_ANON_KEY"
EOT
    echo "✅ .env created. Please update it with real credentials."
else
    echo "ℹ️ .env already exists, skipping."
fi

echo "✅ Setup complete!"
echo "👉 cd senaemammai-front"
echo "👉 npm run dev"
