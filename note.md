# Encrypted secrets with age

Plaintext secrets must never be pushed to GitHub. Encrypt them with age first,
then commit only the `.age` file.

## Public recipient

This key is public and safe to store in the repository:

```text
age19ml0m6z9prakmc2jfhtpu4d8gn8kyn7t3g2td79gl30l7cs97qsqspu45g
```

The private identity is stored locally at:

```text
D:\Dev\Secrets\age\master-age-key.txt
```

Never commit or share the private identity. Back it up securely—encrypted files
cannot be recovered if it is lost.

## Encrypt `.env`

Run from the project root:

```powershell
age -r $env:AGE_PUBLIC_KEY -o .env.age .env
```

Commit `.env.age`, not `.env`.

## Restore `.env` after cloning

```powershell
age --decrypt `
    -i "D:\Dev\Secrets\age\master-age-key.txt" `
    -o .env `
    .env.age
```

## PowerShell helpers

Add these to your PowerShell profile:

```powershell
$env:AGE_PUBLIC_KEY = "age19ml0m6z9prakmc2jfhtpu4d8gn8kyn7t3g2td79gl30l7cs97qsqspu45g"

function agel {
    if (-not (Test-Path -LiteralPath ".env")) {
        Write-Host "ERROR: .env not found"
        return
    }

    age -r $env:AGE_PUBLIC_KEY -o .env.age .env
    if ($LASTEXITCODE -eq 0) {
        Write-Host "DONE: .env encrypted -> .env.age"
    }
}

function ageu {
    if (-not (Test-Path -LiteralPath ".env.age")) {
        Write-Host "ERROR: .env.age not found"
        return
    }

    age --decrypt `
        -i "D:\Dev\Secrets\age\master-age-key.txt" `
        -o .env `
        .env.age

    if ($LASTEXITCODE -eq 0) {
        Write-Host "DONE: .env restored"
    }
}
```

## What to encrypt

- `.env`
- Service-account/Admin SDK files
- Android release keystores and `key.properties`
- iOS signing certificates and provisioning profiles
- Any future private API credentials

## What not to encrypt

These are public Firebase client configuration files required by the app:

- `android/app/google-services.json`
- `ios/Runner/GoogleService-Info.plist`
- `lib/firebase_options.dart`

Before pushing, run `agel` again whenever `.env` changes. If plaintext credentials
are accidentally committed, rotate them immediately—deleting them in a later
commit does not remove them from Git history.
