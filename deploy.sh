#!/bin/bash
# Complete build and deployment automation for Speed-graph plugin

# Load environment variables
if [ -f .env ]; then
    source .env
else
    echo "❌ .env file not found. Please create one from .env.example"
    exit 1
fi

# Function to check if Trackmania is running
check_trackmania() {
    if tasklist.exe 2>/dev/null | grep -q "Trackmania.exe"; then
        return 0
    else
        return 1
    fi
}

# Function to build plugin
build_plugin() {
    echo "🏗️  Building plugin..."
    
    # Clean previous build
    [ -f "$PLUGIN_NAME.op" ] && rm "$PLUGIN_NAME.op"
    
    # Build (using compression level 1 to match Openplanet standard)
    zip -1 -r "$PLUGIN_NAME.op" info.toml src/ -x "src/.*" "src/*~"
    
    if [ $? -ne 0 ]; then
        echo "❌ Build failed!"
        exit 1
    fi
    
    echo "✅ Build successful"
}

# Function to deploy plugin
deploy_plugin() {
    if [ ! -d "$TARGET_DIR" ]; then
        echo "❌ Target directory not found: $TARGET_DIR"
        echo "💡 Check your .env file and ensure the path is correct"
        exit 1
    fi
    
    cp "$PLUGIN_NAME.op" "$TARGET_DIR/"
    echo "📦 Plugin deployed"
}

# Function to show deployment info
show_info() {
    echo ""
    echo "🎮 Deployment Complete!"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📁 Plugin Location: $TARGET_DIR/$PLUGIN_NAME.op"
    echo "🎯 Plugin Name: Speed-graph"
    echo "🔧 Version: $(grep 'version' info.toml | cut -d'"' -f2)"
    echo ""
    echo "🎮 Testing Instructions:"
    echo "1. Launch Trackmania"
    echo "2. Press F3 to open Openplanet overlay"
    echo "3. Go to Developer menu"
    echo "4. Enable 'Developer Mode' if not already enabled"
    echo "5. Look for 'Speed-graph' in the plugin list"
    echo "6. Load the plugin (box icon = from .op file)"
    echo ""
    if check_trackmania; then
        echo "✅ Trackmania is currently running"
    else
        echo "⚠️  Trackmania is not running"
    fi
}

# Main execution
echo "🚀 Starting automated deployment for Speed-graph plugin..."
build_plugin
deploy_plugin
show_info 