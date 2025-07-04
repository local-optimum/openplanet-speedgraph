namespace SpeedGraphSettings
{
    [Setting name="Time Window (seconds)" category="SpeedGraph" min=5.0 max=60.0]
    float TimeWindow = 10.0f;

    [Setting name="Update Interval (seconds)" category="SpeedGraph" min=0.01 max=0.2]
    float UpdateInterval = 0.05f;

    [Setting name="Graph Padding" category="SpeedGraph" min=10.0 max=50.0]
    float GraphPadding = 20.0f;

    [Setting name="Speed Line Color" category="SpeedGraph"]
    vec4 SpeedLineColor = vec4(0.2f, 0.8f, 0.2f, 1.0f);

    [Setting name="Gear Line Color" category="SpeedGraph"]
    vec4 GearLineColor = vec4(0.8f, 0.2f, 0.2f, 1.0f);

    [Setting name="Grid Color" category="SpeedGraph"]
    vec4 GridColor = vec4(0.3f, 0.3f, 0.3f, 0.5f);

    [Setting name="Background Color" category="SpeedGraph"]
    vec4 BackgroundColor = vec4(0.1f, 0.1f, 0.1f, 0.8f);

    [Setting name="Text Color" category="SpeedGraph"]
    vec4 TextColor = vec4(1.0f, 1.0f, 1.0f, 1.0f);

    [Setting name="Speed Line Width" category="SpeedGraph" min=1.0 max=5.0]
    float SpeedLineWidth = 2.0f;

    [Setting name="Gear Line Width" category="SpeedGraph" min=1.0 max=5.0]
    float GearLineWidth = 3.0f;

    [Setting name="Grid Line Width" category="SpeedGraph" min=0.5 max=2.0]
    float GridLineWidth = 1.0f;

    [Setting name="Max Speed (km/h)" category="SpeedGraph" min=100.0 max=500.0]
    float MaxSpeed = 300.0f;

    [Setting name="Show Grid" category="SpeedGraph"]
    bool ShowGrid = true;

    [Setting name="Show Current Values" category="SpeedGraph"]
    bool ShowCurrentValues = true;

    [Setting name="Show Speed Graph" category="SpeedGraph"]
    bool ShowSpeedGraph = true;

    [Setting name="Show Gear Graph" category="SpeedGraph"]
    bool ShowGearGraph = true;

    [Setting name="Gear Graph Height (% of total)" category="SpeedGraph" min=0.1 max=0.5]
    float GearGraphHeightPercent = 0.2f;

    [Setting name="Font Size" category="SpeedGraph" min=12.0 max=36.0]
    float FontSize = 24.0f;

    void ResetAllToDefault()
    {
        TimeWindow = 10.0f;
        UpdateInterval = 0.05f;
        GraphPadding = 20.0f;
        SpeedLineColor = vec4(0.2f, 0.8f, 0.2f, 1.0f);
        GearLineColor = vec4(0.8f, 0.2f, 0.2f, 1.0f);
        GridColor = vec4(0.3f, 0.3f, 0.3f, 0.5f);
        BackgroundColor = vec4(0.1f, 0.1f, 0.1f, 0.8f);
        TextColor = vec4(1.0f, 1.0f, 1.0f, 1.0f);
        SpeedLineWidth = 2.0f;
        GearLineWidth = 3.0f;
        GridLineWidth = 1.0f;
        MaxSpeed = 300.0f;
        ShowGrid = true;
        ShowCurrentValues = true;
        ShowSpeedGraph = true;
        ShowGearGraph = true;
        GearGraphHeightPercent = 0.2f;
        FontSize = 24.0f;
    }
} 