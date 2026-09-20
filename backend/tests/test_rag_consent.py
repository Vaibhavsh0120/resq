from app.ai.retrieval.context import (
    filter_authorized_consents,
    filter_profile_context,
    grounded_prompt,
)


def test_sensitive_profile_context_requires_explicit_consent() -> None:
    profile = {
        "personalInfo": {"fullName": "Asha"},
        "medicalInfo": {"allergies": "Penicillin"},
        "homeLocation": {"latitude": 28.61, "longitude": 77.20},
    }

    without_sensitive = filter_profile_context(profile, {"readiness"})
    assert "medical" not in without_sensitive
    assert "precise_location" not in without_sensitive

    with_sensitive = filter_profile_context(
        profile,
        {"medical", "precise_location"},
    )
    assert with_sensitive["medical"]["allergies"] == "Penicillin"
    assert with_sensitive["precise_location"]["latitude"] == 28.61


def test_grounded_prompt_keeps_prior_conversation_context() -> None:
    prompt = grounded_prompt(
        "What should I do next?",
        {"guidance": []},
        [{"role": "user", "text": "There is smoke in the hallway."}],
    )

    assert "There is smoke in the hallway." in prompt
    assert "untrusted data" in prompt


def test_client_cannot_enable_private_rag_categories_without_saved_consent() -> None:
    requested = {"medical", "precise_location", "family"}
    authorized = filter_authorized_consents(
        {"medical": False, "preciseLocation": False, "family": True},
        requested,
    )

    assert authorized == {"family"}
