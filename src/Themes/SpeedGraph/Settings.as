namespace SpeedGraphSettings
{
    // === Time & Update Settings ===
    [Setting name="Time Window (seconds)" category="SpeedGraph" min=5.0 max=60.0]
    float TimeWindow = 10.0f;

    [Setting name="Update Interval (seconds)" category="SpeedGraph" min=0.01 max=0.2]
    float UpdateInterval = 0.05f;

    // === Display Options ===
    [Setting name="Show Grid" category="SpeedGraph"]
    bool ShowGrid = true;

    [Setting name="Show Current Values" category="SpeedGraph"]
    bool ShowCurrentValues = true;

    [Setting name="Show Speed Graph" category="SpeedGraph"]
    bool ShowSpeedGraph = true;

    [Setting name="Show Gear Graph" category="SpeedGraph"]
    bool ShowGearGraph = true;

    [Setting name="Show RPM Graph" category="SpeedGraph"]
    bool ShowRPMGraph = true;

    [Setting name="Show Side Speed Graph" category="SpeedGraph"]
    bool ShowSideSpeedGraph = true;

    // === Layout & Dimensions ===
    [Setting name="Graph Padding" category="SpeedGraph" min=10.0 max=50.0]
    float GraphPadding = 20.0f;

    [Setting name="Max Speed (km/h)" category="SpeedGraph" min=100.0 max=500.0]
    float MaxSpeed = 300.0f;

    [Setting name="Font Size" category="SpeedGraph" min=12.0 max=36.0]
    float FontSize = 24.0f;

    [Setting name="Gear Graph Height (% of total)" category="SpeedGraph" min=0.1 max=1.0]
    float GearGraphHeightPercent = 0.4f;

    [Setting name="RPM Graph Height (% of total)" category="SpeedGraph" min=0.1 max=1.0]
    float RPMGraphHeightPercent = 0.4f;

    [Setting name="Side Speed Graph Height (% of total)" category="SpeedGraph" min=0.1 max=1.0]
    float SideSpeedGraphHeightPercent = 0.6f;

    // === Colors ===
    [Setting name="Background Color" category="SpeedGraph"]
    vec4 BackgroundColor = vec4(0.1f, 0.1f, 0.1f, 0.8f);

    [Setting name="Grid Color" category="SpeedGraph"]
    vec4 GridColor = vec4(0.3f, 0.3f, 0.3f, 0.5f);

    [Setting name="Text Color" category="SpeedGraph"]
    vec4 TextColor = vec4(1.0f, 1.0f, 1.0f, 1.0f);

    [Setting name="Speed Line Color" category="SpeedGraph"]
    vec4 SpeedLineColor = vec4(0.2f, 0.8f, 0.2f, 1.0f);

    [Setting name="Gear Line Color" category="SpeedGraph"]
    vec4 GearLineColor = vec4(0.6f, 0.8f, 1.0f, 1.0f); // Pale blue color

    [Setting name="RPM Line Color" category="SpeedGraph"]
    vec4 RPMLineColor = vec4(1.0f, 0.6f, 0.2f, 0.4f); // Low opacity orange for RPM

    [Setting name="Side Speed Line Color" category="SpeedGraph"]
    vec4 SideSpeedLineColor = vec4(1.0f, 0.7f, 0.8f, 0.6f); // Low opacity pink color

    [Setting name="Gear Shift Indicator Color" category="SpeedGraph"]
    vec4 GearShiftIndicatorColor = vec4(1.0f, 0.0f, 0.0f, 1.0f); // Red color for gear shift indicator

    // === Line Widths ===
    [Setting name="Grid Line Width" category="SpeedGraph" min=0.5 max=2.0]
    float GridLineWidth = 1.0f;

    [Setting name="Speed Line Width" category="SpeedGraph" min=1.0 max=5.0]
    float SpeedLineWidth = 2.0f;

    [Setting name="Gear Line Width" category="SpeedGraph" min=1.0 max=5.0]
    float GearLineWidth = 2.0f;

    [Setting name="RPM Line Width" category="SpeedGraph" min=1.0 max=5.0]
    float RPMLineWidth = 1.0f;

    [Setting name="Side Speed Line Width" category="SpeedGraph" min=1.0 max=5.0]
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
        GraphPadding = 20.0f;
        MaxSpeed = 300.0f;
        FontSize = 24.0f;
        GearGraphHeightPercent = 0.4f;
        RPMGraphHeightPercent = 0.4f;
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