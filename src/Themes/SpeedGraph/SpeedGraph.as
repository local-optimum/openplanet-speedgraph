class SpeedDataPoint {
    float timestamp;
    float speed;
    int gear;
    float rpm;  // Add RPM to data points
}

class SpeedGraphGauge : Gauge {
    array<SpeedDataPoint> m_dataPoints;
    float m_lastUpdateTime = 0.0f;
    
    // Graph dimensions
    vec2 m_graphSize;
    vec2 m_graphPos;
    
    // Fonts for display
    nvg::Font m_valueFont;
    nvg::Font m_labelFont;
    
    SpeedGraphGauge() {
        super();
        // Load fonts - Light Italic for values, Demi Bold for labels
        m_valueFont = nvg::LoadFont("src/Fonts/Oswald-Light-Italic.ttf");
        m_labelFont = nvg::LoadFont("src/Fonts/Oswald-Demi-Bold-Italic.ttf");
    }
    
    void InternalRender(CSceneVehicleVisState@ vis) override {
        // Get speed and gear data first (same as base class)
        if (PluginSettings::ShowVelocity) {
            m_speed = vis.WorldVel.Length() * 3.6f;
        } else {
            m_speed = vis.FrontSpeed * 3.6f;
        }
        m_rpm = VehicleState::GetRPM(vis);
        m_gear = vis.CurGear;
        if (vis.CurGear == 0)
            m_gear = -1;
        
        // Update data points
        float currentTime = Time::Now / 1000.0f; // Convert to seconds
        if (currentTime - m_lastUpdateTime >= SpeedGraphSettings::UpdateInterval) {
            AddDataPoint(currentTime, m_speed, m_gear);
            m_lastUpdateTime = currentTime;
        }
        
        // Clean old data points
        CleanOldDataPoints(currentTime);
        
        // Handle positioning and rendering (same as base class)
        vec2 screenSize = vec2(Draw::GetWidth(), Draw::GetHeight());
        m_resPos = m_pos * (screenSize - m_size);
        m_center = vec2(m_size.x * 0.5f, m_size.y * 0.5f);
        nvg::Translate(m_resPos.x, m_resPos.y);
        Render();
        nvg::ResetTransform();
    }
    
    void Render() override {
        // Calculate graph dimensions within the positioned container
        m_graphPos = vec2(SpeedGraphSettings::GraphPadding, SpeedGraphSettings::GraphPadding);
        m_graphSize = vec2(m_size.x - 2 * SpeedGraphSettings::GraphPadding, m_size.y - 2 * SpeedGraphSettings::GraphPadding);
        
        // Render the graph
        RenderGraph();
    }
    
    void AddDataPoint(float timestamp, float speed, int gear) {
        SpeedDataPoint point;
        point.timestamp = timestamp;
        point.speed = speed;
        point.gear = gear;
        point.rpm = m_rpm;  // Store RPM with each data point
        m_dataPoints.InsertLast(point);
    }
    
    void CleanOldDataPoints(float currentTime) {
        float cutoffTime = currentTime - SpeedGraphSettings::TimeWindow;
        
        // Remove old data points
        for (int i = m_dataPoints.Length - 1; i >= 0; i--) {
            if (m_dataPoints[i].timestamp < cutoffTime) {
                m_dataPoints.RemoveAt(i);
            } else {
                break; // Since data is chronological, we can break early
            }
        }
    }
    
    void RenderGraph() {
        if (m_dataPoints.Length < 2) return;
        
        // Calculate time range
        float currentTime = Time::Now / 1000.0f;
        float startTime = currentTime - SpeedGraphSettings::TimeWindow;
        float endTime = currentTime;
        
        // Find speed range for scaling
        float minSpeed = 0.0f;
        float maxSpeed = SpeedGraphSettings::MaxSpeed;
        
        for (uint i = 0; i < m_dataPoints.Length; i++) {
            if (m_dataPoints[i].speed > maxSpeed) {
                maxSpeed = m_dataPoints[i].speed;
            }
        }
        
        // Add some padding to max speed
        maxSpeed += 20.0f;
        
        // Render background
        RenderBackground();
        
        // Render grid
        if (SpeedGraphSettings::ShowGrid) {
            RenderGrid(minSpeed, maxSpeed);
        }
        
        // Render gear graph first (so speed/rpm graphs appear on top)
        if (SpeedGraphSettings::ShowGearGraph) {
            RenderGearGraph(startTime, endTime);
        }

        // Render RPM graph
        if (SpeedGraphSettings::ShowRPMGraph) {
            RenderRPMGraph(startTime, endTime);
        }
        
        // Render speed graph last (on top)
        if (SpeedGraphSettings::ShowSpeedGraph) {
            RenderSpeedGraph(startTime, endTime, minSpeed, maxSpeed);
        }
        
        // Render current values
        if (SpeedGraphSettings::ShowCurrentValues) {
            RenderCurrentValues();
        }
    }
    
