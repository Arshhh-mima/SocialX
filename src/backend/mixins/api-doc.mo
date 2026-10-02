/// Public API documentation for the MicroBlog backend.
///
/// This mixin exposes a single static `getApiDoc` query. It reads no actor
/// state, so it takes no parameters and is safe to call anonymously.
mixin () {
  /// Return the backend's public API documentation as Markdown.
  public query func getApiDoc() : async Text {
    "# MicroBlog Backend API\n" #
    "\n" #
    "MicroBlog is a small social network: users create profiles, publish short\n" #
    "posts (with optional media), reply, repost, quote, like, follow, block, mute,\n" #
    "and exchange direct messages. This document describes the public Candid API\n" #
    "exposed by the backend canister.\n" #
    "\n" #
    "## Authentication and identity\n" #
    "\n" #
    "Every method that reads or writes user-specific data requires a **signed-in\n" #
    "(non-anonymous) caller**. Anonymous callers are rejected with a trap whose\n" #
    "message is `Not authenticated` on the guarded methods listed below. Public\n" #
    "read-only feeds (`getGlobalFeed`, `getPost`, `getPostsByUser`,\n" #
    "`getPostsByUsername`, `getPostsByHashtag`, `getReplies`, `searchPosts`,\n" #
    "`searchUsers`, `getTrendingHashtags`, `getUserProfile`,\n" #
    "`getProfileByUsername`, `getFollowers`, `getFollowing`,\n" #
    "`checkUsernameAvailability`, `getPrincipalByUsername`) accept anonymous\n" #
    "callers and return a reduced view (no per-caller flags such as\n" #
    "`isLikedByCurrentUser`).\n" #
    "\n" #
    "The app's frontend pins an Internet Identity **derivation origin**, published\n" #
    "at `/.well-known/ii-derivation-origin` when available. An agent that already\n" #
    "holds the user's Internet Identity authorization derives the correct per-app\n" #
    "principal against that origin (for example\n" #
    "`icp identity link web <name> --app <host>`). Such a delegation acts with the\n" #
    "user's full authority in this app until it expires.\n" #
    "\n" #
    "There is no separate registration step for the API: a caller becomes a known\n" #
    "user by calling `setProfile`. Until then, methods that require a profile trap\n" #
    "with `Must create profile first` (or `Must create profile before posting`,\n" #
    "`Must create profile before replying`, `Must create profile before reposting`,\n" #
    "`Must create profile before quoting`). A principal that never signed in\n" #
    "through the app's own frontend is unknown to the backend even if it belongs to\n" #
    "the app's owner, and a signed-in caller derived against a different origin is a\n" #
    "different principal than the one the frontend registered.\n" #
    "\n" #
    "## Units and encodings\n" #
    "\n" #
    "- **Timestamps** (`createdAt`, `updatedAt`, `editedAt`, `lastMessageAt`) are\n" #
    "  `Time.Time` = `Int`, nanoseconds since the Unix epoch (IC time).\n" #
    "- **Principals** are Candid `principal` values; usernames are matched\n" #
    "  case-insensitively and stored lowercased.\n" #
    "- **Media** is referenced by `Storage.ExternalBlob` handles, not inline bytes.\n" #
    "  `mediaType` is `\"image\"` or `\"video\"` and must be present exactly when\n" #
    "  `mediaHash` is present.\n" #
    "- **Conversation ids** are `Text` of the form `<principalA>:<principalB>`,\n" #
    "  with the two principals ordered by principal comparison so a pair always\n" #
    "  maps to one conversation.\n" #
    "- **Optional values** are Candid `opt`; `null` means absent.\n" #
    "- **Post types** are the variant `#original`, `#reply(Nat)`, `#repost(Nat)`,\n" #
    "  `#quote(Nat)`, where the payload is the related post id.\n" #
    "\n" #
    "## Lifecycle and polling\n" #
    "\n" #
    "- Feeds and message history are **cursor-paginated**. Pass the returned\n" #
    "  `nextCursor` (or `nextOffset`) as the next request's cursor; `hasMore`\n" #
    "  indicates whether another page exists. A `null` cursor means \"start from the\n" #
    "  newest item\".\n" #
    "- `getMessages` returns messages **newest first**; `before` is an exclusive\n" #
    "  cursor on message id, and `nextCursor` is the id to pass as `before` for the\n" #
    "  next (older) page.\n" #
    "- `getConversations` returns the caller's inbox, most recent message first.\n" #
    "- `getUnreadMessageCount` and `getUnreadNotificationCount` are cheap polling\n" #
    "  endpoints for badge counts.\n" #
    "- `getMutualFollowStatus(other)` reports whether the caller and `other` follow\n" #
    "  each other, plus each direction, so the UI can decide whether to show the\n" #
    "  Message button.\n" #
    "\n" #
    "## Mutation retry safety\n" #
    "\n" #
    "- `followUser`, `unfollowUser`, `blockUser`, `unblockUser`, `muteUser`,\n" #
    "  `unmuteUser`, `likePost`, `unlikePost`, `markConversationRead`,\n" #
    "  `markNotificationRead`, and `markAllNotificationsRead` are **idempotent**:\n" #
    "  repeating them converges to the same state.\n" #
    "- `sendMessage` is **not idempotent** — each successful call appends a new\n" #
    "  message and increments the recipient's unread count. A retried send after a\n" #
    "  timeout can duplicate the message; the client should reconcile against\n" #
    "  `getMessages`.\n" #
    "- `createPost`, `createReply`, `repostPost`, and `quotePost` each allocate a\n" #
    "  new post id and are **not idempotent**; `repostPost` traps with\n" #
    "  `Already reposted this post` if the caller already reposted that post.\n" #
    "- `deletePost`, `undoRepost`, and `unfollowUser` are destructive and safe to\n" #
    "  repeat (a second call is a no-op or traps on a missing post).\n" #
    "- `editPost` and `deletePost` are only allowed within **15 minutes** of the\n" #
    "  post's `createdAt`; afterwards they trap with\n" #
    "  `Edit window has expired (15 minutes)` / `Delete window has expired (15 minutes)`.\n" #
    "\n" #
    "## Errors, traps, and limits\n" #
    "\n" #
    "Most failures are **traps** (opaque rejects), not typed errors. Notable ones:\n" #
    "\n" #
    "- `Not authenticated` — anonymous caller on a guarded method.\n" #
    "- `Must create profile first` (and the posting/reply/repost/quote variants) —\n" #
    "  caller has no profile.\n" #
    "- `Username is already taken`, `Username must be 3-20 characters, alphanumeric\n" #
    "  and underscores only`, `Display name cannot be empty`,\n" #
    "  `Display name must be 50 characters or fewer`,\n" #
    "  `Bio must be 160 characters or fewer`.\n" #
    "- `Post text must be 280 characters or fewer` (also for replies and quotes),\n" #
    "  `Post must contain text or media`.\n" #
    "- `Cannot edit another user's post`, `Cannot delete another user's post`,\n" #
    "  `Post not found`, `Parent post not found`.\n" #
    "- `Cannot follow yourself`, `Cannot block yourself`, `Cannot mute yourself`,\n" #
    "  `User not found`, `Cannot interact with this user` (blocked in either\n" #
    "  direction).\n" #
    "- `Post limit reached (10000 posts max)` — per-user post cap.\n" #
    "- `mediaType requires mediaHash`, `mediaHash requires mediaType`,\n" #
    "  `mediaType must be \"image\" or \"video\"`.\n" #
    "\n" #
    "`sendMessage` is the exception: it returns a typed\n" #
    "`Result<Message, MessagingError>` so the caller can branch on the reason:\n" #
    "\n" #
    "- `#notMutual` — the caller and recipient do not follow each other.\n" #
    "- `#blocked` — either party has blocked the other.\n" #
    "- `#selfMessage` — the caller tried to message themselves.\n" #
    "- `#emptyMessage` — the message body is empty after trimming.\n" #
    "- `#messageTooLong({ maxLength })` — body exceeds 1000 characters.\n" #
    "- `#recipientNotFound` — the recipient has no profile.\n" #
    "\n" #
    "## Messaging gate (mutual follow)\n" #
    "\n" #
    "Direct messaging is gated on a **mutual follow**: both users must follow each\n" #
    "other. `sendMessage` returns `#notMutual` otherwise, and `getMutualFollowStatus`\n" #
    "lets the UI check before offering the Message button. A block in either\n" #
    "direction takes precedence and yields `#blocked`. Conversations are strictly\n" #
    "one-to-one; there are no group conversations and no message attachments.\n" #
    "\n" #
    "## Non-obvious gotchas\n" #
    "\n" #
    "- `getMessages` returns an empty page (not an error) when the caller does not\n" #
    "  participate in the conversation, so it never leaks another user's thread.\n" #
    "- `getConversations` enriches the other participant's username, display name,\n" #
    "  and profile picture at read time; a deleted or missing profile leaves those\n" #
    "  fields empty.\n" #
    "- `getProfile` returns the caller's own raw profile; `getUserProfile` and\n" #
    "  `getProfileByUsername` return the enriched `UserProfileResponse` with counts\n" #
    "  and per-caller flags.\n" #
    "- `getHomeFeed` falls back to the global feed when the caller follows nobody.\n" #
    "- `getTrendingHashtags` counts only posts from the last 24 hours.\n" #
    "- `searchUsers` and `searchPosts` are case-insensitive substring matches.\n" #
    "- `getApiDoc` is a static document and never reflects runtime state.\n";
  };
};
