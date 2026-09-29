from fastapi import APIRouter, HTTPException

from ...config import get_settings
from ...integrations.firebase import firestore_client
from ...services.account_deletion import delete_account
from ..dependencies import CurrentUser

router = APIRouter(prefix="/account", tags=["account"])


@router.delete("")
async def delete_my_account(user: CurrentUser) -> dict[str, bool]:
    try:
        delete_account(firestore_client(), user.uid, get_settings())
    except Exception as exc:
        raise HTTPException(status_code=503, detail={"code": "account_deletion_retry"}) from exc
    return {"deleted": True}
