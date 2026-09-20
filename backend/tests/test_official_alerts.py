from app.integrations.official_alerts import _imd_severity


def test_imd_warning_scale_does_not_treat_green_as_critical() -> None:
    assert _imd_severity("1") == "info"
    assert _imd_severity("2") == "info"
    assert _imd_severity("3") == "warning"
    assert _imd_severity("4") == "critical"
