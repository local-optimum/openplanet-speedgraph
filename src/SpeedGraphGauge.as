class SpeedDataPoint {
    float timestamp;
    float speed;
    int gear;
    float rpm;  // Add RPM to data points
    float sideSpeed;  // Add side speed to data points
}

class SpeedGraphGauge {
    // Base gauge properties (from Gauge.as)
    vec2 m_pos;
    vec2 m_size;
    vec2 m_resPos;
    vec2 m_center;
    float m_rpm = 0.0f;
    float m_speed = 0.0f;
    int m_gear = 0;
    float m_minRpm = 200.0f; // Minimal RPM to avoid flickering at engine idle
    float m_maxRpm = 11000.0f;
    
    // SpeedGraph specific properties
    array<SpeedDataPoint> m_dataPoints;
    float m_lastUpdateTime = 0.0f;
    
    // Graph dimensions
    vec2 m_graphSize;
    vec2 m_graphPos;
    
    // Fonts for display
    nvg::Font m_valueFont;
    nvg::Font m_labelFont;
    
    // Smooth scaling animation
    float m_smoothMaxSpeed = 250.0f;
    
    // Current side speed for display
    float m_sideSpeed = 0.0f;
    
    SpeedGraphGauge() {
        // Load fonts - Light Italic for values, Demi Bold for labels
        m_valueFont = nvg::LoadFont("src/Fonts/Oswald-Light-Italic.ttf");
        m_labelFont = nvg::LoadFont("src/Fonts/Oswald-Demi-Bold-Italic.ttf");
    }
    
