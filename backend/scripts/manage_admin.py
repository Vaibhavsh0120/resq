"""Grant or revoke the ResQ moderator claim for a registered Firebase user."""

import argparse

from firebase_admin import auth

from app.integrations.firebase import ensure_firebase


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("uid", help="Existing registered Firebase Auth UID")
    parser.add_argument("action", choices=("grant", "revoke"))
    args = parser.parse_args()
    ensure_firebase()
    user = auth.get_user(args.uid)
    if args.action == "grant" and not (user.email or user.phone_number):
        raise SystemExit("Anonymous accounts cannot receive the admin claim.")
    claims = dict(user.custom_claims or {})
    if args.action == "grant":
        claims["admin"] = True
    else:
        claims.pop("admin", None)
    auth.set_custom_user_claims(args.uid, claims)
    result = "granted" if args.action == "grant" else "revoked"
    print(f"Admin claim {result} for {args.uid}; refresh the user's ID token.")


if __name__ == "__main__":
    main()
