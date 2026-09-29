from typing import Annotated

import secrets

from fastapi import Depends, Header, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from firebase_admin import auth

from ..domain.models import UserContext
from ..integrations.firebase import ensure_firebase
from ..config import get_settings

bearer = HTTPBearer(auto_error=True)


async def current_user(
    credentials: Annotated[HTTPAuthorizationCredentials, Depends(bearer)],
) -> UserContext:
    try:
        ensure_firebase()
        decoded = auth.verify_id_token(credentials.credentials, check_revoked=True)
        return UserContext(
            uid=decoded["uid"],
            is_anonymous=decoded.get("firebase", {}).get("sign_in_provider") == "anonymous",
            email=decoded.get("email"),
            phone_number=decoded.get("phone_number"),
        )
    except Exception as exc:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail={"code": "invalid_auth_token", "message": "Authentication is required."},
        ) from exc


CurrentUser = Annotated[UserContext, Depends(current_user)]


async def require_admin(
    x_admin_key: Annotated[str | None, Header()] = None,
    authorization: Annotated[str | None, Header()] = None,
) -> str:
    expected = get_settings().admin_api_key
    if expected and x_admin_key and secrets.compare_digest(expected, x_admin_key):
        return "scheduled-job"
    if authorization and authorization.startswith("Bearer "):
        try:
            ensure_firebase()
            decoded = auth.verify_id_token(authorization.removeprefix("Bearer "), check_revoked=True)
            if decoded.get("admin") is True and decoded.get("firebase", {}).get("sign_in_provider") != "anonymous":
                return decoded["uid"]
        except Exception:
            pass
    raise HTTPException(
        status_code=status.HTTP_403_FORBIDDEN,
        detail={"code": "admin_required"},
    )


AdminAccess = Annotated[str, Depends(require_admin)]
