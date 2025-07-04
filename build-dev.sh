#!/bin/bash
# Development build - deploys source folder directly for faster iteration
# Plugin: Speed-graph

# Load environment variables
if [ -f .env ]; then
    source .env
else
    echo "❌ .env file not found. Please create one from .env.example"
    exit 1
fi

DEV_TARGET="$TARGET_DIR/$PLUGIN_NAME"

echo "🔧 Deploying development version of Speed-graph plugin..."

# Check if target directory exists
if [ ! -d "$TARGET_DIR" ]; then
    echo "❌ Target directory not found: $TARGET_DIR"
    echo "💡 Check your .env file and ensure the path is correct"
    exit 1
fi

# Remove existing development directory to ensure clean deployment
if [ -d "$DEV_TARGET" ]; then
    echo "🧹 Removing existing development version..."
    rm -rf "$DEV_TARGET"
fi

# Create fresh target directory
mkdir -p "$DEV_TARGET"

# Copy files
cp info.toml "$DEV_TARGET/"
cp -r src/ "$DEV_TARGET/"

echo "✅ Development version deployed to: $DEV_TARGET"
echo "📁 Fresh deployment completed:"
echo "   - info.toml"
echo "   - src/ (all source files)"
echo ""
echo "💡 Use Developer Mode in Trackmania to load from folder"
echo "🎮 Look for folder icon next to 'Speed-graph' in plugin list" 