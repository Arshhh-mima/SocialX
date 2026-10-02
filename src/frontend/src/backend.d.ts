import type { Principal } from "@icp-sdk/core/principal";
export interface Some<T> {
    __kind__: "Some";
    value: T;
}
export interface None {
    __kind__: "None";
}
export type Option<T> = Some<T> | None;
import type { ExternalBlob } from "@caffeineai/object-storage";
export type { ExternalBlob } from "@caffeineai/object-storage";
export interface Cell {
    value: Value;
    name: string;
}
export type ConversationId = string;
export interface ConversationSummary {
    otherParticipant: Principal;
    lastMessageAt: Time;
    otherUsername: string;
    lastMessagePreview: string;
    lastMessageFromCaller: boolean;
    conversationId: ConversationId;
    unreadCount: bigint;
    otherDisplayName: string;
    otherProfilePictureHash?: ExternalBlob;
}
export type Error_ = {
    __kind__: "FrontendOriginsNotConfigured";
    FrontendOriginsNotConfigured: null;
} | {
    __kind__: "MixedSsoSources";
    MixedSsoSources: {
        otherKeys: Array<string>;
        ssoKeys: Array<string>;
    };
} | {
    __kind__: "Stale";
    Stale: {
        ageNs: bigint;
    };
} | {
    __kind__: "MalformedCandid";
    MalformedCandid: null;
} | {
    __kind__: "AmbiguousAttribute";
    AmbiguousAttribute: {
        field: string;
        sources: Array<string>;
    };
} | {
    __kind__: "NoAttributes";
    NoAttributes: null;
} | {
    __kind__: "UnknownNonce";
    UnknownNonce: null;
} | {
    __kind__: "UntrustedSsoSource";
    UntrustedSsoSource: {
        domain: string;
    };
} | {
    __kind__: "MissingField";
    MissingField: string;
} | {
    __kind__: "FrontendOriginMismatch";
    FrontendOriginMismatch: {
        got: string;
        expected: Array<string>;
    };
};
export interface FollowUserResponse {
    principal: Principal;
    username: string;
    displayName: string;
    profilePictureHash?: ExternalBlob;
}
export interface Message {
    id: bigint;
    createdAt: Time;
    text: string;
    recipient: Principal;
    sender: Principal;
    conversationId: ConversationId;
}
export type MessagingError = {
    __kind__: "messageTooLong";
    messageTooLong: {
        maxLength: bigint;
    };
} | {
    __kind__: "blocked";
    blocked: null;
} | {
    __kind__: "recipientNotFound";
    recipientNotFound: null;
} | {
    __kind__: "notMutual";
    notMutual: null;
} | {
    __kind__: "selfMessage";
    selfMessage: null;
} | {
    __kind__: "emptyMessage";
    emptyMessage: null;
};
export interface MutualFollowStatus {
    callerFollowsOther: boolean;
    otherFollowsCaller: boolean;
    isMutual: boolean;
}
export interface Notification {
    id: bigint;
    notificationType: NotificationType;
    createdAt: Time;
    isRead: boolean;
    actorUsername: string;
    actorPrincipal: Principal;
}
export type NotificationType = {
    __kind__: "repost";
    repost: bigint;
} | {
    __kind__: "like";
    like: bigint;
} | {
    __kind__: "quote";
    quote: bigint;
} | {
    __kind__: "mention";
    mention: bigint;
} | {
    __kind__: "reply";
    reply: bigint;
} | {
    __kind__: "follow";
    follow: null;
};
export interface PaginatedFollows {
    nextOffset?: bigint;
    hasMore: boolean;
    users: Array<FollowUserResponse>;
}
export interface PaginatedMessages {
    hasMore: boolean;
    messages: Array<Message>;
    nextCursor?: bigint;
}
export interface PaginatedNotifications {
    hasMore: boolean;
    notifications: Array<Notification>;
    nextCursor?: bigint;
}
export interface PaginatedPosts {
    hasMore: boolean;
    posts: Array<PostResponse>;
    nextCursor?: bigint;
}
export interface PostResponse {
    id: bigint;
    postType: PostType;
    authorUsername: string;
    likeCount: bigint;
    isRepostedByCurrentUser: boolean;
    authorProfilePictureHash?: ExternalBlob;
    repostCount: bigint;
    createdAt: Time;
    text: string;
    author: Principal;
    mediaHash?: ExternalBlob;
    replyCount: bigint;
    mediaType?: string;
    editedAt?: Time;
    authorDisplayName: string;
    isLikedByCurrentUser: boolean;
}
export type PostType = {
    __kind__: "repost";
    repost: bigint;
} | {
    __kind__: "quote";
    quote: bigint;
} | {
    __kind__: "original";
    original: null;
} | {
    __kind__: "reply";
    reply: bigint;
};
export type Result = {
    __kind__: "ok";
    ok: Message;
} | {
    __kind__: "err";
    err: MessagingError;
};
export type Result_1 = {
    __kind__: "ok";
    ok: null;
} | {
    __kind__: "err";
    err: Error_;
};
export interface Result__1 {
    hasMore: boolean;
    rows: Array<Array<Cell>>;
}
export type Time = bigint;
export interface TrendingHashtag {
    tag: string;
    count: bigint;
}
export interface UserProfile {
    bio: string;
    username: string;
    displayName: string;
    createdAt: Time;
    updatedAt: Time;
    headerImageHash?: ExternalBlob;
    profilePictureHash?: ExternalBlob;
}
export interface UserProfileResponse {
    bio: string;
    isBlockedByCurrentUser: boolean;
    principal: Principal;
    username: string;
    displayName: string;
    isMutedByCurrentUser: boolean;
    followersCount: bigint;
    createdAt: Time;
    updatedAt: Time;
    headerImageHash?: ExternalBlob;
    followingCount: bigint;
    isFollowedByCurrentUser: boolean;
    profilePictureHash?: ExternalBlob;
    postsCount: bigint;
}
export type Value = {
    __kind__: "int";
    int: bigint;
} | {
    __kind__: "nat";
    nat: bigint;
} | {
    __kind__: "float";
    float: number;
} | {
    __kind__: "bool";
    bool: boolean;
} | {
    __kind__: "null";
    null: null;
} | {
    __kind__: "text";
    text: string;
};
export enum UserRole {
    admin = "admin",
    user = "user",
    guest = "guest"
}
export interface backendInterface {
    assignCallerUserRole(user: Principal, role: UserRole): Promise<void>;
    blockUser(user: Principal): Promise<void>;
    checkUsernameAvailability(username: string): Promise<boolean>;
    createPost(text: string, mediaHash: ExternalBlob | null, mediaType: string | null): Promise<PostResponse>;
    createReply(parentPostId: bigint, text: string, mediaHash: ExternalBlob | null, mediaType: string | null): Promise<PostResponse>;
    deletePost(postId: bigint): Promise<void>;
    editPost(postId: bigint, text: string): Promise<PostResponse>;
    execute(qJson: string): Promise<Result__1>;
    followUser(user: Principal): Promise<void>;
    /**
     * / Return the backend's public API documentation as Markdown.
     */
    getApiDoc(): Promise<string>;
    getCallerUserRole(): Promise<UserRole>;
    /**
     * / List the caller's conversations, most recent message first.
     */
    getConversations(): Promise<Array<ConversationSummary>>;
    getFollowers(username: string, offset: bigint, limit: bigint): Promise<PaginatedFollows>;
    getFollowing(username: string, offset: bigint, limit: bigint): Promise<PaginatedFollows>;
    getGlobalFeed(cursor: bigint | null, limit: bigint): Promise<PaginatedPosts>;
    getHomeFeed(cursor: bigint | null, limit: bigint): Promise<PaginatedPosts>;
    /**
     * / Fetch a page of a conversation's history, newest first. `before` is an
     * / exclusive cursor on message id; `null` starts from the newest message.
     */
    getMessages(conversationId: ConversationId, before: bigint | null, limit: bigint): Promise<PaginatedMessages>;
    /**
     * / Whether the caller and `other` follow each other, so the frontend can
     * / decide whether to show the Message button.
     */
    getMutualFollowStatus(other: Principal): Promise<MutualFollowStatus>;
    getNotifications(cursor: bigint | null, limit: bigint): Promise<PaginatedNotifications>;
    getPost(postId: bigint): Promise<PostResponse | null>;
    getPostsByHashtag(tag: string, cursor: bigint | null, limit: bigint): Promise<PaginatedPosts>;
    getPostsByUser(user: Principal, cursor: bigint | null, limit: bigint): Promise<PaginatedPosts>;
    getPostsByUsername(username: string, cursor: bigint | null, limit: bigint): Promise<PaginatedPosts>;
    getPrincipalByUsername(username: string): Promise<Principal | null>;
    getProfile(): Promise<UserProfile | null>;
    getProfileByUsername(username: string): Promise<UserProfileResponse | null>;
    getReplies(postId: bigint, cursor: bigint | null, limit: bigint): Promise<PaginatedPosts>;
    getTrendingHashtags(limit: bigint): Promise<Array<TrendingHashtag>>;
    /**
     * / Total unread messages across all of the caller's conversations.
     */
    getUnreadMessageCount(): Promise<bigint>;
    getUnreadNotificationCount(): Promise<bigint>;
    getUserProfile(user: Principal): Promise<UserProfileResponse | null>;
    isCallerAdmin(): Promise<boolean>;
    likePost(postId: bigint): Promise<void>;
    markAllNotificationsRead(): Promise<void>;
    /**
     * / Mark a conversation's messages as read for the caller.
     */
    markConversationRead(conversationId: ConversationId): Promise<void>;
    markNotificationRead(notifId: bigint): Promise<void>;
    muteUser(user: Principal): Promise<void>;
    quotePost(postId: bigint, text: string, mediaHash: ExternalBlob | null, mediaType: string | null): Promise<PostResponse>;
    repostPost(postId: bigint): Promise<PostResponse>;
    schema(): Promise<string>;
    searchPosts(searchText: string, cursor: bigint | null, limit: bigint): Promise<PaginatedPosts>;
    searchUsers(searchText: string, limit: bigint): Promise<Array<UserProfileResponse>>;
    /**
     * / Send a direct message to `recipient`. Requires a mutual follow and no
     * / block in either direction. Returns the caller-actionable error otherwise.
     */
    sendMessage(recipient: Principal, text: string): Promise<Result>;
    setProfile(username: string, displayName: string, bio: string): Promise<void>;
    unblockUser(user: Principal): Promise<void>;
    undoRepost(postId: bigint): Promise<void>;
    unfollowUser(user: Principal): Promise<void>;
    unlikePost(postId: bigint): Promise<void>;
    unmuteUser(user: Principal): Promise<void>;
    updateHeaderImage(imageHash: ExternalBlob | null): Promise<void>;
    updateProfilePicture(pictureHash: ExternalBlob | null): Promise<void>;
}
