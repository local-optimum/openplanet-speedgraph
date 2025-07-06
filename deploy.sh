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
    
    # Path to 7-Zip executable (Windows path accessible from WSL)
    SEVENZIP="/mnt/c/Program Files/7-Zip/7z.exe"
    
    # Check if 7-Zip is available
    if [ ! -f "$SEVENZIP" ]; then
        echo "❌ 7-Zip not found at: $SEVENZIP"
        echo "💡 Please ensure 7-Zip is installed at C:\\Program Files\\7-Zip\\7z.exe"
        exit 1
    fi
    
    # Clean previous build
    [ -f "$PLUGIN_NAME.op" ] && rm "$PLUGIN_NAME.op"
    
    # Build using 7-Zip (compression level 1 to match Openplanet standard)
    # -mx1 = compression level 1 (fastest)
    # -tzip = zip format
    # a = add files to archive
    "$SEVENZIP" a -mx1 -tzip "$PLUGIN_NAME.op" info.toml src
    
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
    
    local target_file="$TARGET_DIR/$PLUGIN_NAME.op"
    
    # Check if plugin already exists and remove it
    if [ -f "$target_file" ]; then
        echo "🗑️  Removing existing plugin: $PLUGIN_NAME.op"
        rm "$target_file"
        if [ $? -ne 0 ]; then
            echo "⚠️  Cannot remove existing plugin file (likely in use by Trackmania/Openplanet)"
            echo "💡 Attempting to backup and force deployment..."
            
            # Create backup filename with timestamp
            local backup_file="$target_file.backup.$(date +%Y%m%d_%H%M%S)"
            
            # Try to rename instead of delete
            mv "$target_file" "$backup_file" 2>/dev/null
            if [ $? -ne 0 ]; then
                echo "❌ Cannot backup existing plugin file"
                echo "💡 Please disable the plugin in Trackmania/Openplanet first, then re-run deploy.sh"
                echo "   Or manually remove: $target_file"
                exit 1
            else
                echo "✅ Backed up existing plugin to: $(basename "$backup_file")"
            fi
        fi
    fi
    
    # Deploy new plugin
    cp "$PLUGIN_NAME.op" "$TARGET_DIR/"
    if [ $? -ne 0 ]; then
        echo "❌ Failed to deploy plugin"
        exit 1
    fi
    
    echo "📦 Plugin deployed successfully"
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
    echo "5. Look for 'Telemetry' in the plugin list"
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