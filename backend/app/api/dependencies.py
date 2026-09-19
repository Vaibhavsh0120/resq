from typing import Annotated

from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from firebase_admin import auth

from ..domain.models import UserContext
from ..integrations.firebase import ensure_firebase

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
        )
    except Exception as exc:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail={"code": "invalid_auth_token", "message": "Authentication is required."},
        ) from exc


CurrentUser = Annotated[UserContext, Depends(current_user)]
