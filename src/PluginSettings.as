namespace PluginSettings
{
    [Setting name="Show Telemetry" category="General"]
    bool ShowSpeedGraph = true;

    [Setting name="Hide when not playing" category="General"]
    bool HideWhenNotPlaying = true;

    [Setting name="Hide when interface is hidden" category="General"]
    bool HideWhenNotIFace = false;

    [Setting name="Locator Mode (move telemetry)" category="General"]
    bool LocatorMode = false;

    [Setting name="Position" category="General"]
    vec2 Position = vec2(0.98f, 0.02f);

    [Setting name="Size" category="General"]
    vec2 Size = vec2(400, 250);

    [SettingsTab name="Telemetry Settings"]
    void RenderTelemetrySettingsTab()
    {
        g_dashboard.m_gauge.RenderSettingsTab();
    }
}

namespace SpeedGraphSettings
{
    // === Time & Update Settings ===
    [Setting name="Time Window (seconds)" category="Telemetry" min=5.0 max=60.0]
    float TimeWindow = 10.0f;

    [Setting name="Update Interval (seconds)" category="Telemetry" min=0.01 max=0.2]
    float UpdateInterval = 0.05f;

    // === Display Options ===
    [Setting name="Show Grid" category="Telemetry"]
    bool ShowGrid = true;

    [Setting name="Show Current Values" category="Telemetry"]
    bool ShowCurrentValues = true;

    [Setting name="Show Speed Graph" category="Telemetry"]
    bool ShowSpeedGraph = true;

    [Setting name="Show Gear Graph" category="Telemetry"]
    bool ShowGearGraph = true;

    [Setting name="Show RPM Graph" category="Telemetry"]
    bool ShowRPMGraph = true;

    [Setting name="Show Side Speed Graph" category="Telemetry"]
    bool ShowSideSpeedGraph = true;

    [Setting name="Use velocity instead of speed (useful for ice)" category="Telemetry"]
    bool ShowVelocity = false;

    // === Layout & Dimensions ===
    [Setting name="Graph Padding" category="Telemetry" min=10.0 max=50.0]
    float GraphPadding = 20.0f;

    [Setting name="Max Speed (km/h)" category="Telemetry" min=100.0 max=500.0]
    float MaxSpeed = 300.0f;

    [Setting name="Font Size" category="Telemetry" min=12.0 max=36.0]
    float FontSize = 24.0f;

    [Setting name="Gear Graph Height (% of total)" category="Telemetry" min=0.1 max=1.0]
    float GearGraphHeightPercent = 0.25f;

    [Setting name="RPM Graph Height (% of total)" category="Telemetry" min=0.1 max=1.0]
    float RPMGraphHeightPercent = 0.25f;

    [Setting name="Side Speed Graph Height (% of total)" category="Telemetry" min=0.1 max=1.0]
    float SideSpeedGraphHeightPercent = 0.6f;

    // === Colors ===
    [Setting name="Background Color" category="Telemetry"]
    vec4 BackgroundColor = vec4(0.1f, 0.1f, 0.1f, 0.8f);

    [Setting name="Grid Color" category="Telemetry"]
    vec4 GridColor = vec4(0.3f, 0.3f, 0.3f, 0.5f);

    [Setting name="Text Color" category="Telemetry"]
    vec4 TextColor = vec4(1.0f, 1.0f, 1.0f, 1.0f);

    [Setting name="Speed Line Color" category="Telemetry"]
    vec4 SpeedLineColor = vec4(0.2f, 0.8f, 0.2f, 1.0f);

    [Setting name="Gear Line Color" category="Telemetry"]
    vec4 GearLineColor = vec4(0.6f, 0.8f, 1.0f, 1.0f); // Pale blue color

    [Setting name="RPM Line Color" category="Telemetry"]
    vec4 RPMLineColor = vec4(1.0f, 0.6f, 0.2f, 0.4f); // Low opacity orange for RPM

    [Setting name="Side Speed Line Color" category="Telemetry"]
    vec4 SideSpeedLineColor = vec4(1.0f, 0.7f, 0.8f, 0.6f); // Low opacity pink color

    [Setting name="Gear Shift Indicator Color" category="Telemetry"]
    vec4 GearShiftIndicatorColor = vec4(1.0f, 0.0f, 0.0f, 1.0f); // Red color for gear shift indicator

    // === Line Widths ===
    [Setting name="Grid Line Width" category="Telemetry" min=0.5 max=2.0]
    float GridLineWidth = 1.0f;

    [Setting name="Speed Line Width" category="Telemetry" min=1.0 max=5.0]
    float SpeedLineWidth = 2.0f;

    [Setting name="Gear Line Width" category="Telemetry" min=1.0 max=5.0]
    float GearLineWidth = 2.0f;

    [Setting name="RPM Line Width" category="Telemetry" min=1.0 max=5.0]
    float RPMLineWidth = 1.0f;

    [Setting name="Side Speed Line Width" category="Telemetry" min=1.0 max=5.0]
    float SideSpeedLineWidth = 1.0f;

    void ResetAllToDefault()
    {
        TimeWindow = 10.0f;
        UpdateInterval = 0.05f;
        ShowGrid = true;
        ShowCurrentValues = true;
        ShowSpeedGraph = true;
        ShowGearGraph = true;
        ShowRPMGraph = true;
        ShowSideSpeedGraph = true;
        ShowVelocity = false;
        GraphPadding = 20.0f;
        MaxSpeed = 300.0f;
        FontSize = 24.0f;
        GearGraphHeightPercent = 0.25f;
        RPMGraphHeightPercent = 0.25f;
        SideSpeedGraphHeightPercent = 0.6f;
        BackgroundColor = vec4(0.1f, 0.1f, 0.1f, 0.8f);
        GridColor = vec4(0.3f, 0.3f, 0.3f, 0.5f);
        TextColor = vec4(1.0f, 1.0f, 1.0f, 1.0f);
        SpeedLineColor = vec4(0.2f, 0.8f, 0.2f, 1.0f);
        GearLineColor = vec4(0.6f, 0.8f, 1.0f, 1.0f);
        RPMLineColor = vec4(1.0f, 0.6f, 0.2f, 0.4f);
        SideSpeedLineColor = vec4(1.0f, 0.7f, 0.8f, 0.6f);
        GearShiftIndicatorColor = vec4(1.0f, 0.0f, 0.0f, 1.0f);
        GridLineWidth = 1.0f;
        SpeedLineWidth = 2.0f;
        GearLineWidth = 2.0f;
        RPMLineWidth = 1.0f;
        SideSpeedLineWidth = 1.0f;
    }
} 