    void InternalRender(CSceneVehicleVisState@ vis) {
        // Get speed and gear data first (same as base class)
        if (SpeedGraphSettings::ShowVelocity) {
            m_speed = vis.WorldVel.Length() * 3.6f;
        } else {
            m_speed = vis.FrontSpeed * 3.6f;
        }
        m_rpm = VehicleState::GetRPM(vis);
        m_gear = vis.CurGear;
        if (vis.CurGear == 0)
            m_gear = -1;
        
        // Get side speed data
        float sideSpeed = VehicleState::GetSideSpeed(vis);
        m_sideSpeed = sideSpeed;  // Store for display
        
        // Update data points
        float currentTime = Time::Now / 1000.0f; // Convert to seconds
        if (currentTime - m_lastUpdateTime >= SpeedGraphSettings::UpdateInterval) {
            AddDataPoint(currentTime, m_speed, m_gear, sideSpeed);
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
    
    void Render() {
        // Calculate graph dimensions within the positioned container
        m_graphPos = vec2(SpeedGraphSettings::GraphPadding, SpeedGraphSettings::GraphPadding);
        m_graphSize = vec2(m_size.x - 2 * SpeedGraphSettings::GraphPadding, m_size.y - 2 * SpeedGraphSettings::GraphPadding);
        
        // Render the graph
        RenderGraph();
    }
    
    void AddDataPoint(float timestamp, float speed, int gear, float sideSpeed) {
        SpeedDataPoint point;
        point.timestamp = timestamp;
        point.speed = speed;
        point.gear = gear;
        point.rpm = m_rpm;  // Store RPM with each data point
        point.sideSpeed = sideSpeed;  // Store side speed with each data point
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
        
        // Find speed range for scaling - only consider data points in current time window
        float minSpeed = 0.0f;
        float dataMaxSpeed = 0.0f;
        
        for (uint i = 0; i < m_dataPoints.Length; i++) {
            // Only consider data points within the current time window
            if (m_dataPoints[i].timestamp >= startTime && m_dataPoints[i].timestamp <= endTime) {
                if (m_dataPoints[i].speed > dataMaxSpeed) {
                    dataMaxSpeed = m_dataPoints[i].speed;
                }
            }
        }
        
        // Scale up when speed gets within 50 of current scale maximum
        // This provides visual headroom instead of waiting for speed to exceed the scale
        float scaleBuffer = 50.0f;
        float requiredMax = dataMaxSpeed + scaleBuffer;
        
        // Round up to nearest 50 increment so grid lines align with meaningful values
        // Ensure minimum of 250 for default range (0, 50, 100, 150, 200, 250)
        float targetMaxSpeed = Math::Max(250.0f, Math::Ceil(requiredMax / 50.0f) * 50.0f);
        
        // Smooth animation: gradually transition to new scale instead of jumping
        // Use faster lerp speed for zooming in (decreasing scale) than zooming out
        float lerpSpeed = (targetMaxSpeed < m_smoothMaxSpeed) ? 0.05f : 0.02f;
        m_smoothMaxSpeed = Math::Lerp(m_smoothMaxSpeed, targetMaxSpeed, lerpSpeed);
        float maxSpeed = m_smoothMaxSpeed;
        
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
        
        // Render side speed graph
        if (SpeedGraphSettings::ShowSideSpeedGraph) {
            RenderSideSpeedGraph(startTime, endTime);
        }
        
        // Render current values
        if (SpeedGraphSettings::ShowCurrentValues) {
            RenderCurrentValues();
        }
    }
    
    void RenderBackground() {
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
        
        // Horizontal grid lines (speed) - always 50 km/h increments
        float speedIncrement = 50.0f;
        int numHorizontalLines = int(Math::Ceil(maxSpeed / speedIncrement));
        
        for (int i = 0; i <= numHorizontalLines; i++) {
            float speedValue = i * speedIncrement;
            
            // Calculate Y position based on speed value
            float y = m_graphPos.y + m_graphSize.y * (1.0f - (speedValue - minSpeed) / (maxSpeed - minSpeed));
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
        
        // Reset clipping before drawing labels to prevent them from being cut off
        nvg::ResetScissor();
        
        // Add speed labels on the right side of horizontal grid lines
        nvg::FontFace(m_labelFont);
        nvg::FontSize(SpeedGraphSettings::FontSize * 0.5f); // Thinner font for labels
        nvg::TextAlign(nvg::Align::Right);
        
        // Draw speed labels with intelligent spacing
        for (int i = 0; i <= numHorizontalLines; i++) {
            float speedValue = i * speedIncrement;
            
            // Also process the exact maxSpeed if it's not already included
            bool isExactMax = false;
            if (i == numHorizontalLines && speedValue < maxSpeed) {
                speedValue = maxSpeed;
                isExactMax = true;
            }
            
            // Calculate Y position (same as gridline)
            float y = m_graphPos.y + m_graphSize.y * (1.0f - (speedValue - minSpeed) / (maxSpeed - minSpeed));
            
            // Draw labels even if gridline is at the exact top edge
            // This ensures top gridline labels appear correctly
            
            // Determine label visibility and alpha
            bool shouldShowLabel = false;
            float alpha = 0.1f;
            
            if (maxSpeed <= 250.0f) {
                // Default view: show all 50 km/h labels
                shouldShowLabel = (int(speedValue) % 50 == 0);
            } else {
                // Zoomed out view: show 100 km/h labels always, fade out 50 km/h sub-labels
                if (int(speedValue) % 100 == 0) {
                    // Major labels (100 km/h increments) - always show
                    shouldShowLabel = true;
                } else if (int(speedValue) % 50 == 0) {
                    // Sub-labels (50 km/h increments) - fade out as we zoom out
                    shouldShowLabel = true;
                    float fadeRange = 50.0f; // Fade over 50 km/h range above 250
                    float fadeProgress = Math::Clamp((maxSpeed - 250.0f) / fadeRange, 0.0f, 1.0f);
                    alpha = 0.1f * (1.0f - fadeProgress);
                }
            }
            
            if (shouldShowLabel && alpha > 0.01f) { // Lower threshold to ensure labels show
                // Only show label if it will be positioned within the graph area
                float labelY = y + 12;
                if (labelY >= m_graphPos.y && labelY <= m_graphPos.y + m_graphSize.y) {
                    vec4 labelColor = vec4(SpeedGraphSettings::TextColor.x, SpeedGraphSettings::TextColor.y, SpeedGraphSettings::TextColor.z, alpha);
                    nvg::FillColor(labelColor);
                    nvg::Text(m_graphPos.x + m_graphSize.x - 5, labelY, Text::Format("%.0f", speedValue));
                }
            }
        }
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
            
            // Calculate Y coordinate (RPM scaled to configured percentage of graph height from bottom)
            float rpmRatio = m_dataPoints[i].rpm / maxRPM; // Maps RPM to 0.0-1.0
            float y = m_graphPos.y + m_graphSize.y * (1.0f - rpmRatio * SpeedGraphSettings::RPMGraphHeightPercent);
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
        
        // Use configurable percentage of graph height for gear display, with 5 gear levels (1-5)
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
            
            // Map gear to Y coordinate using configurable percentage
            // Treat reverse gear (-1) and neutral (0) as bottom level
            int displayGear = m_dataPoints[i].gear;
            if (displayGear <= 0) displayGear = 1; // Reverse/Neutral map to gear 1 level
            if (displayGear > 5) displayGear = 5; // Cap at gear 5
            
            // Calculate Y coordinate using configurable percentage of graph height
            // Gear 1 at bottom, gear 5 at top of the configured percentage area
            float gearRatio = (displayGear - 1) / 4.0f; // Maps gear 1-5 to 0.0-1.0
            float y = m_graphPos.y + m_graphSize.y * (1.0f - gearRatio * SpeedGraphSettings::GearGraphHeightPercent);
            
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

    void RenderSideSpeedGraph(float startTime, float endTime) {
        if (m_dataPoints.Length < 2) return;
        
        // Set clipping region to prevent drawing outside graph area
        nvg::Scissor(m_graphPos.x, m_graphPos.y, m_graphSize.x, m_graphSize.y);
        
        // Find the maximum absolute side speed for scaling
        float maxAbsSideSpeed = 0.0f;
        for (uint i = 0; i < m_dataPoints.Length; i++) {
            if (m_dataPoints[i].timestamp >= startTime && m_dataPoints[i].timestamp <= endTime) {
                float absSideSpeed = Math::Abs(m_dataPoints[i].sideSpeed);
                if (absSideSpeed > maxAbsSideSpeed) {
                    maxAbsSideSpeed = absSideSpeed;
                }
            }
        }
        
        // Ensure minimum range for visibility
        if (maxAbsSideSpeed < 5.0f) {
            maxAbsSideSpeed = 5.0f;
        }
        
        // Calculate the area for side speed graph (centered in configured percentage)
        float sideSpeedAreaHeight = m_graphSize.y * SpeedGraphSettings::SideSpeedGraphHeightPercent;
        float sideSpeedCenterY = m_graphPos.y + (m_graphSize.y - sideSpeedAreaHeight) / 2.0f + sideSpeedAreaHeight / 2.0f;
        
        // Draw zero line (center reference line)
        nvg::BeginPath();
        nvg::StrokeColor(vec4(SpeedGraphSettings::SideSpeedLineColor.x, 
                             SpeedGraphSettings::SideSpeedLineColor.y, 
                             SpeedGraphSettings::SideSpeedLineColor.z, 0.2f)); // Even more transparent for center line
        nvg::StrokeWidth(0.5f);
        nvg::MoveTo(vec2(m_graphPos.x, sideSpeedCenterY));
        nvg::LineTo(vec2(m_graphPos.x + m_graphSize.x, sideSpeedCenterY));
        nvg::Stroke();
        nvg::ClosePath();
        
        // Draw side speed graph
        nvg::BeginPath();
        nvg::StrokeColor(SpeedGraphSettings::SideSpeedLineColor);
        nvg::StrokeWidth(SpeedGraphSettings::SideSpeedLineWidth);
        
        bool firstPoint = true;
        for (uint i = 0; i < m_dataPoints.Length; i++) {
            // Only process points within the time window
            if (m_dataPoints[i].timestamp < startTime || m_dataPoints[i].timestamp > endTime) {
                continue;
            }
            
            // Calculate coordinates
            float x = m_graphPos.x + ((m_dataPoints[i].timestamp - startTime) / (endTime - startTime)) * m_graphSize.x;
            
            // Calculate Y coordinate relative to center line
            // Positive side speed goes up, negative goes down
            float normalizedSideSpeed = m_dataPoints[i].sideSpeed / maxAbsSideSpeed;
            float y = sideSpeedCenterY - normalizedSideSpeed * (sideSpeedAreaHeight / 2.0f);
            
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
        float yPosDrift = m_graphPos.y + 60;  // Drift between Speed and Gear
        float yPosGear = m_graphPos.y + 90;   // Moved down to accommodate drift
        float yPosRPM = m_graphPos.y + 120;   // Moved down to accommodate drift
        
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

        // Draw Drift label and underline
        nvg::Text(xPos, yPosDrift, "DRIFT");
        vec2 driftBounds = nvg::TextBounds("DRIFT");
        nvg::BeginPath();
        nvg::StrokeWidth(2.0f);
        nvg::StrokeColor(SpeedGraphSettings::SideSpeedLineColor);
        nvg::MoveTo(vec2(xPos, yPosDrift + 2));
        nvg::LineTo(vec2(xPos + driftBounds.x, yPosDrift + 2));
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
        vec2 driftLabelBounds = nvg::TextBounds("DRIFT");
        vec2 gearLabelBounds = nvg::TextBounds("GEAR");
        vec2 rpmLabelBounds = nvg::TextBounds("RPM");
        float labelPadding = 10;  // Add some space between label and value
        
        // Draw values with light font
        nvg::FontFace(m_valueFont);
        nvg::FontSize(valueFontSize);
        
        // Draw speed value
        nvg::FillColor(SpeedGraphSettings::TextColor);
        nvg::Text(xPos + speedLabelBounds.x + labelPadding, yPosSpeed, Text::Format("%.0f", m_speed));
        
        // Draw drift value
        nvg::FillColor(SpeedGraphSettings::TextColor);
        nvg::Text(xPos + driftLabelBounds.x + labelPadding, yPosDrift, Text::Format("%.0f", m_sideSpeed));
        
        // Draw gear value with color based on RPM
        string gearText = m_gear == -1 ? "R" : Text::Format("%d", m_gear);
        nvg::FillColor(m_rpm >= 10000 ? SpeedGraphSettings::GearShiftIndicatorColor : SpeedGraphSettings::TextColor);
        nvg::Text(xPos + gearLabelBounds.x + labelPadding, yPosGear + 3, gearText); // Move gear number down by 3px
        
        // Draw RPM bar if RPM graph is enabled
        if (SpeedGraphSettings::ShowRPMGraph) {
            RenderRPMBar(xPos + rpmLabelBounds.x + labelPadding, yPosRPM);
        }
        
        nvg::ClosePath();
        
        // Reset clipping
        nvg::ResetScissor();
    }
    
    void RenderRPMBar(float x, float y) {
        float barWidth = 48.0f; // 60% of original 80px
        float barHeight = 12.0f;
        float barY = y - barHeight * 0.8f; // Move up relative to RPM text label
        
        // Calculate RPM percentage
        float rpmPercentage = Math::Clamp(m_rpm / m_maxRpm, 0.0f, 1.0f);
        float fillWidth = barWidth * rpmPercentage;
        
        // Determine if we should flash red (gear shift indicator)
        bool shouldFlashRed = m_rpm >= 10000; // Same logic as gear text
        
        // Background (empty part of bar)
        nvg::BeginPath();
        nvg::Rect(vec2(x, barY), vec2(barWidth, barHeight));
        nvg::FillColor(vec4(0.1f, 0.1f, 0.1f, 0.8f)); // Dark background
        nvg::Fill();
        nvg::ClosePath();
        
        // Fill (RPM level)
        if (fillWidth > 0) {
            nvg::BeginPath();
            nvg::Rect(vec2(x, barY), vec2(fillWidth, barHeight));
            if (shouldFlashRed) {
                nvg::FillColor(SpeedGraphSettings::GearShiftIndicatorColor); // Red flash
            } else {
                nvg::FillColor(vec4(1.0f, 1.0f, 1.0f, 1.0f)); // White fill
            }
            nvg::Fill();
            nvg::ClosePath();
        }
        
        // White border
        nvg::BeginPath();
        nvg::Rect(vec2(x, barY), vec2(barWidth, barHeight));
        nvg::StrokeColor(vec4(1.0f, 1.0f, 1.0f, 1.0f)); // White border
        nvg::StrokeWidth(1.0f);
        nvg::Stroke();
        nvg::ClosePath();
    }
    
    void RenderSpeed() {
        // Speed rendering is handled in RenderGraph
    }
    
    void RenderRPM() {
        // RPM rendering is handled in RenderGraph (could be added later)
    }
    
    void RenderGear() {
        // Gear rendering is handled in RenderGraph
    }
    
    void RenderSettingsTab() {
        if (UI::Button("Reset all settings to default")) {
            SpeedGraphSettings::ResetAllToDefault();
        }
        
        UI::BeginTabBar("Telemetry Settings", UI::TabBarFlags::FittingPolicyResizeDown);
        
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
            SpeedGraphSettings::ShowSideSpeedGraph = UI::Checkbox("Show Side Speed Graph", SpeedGraphSettings::ShowSideSpeedGraph);
            
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
            SpeedGraphSettings::SideSpeedLineColor = UI::InputColor4("Side Speed Line Color", SpeedGraphSettings::SideSpeedLineColor);
            
            UI::EndChild();
            UI::EndTabItem();
        }
        
        if (UI::BeginTabItem("Line Styles")) {
            UI::BeginChild("Line Style Settings");
            
            SpeedGraphSettings::SpeedLineWidth = UI::SliderFloat("Speed Line Width", SpeedGraphSettings::SpeedLineWidth, 1.0f, 5.0f);
            SpeedGraphSettings::GearLineWidth = UI::SliderFloat("Gear Line Width", SpeedGraphSettings::GearLineWidth, 1.0f, 5.0f);
            SpeedGraphSettings::GridLineWidth = UI::SliderFloat("Grid Line Width", SpeedGraphSettings::GridLineWidth, 0.5f, 2.0f);
            SpeedGraphSettings::GearGraphHeightPercent = UI::SliderFloat("Gear Graph Height (%)", SpeedGraphSettings::GearGraphHeightPercent, 0.1f, 0.5f);
            SpeedGraphSettings::RPMGraphHeightPercent = UI::SliderFloat("RPM Graph Height (%)", SpeedGraphSettings::RPMGraphHeightPercent, 0.1f, 1.0f);
            SpeedGraphSettings::RPMLineWidth = UI::SliderFloat("RPM Line Width", SpeedGraphSettings::RPMLineWidth, 1.0f, 5.0f);
            SpeedGraphSettings::SideSpeedLineWidth = UI::SliderFloat("Side Speed Line Width", SpeedGraphSettings::SideSpeedLineWidth, 1.0f, 5.0f);
            SpeedGraphSettings::SideSpeedGraphHeightPercent = UI::SliderFloat("Side Speed Graph Height (%)", SpeedGraphSettings::SideSpeedGraphHeightPercent, 0.1f, 1.0f);
            
            UI::EndChild();
            UI::EndTabItem();
        }
        
        UI::EndTabBar();
    }
} 