    void RenderBackground() override {
        nvg::BeginPath();
        nvg::Rect(m_graphPos, m_graphSize);
        nvg::FillColor(SpeedGraphSettings::BackgroundColor);
        nvg::Fill();
        nvg::ClosePath();
    }
    
    void RenderGrid(float minSpeed, float maxSpeed) {
        // Set clipping region to prevent drawing outside graph area
        nvg::Scissor(m_graphPos.x, m_graphPos.y, m_graphSize.x, m_graphSize.y);
        
        nvg::BeginPath();
        nvg::StrokeColor(SpeedGraphSettings::GridColor);
        nvg::StrokeWidth(SpeedGraphSettings::GridLineWidth);
        
        // Horizontal grid lines (speed)
        int numHorizontalLines = 5;
        for (int i = 0; i <= numHorizontalLines; i++) {
            float y = m_graphPos.y + (m_graphSize.y * i) / numHorizontalLines;
            nvg::MoveTo(vec2(m_graphPos.x, y));
            nvg::LineTo(vec2(m_graphPos.x + m_graphSize.x, y));
        }
        
        // Vertical grid lines (time) - now at 1-second intervals
        float currentTime = Time::Now / 1000.0f;
        float startTime = currentTime - SpeedGraphSettings::TimeWindow;
        
        // Find the first whole second after startTime
        float firstLineTime = Math::Ceil(startTime);
        
        // Draw lines for each whole second in the window
        for (float t = firstLineTime; t <= currentTime; t += 1.0f) {
            // Convert time to x coordinate
            float x = m_graphPos.x + ((t - startTime) / SpeedGraphSettings::TimeWindow) * m_graphSize.x;
            
            // Only draw if within graph bounds
            if (x >= m_graphPos.x && x <= m_graphPos.x + m_graphSize.x) {
                nvg::MoveTo(vec2(x, m_graphPos.y));
                nvg::LineTo(vec2(x, m_graphPos.y + m_graphSize.y));
            }
        }
        
        nvg::Stroke();
        nvg::ClosePath();
        
        // Reset clipping
        nvg::ResetScissor();
    }
    
    void RenderSpeedGraph(float startTime, float endTime, float minSpeed, float maxSpeed) {
        if (m_dataPoints.Length < 2) return;
        
        // Set clipping region to prevent drawing outside graph area
        nvg::Scissor(m_graphPos.x, m_graphPos.y, m_graphSize.x, m_graphSize.y);
        
        nvg::BeginPath();
        nvg::StrokeColor(SpeedGraphSettings::SpeedLineColor);
        nvg::StrokeWidth(SpeedGraphSettings::SpeedLineWidth);
        
        bool firstPoint = true;
        for (uint i = 0; i < m_dataPoints.Length; i++) {
            // Only process points within the time window
            if (m_dataPoints[i].timestamp < startTime || m_dataPoints[i].timestamp > endTime) {
                continue;
            }
            
            // Calculate coordinates
            float x = m_graphPos.x + ((m_dataPoints[i].timestamp - startTime) / (endTime - startTime)) * m_graphSize.x;
            float y = m_graphPos.y + m_graphSize.y - ((m_dataPoints[i].speed - minSpeed) / (maxSpeed - minSpeed)) * m_graphSize.y;
            
            // Clamp coordinates to graph bounds
            x = Math::Clamp(x, m_graphPos.x, m_graphPos.x + m_graphSize.x);
            y = Math::Clamp(y, m_graphPos.y, m_graphPos.y + m_graphSize.y);
            
            if (firstPoint) {
                nvg::MoveTo(vec2(x, y));
                firstPoint = false;
            } else {
                nvg::LineTo(vec2(x, y));
            }
        }
        
        nvg::Stroke();
        nvg::ClosePath();
        
        // Reset clipping
        nvg::ResetScissor();
    }

