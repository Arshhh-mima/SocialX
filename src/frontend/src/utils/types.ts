import type { Principal } from "@icp-sdk/core/principal";
import type { ExternalBlob } from "../backend";

export type PostType =
  | { original: null }
  | { reply: bigint }
  | { repost: bigint }
  | { quote: bigint };

export interface Post {
  id: bigint;
  author: Principal;
  authorUsername: string;
  authorDisplayName: string;
  authorProfilePictureHash?: ExternalBlob;
  text: string;
  mediaHash?: ExternalBlob;
  mediaType?: string;
  postType: PostType;
  createdAt: bigint;
  editedAt?: bigint;
  likeCount: bigint;
  replyCount: bigint;
  repostCount: bigint;
  isLikedByCurrentUser: boolean;
  isRepostedByCurrentUser: boolean;
}

export interface PaginatedPosts {
  posts: Post[];
  nextCursor?: bigint;
  hasMore: boolean;
}

export interface FollowUserResponse {
  principal: Principal;
  username: string;
  displayName: string;
  profilePictureHash?: ExternalBlob;
}

export interface PaginatedFollows {
  users: FollowUserResponse[];
  nextOffset?: bigint;
  hasMore: boolean;
}

export interface UserProfileResponse {
  principal: Principal;
  username: string;
  displayName: string;
  bio: string;
  profilePictureHash?: ExternalBlob;
  headerImageHash?: ExternalBlob;
  createdAt: bigint;
  updatedAt: bigint;
  followersCount: bigint;
  followingCount: bigint;
  postsCount: bigint;
  isFollowedByCurrentUser: boolean;
  isBlockedByCurrentUser: boolean;
  isMutedByCurrentUser: boolean;
}

export type ConversationId = string;

export interface ConversationSummary {
  conversationId: ConversationId;
  otherParticipant: Principal;
  otherUsername: string;
  otherDisplayName: string;
  otherProfilePictureHash?: ExternalBlob;
  lastMessagePreview: string;
  lastMessageAt: bigint;
  lastMessageFromCaller: boolean;
  unreadCount: bigint;
}

export interface Message {
  id: bigint;
  conversationId: ConversationId;
  sender: Principal;
  recipient: Principal;
  text: string;
  createdAt: bigint;
}

export interface PaginatedMessages {
  messages: Message[];
  nextCursor?: bigint;
  hasMore: boolean;
}

export interface MutualFollowStatus {
  isMutual: boolean;
  callerFollowsOther: boolean;
  otherFollowsCaller: boolean;
}

export type MessagingError =
  | { __kind__: "notMutual"; notMutual: null }
  | { __kind__: "blocked"; blocked: null }
  | { __kind__: "selfMessage"; selfMessage: null }
  | { __kind__: "emptyMessage"; emptyMessage: null }
  | { __kind__: "messageTooLong"; messageTooLong: { maxLength: bigint } }
  | { __kind__: "recipientNotFound"; recipientNotFound: null };
