import { Principal } from "@icp-sdk/core/principal";
import type { backendInterface } from "../backend";

const caller = Principal.fromText(
  "yizhk-wc2bp-xvmfk-owyqg-xvxkk-2b7ki-cg4ab-2ld2l-c3gzd-bteb4-5qe",
);
const alice = Principal.fromText("aaaaa-aa");
const bob = Principal.fromText("2ibo7-dia");

const now = BigInt(Date.now()) * 1_000_000n;
const minute = 60_000_000_000n;
const hour = 60n * minute;
const day = 24n * hour;

const aliceProfile = {
  principal: alice,
  username: "alice",
  displayName: "Alice Johnson",
  bio: "Coffee, code, and cats.",
  followersCount: 128n,
  followingCount: 96n,
  postsCount: 12n,
  createdAt: now - 400n * day,
  updatedAt: now - 3n * day,
  isFollowedByCurrentUser: true,
  isBlockedByCurrentUser: false,
  isMutedByCurrentUser: false,
};

const bobProfile = {
  principal: bob,
  username: "bob",
  displayName: "Bob Martinez",
  bio: "Building things on the internet.",
  followersCount: 54n,
  followingCount: 61n,
  postsCount: 7n,
  createdAt: now - 300n * day,
  updatedAt: now - 5n * day,
  isFollowedByCurrentUser: true,
  isBlockedByCurrentUser: false,
  isMutedByCurrentUser: false,
};

const conversations = [
  {
    conversationId: "aaaaa-aa:2vxsx-fae",
    otherParticipant: alice,
    otherUsername: "alice",
    otherDisplayName: "Alice Johnson",
    lastMessagePreview: "Sounds good — see you at 6!",
    lastMessageAt: now - 4n * minute,
    lastMessageFromCaller: false,
    unreadCount: 2n,
  },
  {
    conversationId: "2ibo7-dia:2vxsx-fae",
    otherParticipant: bob,
    otherUsername: "bob",
    otherDisplayName: "Bob Martinez",
    lastMessagePreview: "Did you get a chance to look at the draft?",
    lastMessageAt: now - 2n * hour,
    lastMessageFromCaller: true,
    unreadCount: 0n,
  },
];

const aliceMessages = [
  {
    id: 1n,
    conversationId: "aaaaa-aa:2vxsx-fae",
    sender: alice,
    recipient: caller,
    text: "Hey! Are we still on for coffee later?",
    createdAt: now - 3n * hour,
  },
  {
    id: 2n,
    conversationId: "aaaaa-aa:2vxsx-fae",
    sender: caller,
    recipient: alice,
    text: "Yes! How does 6pm at the usual place sound?",
    createdAt: now - 2n * hour,
  },
  {
    id: 3n,
    conversationId: "aaaaa-aa:2vxsx-fae",
    sender: alice,
    recipient: caller,
    text: "Perfect. I'll grab a table by the window.",
    createdAt: now - 30n * minute,
  },
  {
    id: 4n,
    conversationId: "aaaaa-aa:2vxsx-fae",
    sender: alice,
    recipient: caller,
    text: "Sounds good — see you at 6!",
    createdAt: now - 4n * minute,
  },
];

const bobMessages = [
  {
    id: 5n,
    conversationId: "2ibo7-dia:2vxsx-fae",
    sender: caller,
    recipient: bob,
    text: "Did you get a chance to look at the draft?",
    createdAt: now - 2n * hour,
  },
];

