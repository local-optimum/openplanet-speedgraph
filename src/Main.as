Dashboard@ g_dashboard;

void Main()
{
    @g_dashboard = Dashboard();
}

#if MP4
void SetSiblings(CGameManialinkControl@ control, bool visible)
{
    if (control is null) return;
    auto siblings = control.Parent.Controls;
    for (uint j = 0; j < siblings.Length; j++) {
        siblings[j].Visible = visible;
    }
}

void SetMP4Speedometer(bool visible)
{
    auto playground = GetApp().PlaygroundScript;
    if (playground !is null) {
        playground.UIManager.UIAll.OverlayHideSpeedAndDist = !visible;
        playground.UIManager.UIAll.OverlayHideGauges = !visible;
    }

    auto network = GetApp().Network;
    if (network is null) return;
    auto pages = network.GetManialinkPages();
    for (uint i = 0; i < pages.Length; i++) {
        auto page = pages[i];
        if (page is null) continue; // quite common when joining servers
        auto frame = pages[i].MainFrame;
        if (network.ClientManiaAppPlayground is null) { // Local
            auto speedometer = frame.GetFirstChild("Frame_Speed");
            if (speedometer !is null) {
                speedometer.Visible = visible;
                break;
            }
        } else { // Online
            SetSiblings(frame.GetFirstChild("Frame_SpeedGauge"), visible); // stock
            SetSiblings(frame.GetFirstChild("QuadTachometer"), visible); // custom on some servers
        }
    }
}
#endif

void Render()
{
#if MP4
    SetMP4Speedometer(false);
#endif
    g_dashboard.Render();
}

void RenderInterface()
{
    if (PluginSettings::LocatorMode) {
        Locator::Render("Telemetry", PluginSettings::Position, PluginSettings::Size);
        PluginSettings::Position = Locator::GetPos();
        PluginSettings::Size = Locator::GetSize();
    }
}

void RenderMenu()
{
    if(UI::MenuItem("\\$fa0" + Icons::BarChart + " \\$zTelemetry", "", PluginSettings::ShowSpeedGraph))
        PluginSettings::ShowSpeedGraph = !PluginSettings::ShowSpeedGraph;
}

void OnSettingsChanged()
{
    g_dashboard.InitializeGauge();
}

void OnDestroyed()
{
#if MP4
    SetMP4Speedometer(true);
#endif
}

void OnDisabled()
{
#if MP4
    SetMP4Speedometer(true);
#endif
}