    void RenderRPMGraph(float startTime, float endTime) {
        if (m_dataPoints.Length < 2) return;
        
        // Set clipping region to prevent drawing outside graph area
        nvg::Scissor(m_graphPos.x, m_graphPos.y, m_graphSize.x, m_graphSize.y);
        
        nvg::BeginPath();
        nvg::StrokeColor(SpeedGraphSettings::RPMLineColor);
        nvg::StrokeWidth(SpeedGraphSettings::RPMLineWidth);
        
        bool firstPoint = true;
        float maxRPM = 11000.0f; // Same as in Gauge class
        
        for (uint i = 0; i < m_dataPoints.Length; i++) {
            // Only process points within the time window
            if (m_dataPoints[i].timestamp < startTime || m_dataPoints[i].timestamp > endTime) {
                continue;
            }
            
            // Calculate X coordinate
            float x = m_graphPos.x + ((m_dataPoints[i].timestamp - startTime) / (endTime - startTime)) * m_graphSize.x;
            
            // Clamp X coordinate to graph bounds
            x = Math::Clamp(x, m_graphPos.x, m_graphPos.x + m_graphSize.x);
            
            // Calculate Y coordinate (RPM scaled to graph height)
            float y = m_graphPos.y + m_graphSize.y * (1.0f - (m_dataPoints[i].rpm / maxRPM));
            y = Math::Clamp(y, m_graphPos.y, m_graphPos.y + m_graphSize.y);
            
            if (firstPoint) {
                nvg::MoveTo(vec2(x, y));
                firstPoint = false;
            } else {
                nvg::LineTo(vec2(x, y));
            }
        }
        
        nvg::Stroke();
        nvg::ClosePath();
        
        // Reset clipping
        nvg::ResetScissor();
    }

    void RenderGearGraph(float startTime, float endTime) {
        if (m_dataPoints.Length < 2) return;
        
        // Set clipping region to prevent drawing outside graph area
        nvg::Scissor(m_graphPos.x, m_graphPos.y, m_graphSize.x, m_graphSize.y);
        
        nvg::BeginPath();
        nvg::StrokeColor(SpeedGraphSettings::GearLineColor);
        nvg::StrokeWidth(SpeedGraphSettings::GearLineWidth);
        
        // Use full graph height for gear display, with 5 gear levels (1-5)
        // Each gear maps exactly to a grid line position
        int numHorizontalLines = 5; // Same as in RenderGrid
        
        bool firstPoint = true;
        float lastX = 0, lastY = 0;
        
        for (uint i = 0; i < m_dataPoints.Length; i++) {
            // Only process points within the time window
            if (m_dataPoints[i].timestamp < startTime || m_dataPoints[i].timestamp > endTime) {
                continue;
            }
            
            // Calculate X coordinate
            float x = m_graphPos.x + ((m_dataPoints[i].timestamp - startTime) / (endTime - startTime)) * m_graphSize.x;
            
            // Clamp X coordinate to graph bounds
            x = Math::Clamp(x, m_graphPos.x, m_graphPos.x + m_graphSize.x);
            
            // Map gear to Y coordinate (gear 5 at top grid line, gear 1 at bottom grid line)
            // Treat reverse gear (-1) and neutral (0) as bottom level
            int displayGear = m_dataPoints[i].gear;
            if (displayGear <= 0) displayGear = 1; // Reverse/Neutral map to gear 1 level
            if (displayGear > 5) displayGear = 5; // Cap at gear 5
            
            // Calculate Y coordinate to match grid lines exactly
            // Grid lines are drawn at m_graphPos.y + (m_graphSize.y * i) / numHorizontalLines
            // We want gear 5 at i=0 (top) and gear 1 at i=numHorizontalLines (bottom)
            int gridLineIndex = numHorizontalLines - (displayGear - 1); // Maps gear 1-5 to grid lines 5-1
            float y = m_graphPos.y + (m_graphSize.y * gridLineIndex) / numHorizontalLines;
            
            if (firstPoint) {
                // Start the path at the first point
                nvg::MoveTo(vec2(x, y));
                firstPoint = false;
            } else {
                // Create stepped line: horizontal line to current x, then vertical line to new y
                nvg::LineTo(vec2(x, lastY)); // Horizontal line
                nvg::LineTo(vec2(x, y));     // Vertical line (gear shift)
            }
            
            lastX = x;
            lastY = y;
        }
        
        nvg::Stroke();
        nvg::ClosePath();
        
        // Reset clipping
        nvg::ResetScissor();
    }
    
