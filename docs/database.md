# Database documentation

Firestore is organised into these collections. Field names are centralised in
`lib/core/constants/firestore_paths.dart`.

## `users/{uid}`
The shared identity for both roles.
| field | type | notes |
|---|---|---|
| uid, email | string | |
| role | string | `student` \| `startup` \| `admin` |
| displayName, photoUrl | string | mirrored from the role profile |
| fcmToken | string? | for push delivery; nulled on sign-out |
| status | string | `active` \| `suspended` (admin only) |
| createdAt | timestamp | |

## `students/{uid}`
Student profile. Subcollection: `bookmarks/{internshipId}` (snapshot of the
saved internship + `savedAt`). Stores `skillsLower` for search and
`completionPercent`.

## `startups/{uid}`
Startup profile including `verificationStatus`
(`unverified`|`pending`|`verified`|`rejected`) and `documents[]`. The status
field is **not** client-writable except through the verification workflow.

## `internships/{id}`
| field | type | notes |
|---|---|---|
| startupId, startupName, startupLogoUrl | | denormalised for list rendering |
| title, description, responsibilities[], requirements[], skills[] | | |
| skillsLower[] | array | filterable |
| category, department, tags[], workMode, employmentType | | |
| location, durationWeeks, compensation, isPaid, deadline, positions | | |
| status | string | `open` \| `paused` \| `closed` \| `draft` |
| searchTokens[] | array | prefix tokens of title + startup name |
| postedAt, viewsCount, applicantsCount | | counters updated atomically |

## `applications/{internshipId_studentId}`
Deterministic id enforces one application per student per internship. Holds
denormalised student + startup + internship fields, `motivation`, `resumeUrl`,
`coverLetterUrl`, `status`, and an embedded `timeline[]` of
`{status, at}` events. Queried by `studentId` and by `startupId`.

## `conversations/{sortedUidPair}`
`participantIds[]`, `participantNames{}`, `participantPhotos{}`,
`lastMessage`, `lastMessageAt`, `unreadCounts{uid:int}`, `typing{uid:bool}`.
Subcollection `messages/{id}`: `senderId`, `type`
(`text`|`image`|`file`), `text`/`attachmentUrl`/`attachmentName`, `sentAt`,
`readBy[]`.

## `notifications/{id}`
`userId`, `type`, `title`, `body`, `route`, `read`, `createdAt`. Created as a
side effect of the action that triggers them, in the same batch.

## `verificationRequests/{startupId}`
`startupName`, `documents[]`, `note`, `status`, `submittedAt`, and after review
`reason`, `decidedAt`.

## `reports/{id}`, `categories/{id}`, `analytics/{id}`, `activityLogs/{id}`
Admin/moderation surfaces (see admin architecture). `categories` is public-read
/ admin-write.

## Relationships
- `users 1—1 students` / `startups` (same uid).
- `startups 1—* internships` (`startupId`).
- `internships 1—* applications` (`internshipId`); `students 1—* applications`.
- `students *—* internships` via `students/{uid}/bookmarks`.
- `users *—* users` via `conversations` (1:1 threads).

## Indexes
See `firestore.indexes.json` — composite indexes back every filtered/sorted
query (feed by category/workMode/skill/search × postedAt, applications by
student/startup × appliedAt, notifications by user × createdAt/read,
conversations by participant × lastMessageAt).
