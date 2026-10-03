# ResQ data notice

ResQ stores account and onboarding details, chosen home region, Family Circle
membership, check-ins, SOS records, reports, notification inbox items, and
assistant conversations in Firebase. Location is used for nearby places, a
requested SOS, and location sharing when you choose those actions. AI receives
the question you send and only the categories you enable in Privacy settings.
The operator chooses one backend AI provider; its key is never included in the
app. Device speech recognition and speech output may use services supplied by
the phone's operating system.

Reports remain private until a moderator approves a separately written public
summary. Uploaded photos are re-encoded to remove metadata, stored privately
in Cloudinary, and screened before moderators can view them. Photo access ends
30 days after upload. Operator-triggered maintenance deletes the Cloudinary asset and retries
failed deletions; a late or failed job is visible to the operator. Public
summaries contain only a coarse location and no report photo.

AI has daily per-user and hashed guest-IP allowances. Usage counters older
than 35 days are deleted by manual maintenance. Assistant conversations stay in
the account until deletion. Self-service account deletion first deletes report
photos, then removes private records and public contributions, and finally
deletes the Firebase Auth account. If remote photo deletion fails, the account
remains available so the request can be retried.

Firebase, Cloudinary, Vercel, GitHub Actions, and the selected AI provider
process the data needed for their roles. ResQ does not promise continuous
digital emergency delivery. For a privacy problem, open an issue in the
[project repository](https://github.com/Vaibhavsh0120/resq/issues) without
posting personal, medical, or location details.
