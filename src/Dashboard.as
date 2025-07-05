class Dashboard
{
    SpeedGraphGauge@ m_gauge;

    Dashboard()
    {
        InitializeGauge();
    }

    void InitializeGauge()
    {
        @m_gauge = SpeedGraphGauge();
    }

    void Render()
    {
        if (!PluginSettings::ShowSpeedGraph) return;

        if (PluginSettings::HideWhenNotIFace && !UI::IsGameUIVisible()) return;

        auto app = GetApp();

        if (PluginSettings::HideWhenNotPlaying) {
            if (app.CurrentPlayground !is null && (app.CurrentPlayground.UIConfigs.Length > 0)) {
                if (app.CurrentPlayground.UIConfigs[0].UISequence == CGamePlaygroundUIConfig::EUISequence::Intro) {
                    return;
                }
            }
        }

        auto visState = VehicleState::ViewingPlayerState();
        if (visState is null) return;

        m_gauge.m_pos = PluginSettings::Position;
        m_gauge.m_size = PluginSettings::Size;

        m_gauge.InternalRender(visState);
    }
}