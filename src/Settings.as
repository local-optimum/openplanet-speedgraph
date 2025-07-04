namespace PluginSettings
{
    [Setting name="Show Speed Graph" category="General"]
    bool ShowSpeedometer = true;

    [Setting name="Hide when not playing" category="General"]
    bool HideWhenNotPlaying = true;

    [Setting name="Hide when interface is hidden" category="General"]
    bool HideWhenNotIFace = false;

    [Setting name="Locator Mode (move speed graph)" category="General"]
    bool LocatorMode = false;

    enum Themes {
        Basic,
        BasicDigital,
        TrackmaniaTurbo,
        Ascension2023,
        SpeedGraph
    }

    [Setting name="Theme" category="General"]
    Themes Theme = Themes::SpeedGraph;

    [Setting name="Position" category="General"]
    vec2 Position = vec2(0.98f, 0.02f);

    [Setting name="Size" category="General"]
    vec2 Size = vec2(400, 250);

    [Setting name="Use velocity instead of speed (useful for ice)" category="General"]
    bool ShowVelocity = false;

    [SettingsTab name="Theme Settings"]
    void RenderThemeSettingsTab()
    {
        g_dashboard.m_gauge.RenderSettingsTab();
    }
}