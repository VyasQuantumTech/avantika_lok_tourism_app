# OTP, images and provider-operated transport fixes

Provider identities remain pooja → `pandit`, accommodation → `hotel_manager`, transport → `vehicle_owner`.

- OTP/text dialogs own their controllers until their route has unmounted. Start/end OTP validation, incorrect codes, time-window errors and network errors stay in the dialog for retry. Unexpected widget errors use a neutral fallback while normal Flutter error reporting remains enabled.
- Booking views hydrate a public service photo from linked pooja, room/property or vehicle media, even when a saved service summary exists. Private, deleted and non-image media are excluded. Names/pricing snapshots are preserved. Mobile and admin cards display these URLs; pooja media paths resolve against the API origin.
- Approved vehicle owners operate rides directly. No additional driver account, driver online toggle or assignment is required. Arrival and verified OTP start create a provider-operated trip record with a nullable legacy driver reference. Completion/cancellation releases it. Current KYC, suspension, ownership, vehicle documents and the start/completion OTP gates remain enforced. An owner cannot start another trip while one is in progress.
- Historical driver records and legacy endpoints are retained for older clients and active historical rides. Current mobile screens no longer register/select/assign drivers. Tracking still supports provider arrival and location.

## Rollout

Apply backend migration `20261014000100-provider-operated-transport.js` before starting the new API. It makes `driver_id` nullable on trip assignments and locations; it deletes no existing driver/trip data. Roll back the application separately: the migration refuses to restore mandatory driver references when provider-operated trips already exist.

Mobile fixes are applied both to the main mobile checkout and this chat's worktree. Backend/admin edits are in their main checkouts. Deploy backend and admin and rebuild/restart mobile together; local source fixes do not change the running remote API or an already installed APK.

## Verification

The database suites use a separately created temporary PostgreSQL database. Tests cover direct provider start/completion, invalid OTPs, approved KYC, arrival without assignment, operator tracking, legacy compatibility, and public-only booking images for all services. Mobile tests cover dialog validation, backend rejection/retry, closing animations and cancellation, provider order images, and absence of assignment controls.