    void RenderCurrentValues() {
        // Set clipping region to prevent text from drawing outside graph area
        nvg::Scissor(m_graphPos.x, m_graphPos.y, m_graphSize.x, m_graphSize.y);
        
        // Display current speed and gear in the corner
        nvg::BeginPath();
        nvg::TextAlign(nvg::Align::Left);
        
        float labelFontSize = SpeedGraphSettings::FontSize * 0.8f;  // Slightly smaller for labels
        float valueFontSize = SpeedGraphSettings::FontSize * 1.2f;  // Larger for values
        float xPos = m_graphPos.x + 10;
        float yPosSpeed = m_graphPos.y + 30;
        float yPosGear = m_graphPos.y + 60;
        float yPosRPM = m_graphPos.y + 90;  // Add RPM display below gear
        
        // Draw labels with bold font
        nvg::FontFace(m_labelFont);
        nvg::FontSize(labelFontSize);
        nvg::FillColor(SpeedGraphSettings::TextColor);

        // Draw Speed label and underline
        nvg::Text(xPos, yPosSpeed, "SPEED");
        vec2 speedBounds = nvg::TextBounds("SPEED");
        nvg::BeginPath();
        nvg::StrokeWidth(2.0f);
        nvg::StrokeColor(SpeedGraphSettings::SpeedLineColor);
        nvg::MoveTo(vec2(xPos, yPosSpeed + 2));
        nvg::LineTo(vec2(xPos + speedBounds.x, yPosSpeed + 2));
        nvg::Stroke();
        nvg::ClosePath();

        // Draw Gear label and underline
        nvg::Text(xPos, yPosGear, "GEAR");
        vec2 gearBounds = nvg::TextBounds("GEAR");
        nvg::BeginPath();
        nvg::StrokeWidth(2.0f);
        nvg::StrokeColor(SpeedGraphSettings::GearLineColor);
        nvg::MoveTo(vec2(xPos, yPosGear + 2));
        nvg::LineTo(vec2(xPos + gearBounds.x, yPosGear + 2));
        nvg::Stroke();
        nvg::ClosePath();

        // Draw RPM label and underline if enabled
        if (SpeedGraphSettings::ShowRPMGraph) {
            nvg::Text(xPos, yPosRPM, "RPM");
            vec2 rpmBounds = nvg::TextBounds("RPM");
            nvg::BeginPath();
            nvg::StrokeWidth(2.0f);
            nvg::StrokeColor(SpeedGraphSettings::RPMLineColor);
            nvg::MoveTo(vec2(xPos, yPosRPM + 2));
            nvg::LineTo(vec2(xPos + rpmBounds.x, yPosRPM + 2));
            nvg::Stroke();
            nvg::ClosePath();
        }
        
        // Calculate width of labels to offset values
        vec2 speedLabelBounds = nvg::TextBounds("SPEED");
        vec2 gearLabelBounds = nvg::TextBounds("GEAR");
        vec2 rpmLabelBounds = nvg::TextBounds("RPM");
        float labelPadding = 10;  // Add some space between label and value
        
        // Draw values with light font
        nvg::FontFace(m_valueFont);
        nvg::FontSize(valueFontSize);
        
        // Draw speed value
        nvg::FillColor(SpeedGraphSettings::TextColor);
        nvg::Text(xPos + speedLabelBounds.x + labelPadding, yPosSpeed, Text::Format("%.0f", m_speed));
        
        // Draw gear value with color based on RPM
        string gearText = m_gear == -1 ? "R" : Text::Format("%d", m_gear);
        nvg::FillColor(m_rpm >= 10000 ? SpeedGraphSettings::GearShiftIndicatorColor : SpeedGraphSettings::TextColor);
        nvg::Text(xPos + gearLabelBounds.x + labelPadding, yPosGear, gearText);
        
        // Draw RPM value if RPM graph is enabled
        if (SpeedGraphSettings::ShowRPMGraph) {
            nvg::FillColor(SpeedGraphSettings::TextColor);
            nvg::Text(xPos + rpmLabelBounds.x + labelPadding, yPosRPM, Text::Format("%.0f", m_rpm));
        }
        
        nvg::ClosePath();
        
        // Reset clipping
        nvg::ResetScissor();
    }
    
    void RenderSpeed() override {
        // Speed rendering is handled in RenderGraph
    }
    