export const mockBackend: backendInterface = {
  __accessControlState: async () => ({}),
  __blocks: async () => ({}),
  __conversations: async () => ({}),
  __followers: async () => ({}),
  __following: async () => ({}),
  __hashtagIndex: async () => ({}),
  __messages: async () => ({}),
  __mutes: async () => ({}),
  __nextMessageId: async () => 6n,
  __nextNotificationId: async () => 1n,
  __nextPostId: async () => 5n,
  __postLikes: async () => ({}),
  __postReplies: async () => ({}),
  __postReposts: async () => ({}),
  __posts: async () => ({}),
  __repostIndex: async () => ({}),
  __userNotifications: async () => ({}),
  __userPostCounts: async () => ({}),
  __userProfiles: async () => ({}),
  __usernameToUser: async () => ({}),
  _immutableObjectStorageBlobsAreLive: async (hashes) =>
    hashes.map(() => true),
  _immutableObjectStorageBlobsToDelete: async () => [],
  _immutableObjectStorageConfirmBlobDeletion: async () => undefined,
  _immutableObjectStorageCreateCertificate: async (blobHash) => ({
    method: "GET",
    blob_hash: blobHash,
  }),
  _immutableObjectStorageRefillCashier: async () => ({ success: true }),
  _immutableObjectStorageUpdateGatewayPrincipals: async () => undefined,
  _initialize_access_control: async () => undefined,
  _internet_identity_sign_in_finish: async () => ({
    __kind__: "ok",
    ok: null,
  }),
  _internet_identity_sign_in_start: async () => new Uint8Array(),
  assignCallerUserRole: async () => undefined,
  blockUser: async () => undefined,
  checkUsernameAvailability: async () => true,
  createPost: async () => ({
    id: 1n,
    postType: { __kind__: "original", original: null },
    authorUsername: "alice",
    likeCount: 0n,
    isRepostedByCurrentUser: false,
    repostCount: 0n,
    createdAt: now,
    text: "Sample post",
    author: alice,
    replyCount: 0n,
    authorDisplayName: "Alice Johnson",
    isLikedByCurrentUser: false,
  }),
  createReply: async () => ({
    id: 2n,
    postType: { __kind__: "reply", reply: 1n },
    authorUsername: "alice",
    likeCount: 0n,
    isRepostedByCurrentUser: false,
    repostCount: 0n,
    createdAt: now,
    text: "Sample reply",
    author: alice,
    replyCount: 0n,
    authorDisplayName: "Alice Johnson",
    isLikedByCurrentUser: false,
  }),
  deletePost: async () => undefined,
  editPost: async () => ({
    id: 1n,
    postType: { __kind__: "original", original: null },
    authorUsername: "alice",
    likeCount: 0n,
    isRepostedByCurrentUser: false,
    repostCount: 0n,
    createdAt: now,
    text: "Edited post",
    author: alice,
    replyCount: 0n,
    authorDisplayName: "Alice Johnson",
    isLikedByCurrentUser: false,
  }),
  execute: async () => ({ hasMore: false, rows: [] }),
  followUser: async () => undefined,
  getApiDoc: async () => "# API",
  getCallerUserRole: async () => "user" as never,
  getConversations: async () => conversations,
  getFollowers: async () => ({ hasMore: false, users: [] }),
  getFollowing: async () => ({ hasMore: false, users: [] }),
  getGlobalFeed: async () => ({ hasMore: false, posts: [] }),
  getHomeFeed: async () => ({ hasMore: false, posts: [] }),
  getMessages: async (conversationId) => {
    const all =
      conversationId === "aaaaa-aa:2vxsx-fae" ? aliceMessages : bobMessages;
    return { hasMore: false, messages: [...all].reverse() };
  },
  getMutualFollowStatus: async () => ({
    callerFollowsOther: true,
    otherFollowsCaller: true,
    isMutual: true,
  }),
  getNotifications: async () => ({ hasMore: false, notifications: [] }),
  getPost: async () => null,
  getPostsByHashtag: async () => ({ hasMore: false, posts: [] }),
  getPostsByUser: async () => ({ hasMore: false, posts: [] }),
  getPostsByUsername: async () => ({ hasMore: false, posts: [] }),
  getPrincipalByUsername: async (username) =>
    username.toLowerCase() === "alice"
      ? alice
      : username.toLowerCase() === "bob"
        ? bob
        : null,
  getProfile: async () => ({
    username: "you",
    displayName: "You",
    bio: "This is your profile.",
    createdAt: now - 200n * day,
    updatedAt: now,
  }),
  getProfileByUsername: async (username) => {
    const lower = username.toLowerCase();
    if (lower === "alice") return aliceProfile;
    if (lower === "bob") return bobProfile;
    return null;
  },
  getReplies: async () => ({ hasMore: false, posts: [] }),
  getTrendingHashtags: async () => [],
  getUnreadMessageCount: async () => 2n,
  getUnreadNotificationCount: async () => 0n,
  getUserProfile: async () => aliceProfile,
  isCallerAdmin: async () => false,
  likePost: async () => undefined,
  markAllNotificationsRead: async () => undefined,
  markConversationRead: async () => undefined,
  markNotificationRead: async () => undefined,
  muteUser: async () => undefined,
  quotePost: async () => ({
    id: 3n,
    postType: { __kind__: "quote", quote: 1n },
    authorUsername: "alice",
    likeCount: 0n,
    isRepostedByCurrentUser: false,
    repostCount: 0n,
    createdAt: now,
    text: "Sample quote",
    author: alice,
    replyCount: 0n,
    authorDisplayName: "Alice Johnson",
    isLikedByCurrentUser: false,
  }),
  repostPost: async () => ({
    id: 4n,
    postType: { __kind__: "repost", repost: 1n },
    authorUsername: "alice",
    likeCount: 0n,
    isRepostedByCurrentUser: true,
    repostCount: 1n,
    createdAt: now,
    text: "",
    author: alice,
    replyCount: 0n,
    authorDisplayName: "Alice Johnson",
    isLikedByCurrentUser: false,
  }),
  schema: async () => "{}",
  searchPosts: async () => ({ hasMore: false, posts: [] }),
  searchUsers: async () => [aliceProfile, bobProfile],
  sendMessage: async (recipient, text) => ({
    __kind__: "ok",
    ok: {
      id: BigInt(Date.now()),
      createdAt: BigInt(Date.now()) * 1_000_000n,
      text,
      recipient,
      sender: caller,
      conversationId: "",
    },
  }),
  setProfile: async () => undefined,
  unblockUser: async () => undefined,
  undoRepost: async () => undefined,
  unfollowUser: async () => undefined,
  unlikePost: async () => undefined,
  unmuteUser: async () => undefined,
  updateHeaderImage: async () => undefined,
  updateProfilePicture: async () => undefined,
};