    void RenderRPM() override {
        // RPM rendering is handled in RenderGraph (could be added later)
    }
    
    void RenderGear() override {
        // Gear rendering is handled in RenderGraph
    }
    
    void RenderSettingsTab() override {
        if (UI::Button("Reset all settings to default")) {
            SpeedGraphSettings::ResetAllToDefault();
        }
        
        UI::BeginTabBar("SpeedGraph Settings", UI::TabBarFlags::FittingPolicyResizeDown);
        
        if (UI::BeginTabItem("General")) {
            UI::BeginChild("General Settings");
            
            SpeedGraphSettings::TimeWindow = UI::SliderFloat("Time Window (seconds)", SpeedGraphSettings::TimeWindow, 5.0f, 60.0f);
            SpeedGraphSettings::UpdateInterval = UI::SliderFloat("Update Interval (seconds)", SpeedGraphSettings::UpdateInterval, 0.01f, 0.2f);
            SpeedGraphSettings::GraphPadding = UI::SliderFloat("Graph Padding", SpeedGraphSettings::GraphPadding, 10.0f, 50.0f);
            SpeedGraphSettings::MaxSpeed = UI::SliderFloat("Max Speed (km/h)", SpeedGraphSettings::MaxSpeed, 100.0f, 500.0f);
            SpeedGraphSettings::FontSize = UI::SliderFloat("Font Size", SpeedGraphSettings::FontSize, 12.0f, 36.0f);
            
            UI::Separator();
            
            SpeedGraphSettings::ShowGrid = UI::Checkbox("Show Grid", SpeedGraphSettings::ShowGrid);
            SpeedGraphSettings::ShowCurrentValues = UI::Checkbox("Show Current Values", SpeedGraphSettings::ShowCurrentValues);
            SpeedGraphSettings::ShowSpeedGraph = UI::Checkbox("Show Speed Graph", SpeedGraphSettings::ShowSpeedGraph);
            SpeedGraphSettings::ShowGearGraph = UI::Checkbox("Show Gear Graph", SpeedGraphSettings::ShowGearGraph);
            SpeedGraphSettings::ShowRPMGraph = UI::Checkbox("Show RPM Graph", SpeedGraphSettings::ShowRPMGraph);
            
            UI::EndChild();
            UI::EndTabItem();
        }
        
        if (UI::BeginTabItem("Colors")) {
            UI::BeginChild("Color Settings");
            
            SpeedGraphSettings::SpeedLineColor = UI::InputColor4("Speed Line Color", SpeedGraphSettings::SpeedLineColor);
            SpeedGraphSettings::GearLineColor = UI::InputColor4("Gear Line Color", SpeedGraphSettings::GearLineColor);
            SpeedGraphSettings::GridColor = UI::InputColor4("Grid Color", SpeedGraphSettings::GridColor);
            SpeedGraphSettings::BackgroundColor = UI::InputColor4("Background Color", SpeedGraphSettings::BackgroundColor);
            SpeedGraphSettings::TextColor = UI::InputColor4("Text Color", SpeedGraphSettings::TextColor);
            SpeedGraphSettings::RPMLineColor = UI::InputColor4("RPM Line Color", SpeedGraphSettings::RPMLineColor);
            
            UI::EndChild();
            UI::EndTabItem();
        }
        
        if (UI::BeginTabItem("Line Styles")) {
            UI::BeginChild("Line Style Settings");
            
            SpeedGraphSettings::SpeedLineWidth = UI::SliderFloat("Speed Line Width", SpeedGraphSettings::SpeedLineWidth, 1.0f, 5.0f);
            SpeedGraphSettings::GearLineWidth = UI::SliderFloat("Gear Line Width", SpeedGraphSettings::GearLineWidth, 1.0f, 5.0f);
            SpeedGraphSettings::GridLineWidth = UI::SliderFloat("Grid Line Width", SpeedGraphSettings::GridLineWidth, 0.5f, 2.0f);
            SpeedGraphSettings::GearGraphHeightPercent = UI::SliderFloat("Gear Graph Height (%)", SpeedGraphSettings::GearGraphHeightPercent, 0.1f, 0.5f);
            SpeedGraphSettings::RPMLineWidth = UI::SliderFloat("RPM Line Width", SpeedGraphSettings::RPMLineWidth, 1.0f, 5.0f);
            
            UI::EndChild();
            UI::EndTabItem();
        }
        
        UI::EndTabBar();
    }
} 