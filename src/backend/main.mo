import Iter "mo:core/Iter";
import List "mo:core/List";
import Map "mo:core/Map";
import Principal "mo:core/Principal";
import Runtime "mo:core/Runtime";
import Time "mo:core/Time";
import Char "mo:core/Char";
import Int "mo:core/Int";
import Storage "mo:caffeineai-object-storage/Storage";
import MixinObjectStorage "mo:caffeineai-object-storage/Mixin";
import AccessControl "mo:caffeineai-authorization/access-control";
import MixinAuthorization "mo:caffeineai-authorization/MixinAuthorization";
import OQL "mo:caffeineai-oql";
import Expose "mo:caffeineai-oql/Expose";
import Entity "mo:caffeineai-oql/Entity";
import BoolValue "mo:caffeineai-oql/BoolValue";
import IntValue "mo:caffeineai-oql/IntValue";
import NatValue "mo:caffeineai-oql/NatValue";
import PrincipalValue "mo:caffeineai-oql/PrincipalValue";
import RecordValue "mo:caffeineai-oql/RecordValue";
import TextValue "mo:caffeineai-oql/TextValue";
import MessagingTypes "types/messaging";
import MessagingApi "mixins/messaging-api";
import ApiDocMixin "mixins/api-doc";

actor {
  let accessControlState : AccessControl.AccessControlState;
  include MixinAuthorization(accessControlState, null);
  include MixinObjectStorage();

  type UserProfile = {
    username : Text;
    displayName : Text;
    bio : Text;
    profilePictureHash : ?Storage.ExternalBlob;
    headerImageHash : ?Storage.ExternalBlob;
    createdAt : Time.Time;
    updatedAt : Time.Time;
  };

  type PostType = {
    #original;
    #reply : Nat;
    #repost : Nat;
    #quote : Nat;
  };

  type Post = {
    id : Nat;
    author : Principal;
    text : Text;
    mediaHash : ?Storage.ExternalBlob;
    mediaType : ?Text;
    postType : PostType;
    createdAt : Time.Time;
    editedAt : ?Time.Time;
  };

  type PostResponse = {
    id : Nat;
    author : Principal;
    authorUsername : Text;
    authorDisplayName : Text;
    authorProfilePictureHash : ?Storage.ExternalBlob;
    text : Text;
    mediaHash : ?Storage.ExternalBlob;
    mediaType : ?Text;
    postType : PostType;
    createdAt : Time.Time;
    editedAt : ?Time.Time;
    likeCount : Nat;
    replyCount : Nat;
    repostCount : Nat;
    isLikedByCurrentUser : Bool;
    isRepostedByCurrentUser : Bool;
  };

  type PaginatedPosts = {
    posts : [PostResponse];
    nextCursor : ?Nat;
    hasMore : Bool;
  };

  type TrendingHashtag = {
    tag : Text;
    count : Nat;
  };

  type UserProfileResponse = {
    principal : Principal;
    username : Text;
    displayName : Text;
    bio : Text;
    profilePictureHash : ?Storage.ExternalBlob;
    headerImageHash : ?Storage.ExternalBlob;
    createdAt : Time.Time;
    updatedAt : Time.Time;
    followersCount : Nat;
    followingCount : Nat;
    postsCount : Nat;
    isFollowedByCurrentUser : Bool;
    isBlockedByCurrentUser : Bool;
    isMutedByCurrentUser : Bool;
  };

  type FollowUserResponse = {
    principal : Principal;
    username : Text;
    displayName : Text;
    profilePictureHash : ?Storage.ExternalBlob;
  };

  type PaginatedFollows = {
    users : [FollowUserResponse];
    nextOffset : ?Nat;
    hasMore : Bool;
  };

  type NotificationType = {
    #like : Nat;
    #reply : Nat;
    #mention : Nat;
    #follow;
    #repost : Nat;
    #quote : Nat;
  };

  type Notification = {
    id : Nat;
    notificationType : NotificationType;
    actorPrincipal : Principal;
    actorUsername : Text;
    createdAt : Time.Time;
    isRead : Bool;
  };

  type PaginatedNotifications = {
    notifications : [Notification];
    nextCursor : ?Nat;
    hasMore : Bool;
  };

  let userProfiles : Map.Map<Principal, UserProfile>;
  let usernameToUser : Map.Map<Text, Principal>;
  let posts : Map.Map<Nat, Post>;
  let userPostCounts : Map.Map<Principal, Nat>;
  var nextPostId : Nat;
  let following : Map.Map<Principal, Map.Map<Principal, Bool>>;
  let followers : Map.Map<Principal, Map.Map<Principal, Bool>>;
  let blocks : Map.Map<Principal, Map.Map<Principal, Bool>>;
  let mutes : Map.Map<Principal, Map.Map<Principal, Bool>>;
  let postLikes : Map.Map<Nat, Map.Map<Principal, Bool>>;
  let postReplies : Map.Map<Nat, Map.Map<Nat, Bool>>;
  let postReposts : Map.Map<Nat, Map.Map<Principal, Bool>>;
  let repostIndex : Map.Map<Principal, Map.Map<Nat, Nat>>;
  let hashtagIndex : Map.Map<Text, Map.Map<Nat, Bool>>;
  let userNotifications : Map.Map<Principal, Map.Map<Nat, Notification>>;
  var nextNotificationId : Nat;
  let messages : Map.Map<MessagingTypes.ConversationId, Map.Map<Nat, MessagingTypes.Message>>;
  let conversations : Map.Map<Principal, Map.Map<MessagingTypes.ConversationId, MessagingTypes.ConversationSummary>>;
  let nextMessageId : { var value : Nat };

  include MessagingApi(userProfiles, following, blocks, messages, conversations, nextMessageId);
  include ApiDocMixin();

  transient let anyPrincipal = Principal.fromText("aaaaa-aa");

  // Flatteners that promote the outer map key into a column, so the nested
  // per-user maps become queryable rows.
  type FollowRow = { follower : Principal; followed : Principal; active : Bool };
  type FollowerRow = { user : Principal; follower : Principal; active : Bool };
  type BlockRow = { blocker : Principal; blocked : Principal; active : Bool };
  type MuteRow = { muter : Principal; muted : Principal; active : Bool };
  type PostLikeRow = { postId : Nat; liker : Principal; active : Bool };
  type PostReplyRow = { parentPostId : Nat; replyPostId : Nat; active : Bool };
  type PostRepostRow = { postId : Nat; reposter : Principal; active : Bool };
  type HashtagRow = { tag : Text; postId : Nat; active : Bool };
  type NotificationRow = {
    recipient : Principal;
    id : Nat;
    notificationType : NotificationType;
    actorPrincipal : Principal;
    actorUsername : Text;
    createdAt : Time.Time;
    isRead : Bool;
  };
  type MessageRow = {
    conversationId : MessagingTypes.ConversationId;
    id : Nat;
    sender : Principal;
    recipient : Principal;
    text : Text;
    createdAt : Time.Time;
  };
  type ConversationRow = {
    owner : Principal;
    conversationId : MessagingTypes.ConversationId;
    otherParticipant : Principal;
    otherUsername : Text;
    otherDisplayName : Text;
    otherProfilePictureHash : ?Storage.ExternalBlob;
    lastMessagePreview : Text;
    lastMessageAt : Time.Time;
    lastMessageFromCaller : Bool;
    unreadCount : Nat;
  };

  func postTypeText(t : PostType) : Text {
    switch (t) {
      case (#original) { "original" };
      case (#reply(_)) { "reply" };
      case (#repost(_)) { "repost" };
      case (#quote(_)) { "quote" };
    };
  };

  func notificationTypeText(t : NotificationType) : Text {
    switch (t) {
      case (#like(_)) { "like" };
      case (#reply(_)) { "reply" };
      case (#mention(_)) { "mention" };
      case (#follow) { "follow" };
      case (#repost(_)) { "repost" };
      case (#quote(_)) { "quote" };
    };
  };

  func flattenFollowing() : Iter.Iter<FollowRow> {
    let out = List.empty<FollowRow>();
    for ((follower, inner) in following.entries()) {
      for ((followed, active) in inner.entries()) {
        out.add({ follower; followed; active });
      };
    };
    out.values();
  };

  func flattenFollowers() : Iter.Iter<FollowerRow> {
    let out = List.empty<FollowerRow>();
    for ((user, inner) in followers.entries()) {
      for ((follower, active) in inner.entries()) {
        out.add({ user; follower; active });
      };
    };
    out.values();
  };

  func flattenBlocks() : Iter.Iter<BlockRow> {
    let out = List.empty<BlockRow>();
    for ((blocker, inner) in blocks.entries()) {
      for ((blocked, active) in inner.entries()) {
        out.add({ blocker; blocked; active });
      };
    };
    out.values();
  };

  func flattenMutes() : Iter.Iter<MuteRow> {
    let out = List.empty<MuteRow>();
    for ((muter, inner) in mutes.entries()) {
      for ((muted, active) in inner.entries()) {
        out.add({ muter; muted; active });
      };
    };
    out.values();
  };

  func flattenPostLikes() : Iter.Iter<PostLikeRow> {
    let out = List.empty<PostLikeRow>();
    for ((postId, inner) in postLikes.entries()) {
      for ((liker, active) in inner.entries()) {
        out.add({ postId; liker; active });
      };
    };
    out.values();
  };

  func flattenPostReplies() : Iter.Iter<PostReplyRow> {
    let out = List.empty<PostReplyRow>();
    for ((parentPostId, inner) in postReplies.entries()) {
      for ((replyPostId, active) in inner.entries()) {
        out.add({ parentPostId; replyPostId; active });
      };
    };
    out.values();
  };

  func flattenPostReposts() : Iter.Iter<PostRepostRow> {
    let out = List.empty<PostRepostRow>();
    for ((postId, inner) in postReposts.entries()) {
      for ((reposter, active) in inner.entries()) {
        out.add({ postId; reposter; active });
      };
    };
    out.values();
  };

  func flattenHashtags() : Iter.Iter<HashtagRow> {
    let out = List.empty<HashtagRow>();
    for ((tag, inner) in hashtagIndex.entries()) {
      for ((postId, active) in inner.entries()) {
        out.add({ tag; postId; active });
      };
    };
    out.values();
  };

  func flattenNotifications() : Iter.Iter<NotificationRow> {
    let out = List.empty<NotificationRow>();
    for ((recipient, inner) in userNotifications.entries()) {
      for ((id, notif) in inner.entries()) {
        out.add({
          recipient;
          id;
          notificationType = notif.notificationType;
          actorPrincipal = notif.actorPrincipal;
          actorUsername = notif.actorUsername;
          createdAt = notif.createdAt;
          isRead = notif.isRead;
        });
      };
    };
    out.values();
  };

  func flattenMessages() : Iter.Iter<MessageRow> {
    let out = List.empty<MessageRow>();
    for ((conversationId, inner) in messages.entries()) {
      for ((id, msg) in inner.entries()) {
        out.add({
          conversationId;
          id;
          sender = msg.sender;
          recipient = msg.recipient;
          text = msg.text;
          createdAt = msg.createdAt;
        });
      };
    };
    out.values();
  };

  func flattenConversations() : Iter.Iter<ConversationRow> {
    let out = List.empty<ConversationRow>();
    for ((owner, inner) in conversations.entries()) {
      for ((conversationId, s) in inner.entries()) {
        out.add({
          owner;
          conversationId;
          otherParticipant = s.otherParticipant;
          otherUsername = s.otherUsername;
          otherDisplayName = s.otherDisplayName;
          otherProfilePictureHash = s.otherProfilePictureHash;
          lastMessagePreview = s.lastMessagePreview;
          lastMessageAt = s.lastMessageAt;
          lastMessageFromCaller = s.lastMessageFromCaller;
          unreadCount = s.unreadCount;
        });
      };
    };
    out.values();
  };

  include Expose({
    entities = [
      OQL.Entity.manual<UserProfile>("userProfile", func () = userProfiles.values(), "UserProfile", "username")
        .sample({
          username = "";
          displayName = "";
          bio = "";
          profilePictureHash = null;
          headerImageHash = null;
          createdAt = 0;
          updatedAt = 0;
        })
        .payload("username", func p = p.username)
        .payload("displayName", func p = p.displayName)
        .payload("bio", func p = p.bio)
        .payload("createdAt", func p = p.createdAt)
        .payload("updatedAt", func p = p.updatedAt)
        .controllerOnly()
        .build(),
      OQL.Entity.manual<Post>("post", func () = posts.values(), "Post", "id")
        .sample({
          id = 0;
          author = anyPrincipal;
          text = "";
          mediaHash = null;
          mediaType = null;
          postType = #original;
          createdAt = 0;
          editedAt = null;
        })
        .payload("id", func p = p.id)
        .payload("author", func p = p.author)
        .payload("text", func p = p.text)
        .payload("postType", func p = postTypeText(p.postType))
        .payload("createdAt", func p = p.createdAt)
        .controllerOnly()
        .build(),
      OQL.Entity.manual<FollowRow>("following", flattenFollowing, "Following", "follower")
        .sample({ follower = anyPrincipal; followed = anyPrincipal; active = true })
        .flatten(func r = r)
        .controllerOnly()
        .build(),
      OQL.Entity.manual<FollowerRow>("follower", flattenFollowers, "Follower", "user")
        .sample({ user = anyPrincipal; follower = anyPrincipal; active = true })
        .flatten(func r = r)
        .controllerOnly()
        .build(),
      OQL.Entity.manual<BlockRow>("block", flattenBlocks, "Block", "blocker")
        .sample({ blocker = anyPrincipal; blocked = anyPrincipal; active = true })
        .flatten(func r = r)
        .controllerOnly()
        .build(),
      OQL.Entity.manual<MuteRow>("mute", flattenMutes, "Mute", "muter")
        .sample({ muter = anyPrincipal; muted = anyPrincipal; active = true })
        .flatten(func r = r)
        .controllerOnly()
        .build(),
      OQL.Entity.manual<PostLikeRow>("postLike", flattenPostLikes, "PostLike", "postId")
        .sample({ postId = 0; liker = anyPrincipal; active = true })
        .flatten(func r = r)
        .controllerOnly()
        .build(),
      OQL.Entity.manual<PostReplyRow>("postReply", flattenPostReplies, "PostReply", "parentPostId")
        .sample({ parentPostId = 0; replyPostId = 0; active = true })
        .flatten(func r = r)
        .controllerOnly()
        .build(),
      OQL.Entity.manual<PostRepostRow>("postRepost", flattenPostReposts, "PostRepost", "postId")
        .sample({ postId = 0; reposter = anyPrincipal; active = true })
        .flatten(func r = r)
        .controllerOnly()
        .build(),
      OQL.Entity.manual<HashtagRow>("hashtag", flattenHashtags, "Hashtag", "tag")
        .sample({ tag = ""; postId = 0; active = true })
        .flatten(func r = r)
        .controllerOnly()
        .build(),
      OQL.Entity.manual<NotificationRow>("notification", flattenNotifications, "Notification", "recipient")
        .sample({
          recipient = anyPrincipal;
          id = 0;
          notificationType = #follow;
          actorPrincipal = anyPrincipal;
          actorUsername = "";
          createdAt = 0;
          isRead = false;
        })
        .payload("recipient", func r = r.recipient)
        .payload("id", func r = r.id)
        .payload("notificationType", func r = notificationTypeText(r.notificationType))
        .payload("actorPrincipal", func r = r.actorPrincipal)
        .payload("actorUsername", func r = r.actorUsername)
        .payload("createdAt", func r = r.createdAt)
        .payload("isRead", func r = r.isRead)
        .controllerOnly()
        .build(),
      OQL.Entity.manual<MessageRow>("message", flattenMessages, "Message", "conversationId")
        .sample({
          conversationId = "";
          id = 0;
          sender = anyPrincipal;
          recipient = anyPrincipal;
          text = "";
          createdAt = 0;
        })
        .flatten(func r = r)
        .controllerOnly()
        .build(),
      OQL.Entity.manual<ConversationRow>("conversation", flattenConversations, "Conversation", "owner")
        .sample({
          owner = anyPrincipal;
          conversationId = "";
          otherParticipant = anyPrincipal;
          otherUsername = "";
          otherDisplayName = "";
          otherProfilePictureHash = null;
          lastMessagePreview = "";
          lastMessageAt = 0;
          lastMessageFromCaller = false;
          unreadCount = 0;
        })
        .payload("owner", func r = r.owner)
        .payload("conversationId", func r = r.conversationId)
        .payload("otherParticipant", func r = r.otherParticipant)
        .payload("otherUsername", func r = r.otherUsername)
        .payload("otherDisplayName", func r = r.otherDisplayName)
        .payload("lastMessagePreview", func r = r.lastMessagePreview)
        .payload("lastMessageAt", func r = r.lastMessageAt)
        .payload("lastMessageFromCaller", func r = r.lastMessageFromCaller)
        .payload("unreadCount", func r = r.unreadCount)
        .controllerOnly()
        .build(),
    ];
  });

  transient let maxPostLength : Nat = 280;
  transient let editDeleteWindowNanos : Int = 900_000_000_000;
  transient let maxPostsPerUser : Nat = 10_000;
  transient let maxNotificationsPerUser : Nat = 50;

  func validateMedia(mediaHash : ?Storage.ExternalBlob, mediaType : ?Text) {
    switch (mediaHash, mediaType) {
      case (null, null) {};
      case (?_, ?"image") {};
      case (?_, ?"video") {};
      case (null, ?_) { Runtime.trap("mediaType requires mediaHash") };
      case (?_, null) { Runtime.trap("mediaHash requires mediaType") };
      case (?_, ?_) { Runtime.trap("mediaType must be \"image\" or \"video\"") };
    };
  };

  func requirePostCapNotReached(caller : Principal) {
    let count = switch (userPostCounts.get(caller)) {
      case (?n) { n };
      case (null) { 0 };
    };
    if (count >= maxPostsPerUser) {
      Runtime.trap("Post limit reached (" # maxPostsPerUser.toText() # " posts max)");
    };
  };

  func requireAuth(caller : Principal) {
    if (caller.isAnonymous()) {
      Runtime.trap("Not authenticated");
    };
  };

  func toLower(t : Text) : Text {
    t.map(
      func(c) {
        let code = c.toNat32();
        if (code >= 65 and code <= 90) {
          Char.fromNat32(code + 32);
        } else {
          c;
        };
      }
    );
  };

  func isValidUsername(username : Text) : Bool {
    let size = username.size();
    if (size < 3 or size > 20) { return false };
    for (c in username.chars()) {
      let code = c.toNat32();
      let isLower = code >= 97 and code <= 122;
      let isUpper = code >= 65 and code <= 90;
      let isDigit = code >= 48 and code <= 57;
      let isUnderscore = code == 95;
      if (not isLower and not isUpper and not isDigit and not isUnderscore) {
        return false;
      };
    };
    true;
  };

  func getMap<V>(store : Map.Map<Principal, Map.Map<Nat, V>>, user : Principal) : Map.Map<Nat, V> {
    switch (store.get(user)) {
      case (?m) { m };
      case (null) {
        let m = Map.empty<Nat, V>();
        store.add(user, m);
        m;
      };
    };
  };

  func getPrincipalMap(store : Map.Map<Principal, Map.Map<Principal, Bool>>, key : Principal) : Map.Map<Principal, Bool> {
    switch (store.get(key)) {
      case (?m) { m };
      case (null) {
        let m = Map.empty<Principal, Bool>();
        store.add(key, m);
        m;
      };
    };
  };

  func incrementPostCount(user : Principal) {
    let current = switch (userPostCounts.get(user)) {
      case (?n) { n };
      case (null) { 0 };
    };
    userPostCounts.add(user, current + 1);
  };

  func decrementPostCount(user : Principal) {
    let current : Int = switch (userPostCounts.get(user)) {
      case (?n) { n };
      case (null) { 0 };
    };
    if (current > 0) {
      userPostCounts.add(user, Int.abs(current - 1));
    };
  };

  func getNatPrincipalMap(store : Map.Map<Nat, Map.Map<Principal, Bool>>, key : Nat) : Map.Map<Principal, Bool> {
    switch (store.get(key)) {
      case (?m) { m };
      case (null) {
        let m = Map.empty<Principal, Bool>();
        store.add(key, m);
        m;
      };
    };
  };

  func getPostReplies(postId : Nat) : Map.Map<Nat, Bool> {
    switch (postReplies.get(postId)) {
      case (?m) { m };
      case (null) {
        let m = Map.empty<Nat, Bool>();
        postReplies.add(postId, m);
        m;
      };
    };
  };

  func getHashtagPosts(tag : Text) : Map.Map<Nat, Bool> {
    switch (hashtagIndex.get(tag)) {
      case (?m) { m };
      case (null) {
        let m = Map.empty<Nat, Bool>();
        hashtagIndex.add(tag, m);
        m;
      };
    };
  };

  func isTokenChar(c : Char) : Bool {
    let code = c.toNat32();
    (code >= 97 and code <= 122) or (code >= 65 and code <= 90) or (code >= 48 and code <= 57) or code == 95;
  };

  func extractTokens(text : Text, triggerChar : Char) : [Text] {
    let tokens = List.empty<Text>();
    let seen = Map.empty<Text, Bool>();
    var current = "";
    var inToken = false;

    for (c in text.chars()) {
      if (inToken) {
        if (isTokenChar(c)) {
          current #= c.toText();
        } else {
          if (current != "" and tokens.size() < 10) {
            let lower = toLower(current);
            if (seen.get(lower) == null) {
              tokens.add(lower);
              seen.add(lower, true);
            };
          };
          current := "";
          inToken := false;
          if (c == triggerChar) { inToken := true };
        };
      } else if (c == triggerChar) {
        inToken := true;
      };
    };
    if (inToken and current != "" and tokens.size() < 10) {
      let lower = toLower(current);
      if (seen.get(lower) == null) {
        tokens.add(lower);
        seen.add(lower, true);
      };
    };
    tokens.toArray();
  };

  func indexPostHashtags(postId : Nat, text : Text) {
    for (tag in extractTokens(text, '#').vals()) {
      getHashtagPosts(tag).add(postId, true);
    };
  };

  func removePostHashtags(postId : Nat, text : Text) {
    for (tag in extractTokens(text, '#').vals()) {
      switch (hashtagIndex.get(tag)) {
        case (?m) { m.remove(postId) };
        case (null) {};
      };
    };
  };

  func addNotification(recipient : Principal, actor_ : Principal, notificationType : NotificationType) {
    if (recipient == actor_) { return };
    if (isBlockedBidirectional(recipient, actor_)) { return };
    let actorUsername = switch (userProfiles.get(actor_)) {
      case (?p) { p.username };
      case (null) { "unknown" };
    };
    let id = nextNotificationId;
    nextNotificationId += 1;
    let notif : Notification = {
      id;
      notificationType;
      actorPrincipal = actor_;
      actorUsername;
      createdAt = Time.now();
      isRead = false;
    };
    let notifs = getMap(userNotifications, recipient);
    notifs.add(id, notif);

    // Evict oldest notifications beyond the cap
    if (notifs.size() > maxNotificationsPerUser) {
      let ids = List.empty<Nat>();
      for ((nid, _) in notifs.entries()) {
        ids.add(nid);
      };
      ids.sortInPlace(
        func(a, b) {
          if (a < b) { #less } else if (a > b) { #greater } else { #equal };
        }
      );
      var removed : Nat = 0;
      let toRemove : Nat = notifs.size() - maxNotificationsPerUser;
      for (nid in ids.values()) {
        if (removed < toRemove) {
          notifs.remove(nid);
          removed += 1;
        };
      };
    };
  };

  func notifyMentions(text : Text, postId : Nat, actor_ : Principal) {
    for (username in extractTokens(text, '@').vals()) {
      switch (usernameToUser.get(username)) {
        case (?recipient) {
          addNotification(recipient, actor_, #mention(postId));
        };
        case (null) {};
      };
    };
  };

  // Returns true if `blocker` has blocked `target`
  func hasBlocked(blocker : Principal, target : Principal) : Bool {
    switch (blocks.get(blocker)) {
      case (?m) { m.get(target) != null };
      case (null) { false };
    };
  };

  func isBlockedBidirectional(a : Principal, b : Principal) : Bool {
    hasBlocked(a, b) or hasBlocked(b, a);
  };

  // Case-insensitive substring search
  func textContains(haystack : Text, needle : Text) : Bool {
    let h = toLower(haystack);
    let n = toLower(needle);
    let nSize = n.size();
    if (nSize == 0) { return true };
    let hSize = h.size();
    if (nSize > hSize) { return false };

    let hChars = List.empty<Char>();
    for (c in h.chars()) { hChars.add(c) };
    let nChars = List.empty<Char>();
    for (c in n.chars()) { nChars.add(c) };
    let hArr = hChars.toArray();
    let nArr = nChars.toArray();

    var i = 0;
    while (i + nSize <= hSize) {
      var j = 0;
      var matched = true;
      while (j < nSize and matched) {
        if (hArr[i + j] != nArr[j]) { matched := false };
        j += 1;
      };
      if (matched) { return true };
      i += 1;
    };
    false;
  };

  func buildProfileResponse(user : Principal, caller : Principal) : ?UserProfileResponse {
    if (not caller.isAnonymous() and hasBlocked(user, caller)) {
      return null;
    };
    switch (userProfiles.get(user)) {
      case (null) { null };
      case (?profile) {
        let followersCount = switch (followers.get(user)) {
          case (?m) { m.size() };
          case (null) { 0 };
        };
        let followingCount = switch (following.get(user)) {
          case (?m) { m.size() };
          case (null) { 0 };
        };
        let postsCount = switch (userPostCounts.get(user)) {
          case (?n) { n };
          case (null) { 0 };
        };
        let isAuthenticated = not caller.isAnonymous();
        let isFollowed = if (isAuthenticated) {
          switch (following.get(caller)) {
            case (?m) { m.get(user) != null };
            case (null) { false };
          };
        } else { false };
        let isBlocked = if (isAuthenticated) {
          hasBlocked(caller, user);
        } else { false };
        let isMuted = if (isAuthenticated) {
          switch (mutes.get(caller)) {
            case (?m) { m.get(user) != null };
            case (null) { false };
          };
        } else { false };
        ?{
          principal = user;
          username = profile.username;
          displayName = profile.displayName;
          bio = profile.bio;
          profilePictureHash = profile.profilePictureHash;
          headerImageHash = profile.headerImageHash;
          createdAt = profile.createdAt;
          updatedAt = profile.updatedAt;
          followersCount;
          followingCount;
          postsCount;
          isFollowedByCurrentUser = isFollowed;
          isBlockedByCurrentUser = isBlocked;
          isMutedByCurrentUser = isMuted;
        };
      };
    };
  };

  func toPostResponse(post : Post, caller : ?Principal) : PostResponse {
    let authorProfile = userProfiles.get(post.author);
    let likes = postLikes.get(post.id);
    let likeCount = switch (likes) {
      case (?m) { m.size() };
      case (null) { 0 };
    };
    let isLiked = switch (caller) {
      case (?c) {
        switch (likes) {
          case (?m) { m.get(c) != null };
          case (null) { false };
        };
      };
      case (null) { false };
    };
    let replyCount = switch (postReplies.get(post.id)) {
      case (?m) { m.size() };
      case (null) { 0 };
    };
    let reposts = postReposts.get(post.id);
    let repostCount = switch (reposts) {
      case (?m) { m.size() };
      case (null) { 0 };
    };
    let isReposted = switch (caller) {
      case (?c) {
        switch (reposts) {
          case (?m) { m.get(c) != null };
          case (null) { false };
        };
      };
      case (null) { false };
    };
    {
      id = post.id;
      author = post.author;
      authorUsername = switch (authorProfile) {
        case (?p) { p.username };
        case (null) { "unknown" };
      };
      authorDisplayName = switch (authorProfile) {
        case (?p) { p.displayName };
        case (null) { "Unknown" };
      };
      authorProfilePictureHash = switch (authorProfile) {
        case (?p) { p.profilePictureHash };
        case (null) { null };
      };
      text = post.text;
      mediaHash = post.mediaHash;
      mediaType = post.mediaType;
      postType = post.postType;
      createdAt = post.createdAt;
      editedAt = post.editedAt;
      likeCount;
      replyCount;
      repostCount;
      isLikedByCurrentUser = isLiked;
      isRepostedByCurrentUser = isReposted;
    };
  };

  func paginatePosts(start : Nat, effectiveLimit : Nat, caller : ?Principal, predicate : (Post) -> Bool) : PaginatedPosts {
    if (start == 0) {
      return { posts = []; nextCursor = null; hasMore = false };
    };
    let buf = List.empty<PostResponse>();
    let startInt : Int = start;
    for ((_, post) in posts.reverseEntriesFrom(Int.abs(startInt - 1))) {
      if (predicate(post)) {
        if (buf.size() < effectiveLimit) {
          buf.add(toPostResponse(post, caller));
        } else {
          let arr = buf.toArray();
          return {
            posts = arr;
            nextCursor = ?arr[arr.size() - 1].id;
            hasMore = true;
          };
        };
      };
    };
    { posts = buf.toArray(); nextCursor = null; hasMore = false };
  };

  func paginateFollows(principalMap : Map.Map<Principal, Bool>, caller : Principal, offset : Nat, effectiveLimit : Nat) : PaginatedFollows {
    let result = List.empty<FollowUserResponse>();
    var skipped : Nat = 0;
    var collected : Nat = 0;
    var hasMore = false;
    for ((p, _) in principalMap.entries()) {
      if (not caller.isAnonymous() and isBlockedBidirectional(caller, p)) {
        // skip
      } else {
        switch (userProfiles.get(p)) {
          case (null) {};
          case (?profile) {
            if (skipped < offset) {
              skipped += 1;
            } else if (collected < effectiveLimit) {
              result.add({
                principal = p;
                username = profile.username;
                displayName = profile.displayName;
                profilePictureHash = profile.profilePictureHash;
              });
              collected += 1;
            } else {
              hasMore := true;
            };
          };
        };
      };
    };
    let nextOffset : ?Nat = if (hasMore) { ?(offset + effectiveLimit) } else {
      null;
    };
    { users = result.toArray(); nextOffset; hasMore };
  };

  func paginatePostIds(idMap : Map.Map<Nat, Bool>, caller : Principal, cursor : ?Nat, effectiveLimit : Nat) : PaginatedPosts {
    let isAnon = caller.isAnonymous();
    let c = if (isAnon) { null } else { ?caller };
    let idList = List.empty<Nat>();
    for ((id, _) in idMap.entries()) {
      idList.add(id);
    };
    idList.sortInPlace(
      func(a, b) {
        if (a > b) { #less } else if (a < b) { #greater } else { #equal };
      }
    );
    let start = switch (cursor) {
      case (?cur) { cur };
      case (null) { nextPostId };
    };
    let resultBuf = List.empty<PostResponse>();
    var foundExtra = false;
    for (id in idList.values()) {
      if (not foundExtra and id < start) {
        switch (posts.get(id)) {
          case (?post) {
            if (not isAnon and isBlockedBidirectional(caller, post.author)) {
              // skip
            } else if (resultBuf.size() < effectiveLimit) {
              resultBuf.add(toPostResponse(post, c));
            } else {
              foundExtra := true;
            };
          };
          case (null) {};
        };
      };
    };
    let arr = resultBuf.toArray();
    let nextCursor : ?Nat = if (foundExtra and arr.size() > 0) {
      ?arr[arr.size() - 1].id;
    } else {
      null;
    };
    { posts = arr; nextCursor; hasMore = foundExtra };
  };

  func markNotifRead(notifs : Map.Map<Nat, Notification>, id : Nat) {
    switch (notifs.get(id)) {
      case (?notif) {
        if (not notif.isRead) {
          notifs.add(
            id,
            {
              id = notif.id;
              notificationType = notif.notificationType;
              actorPrincipal = notif.actorPrincipal;
              actorUsername = notif.actorUsername;
              createdAt = notif.createdAt;
              isRead = true;
            },
          );
        };
      };
      case (null) {};
    };
  };

  public query func checkUsernameAvailability(username : Text) : async Bool {
    if (not isValidUsername(username)) { return false };
    let lower = toLower(username);
    switch (usernameToUser.get(lower)) {
      case (?_) { false };
      case (null) { true };
    };
  };

  public query func getPrincipalByUsername(username : Text) : async ?Principal {
    let lower = toLower(username);
    usernameToUser.get(lower);
  };

  public query ({ caller }) func getProfile() : async ?UserProfile {
    requireAuth(caller);
    userProfiles.get(caller);
  };

  public shared ({ caller }) func setProfile(username : Text, displayName : Text, bio : Text) : async () {
    requireAuth(caller);

    if (username == "") {
      Runtime.trap("Username cannot be empty");
    };
    if (not isValidUsername(username)) {
      Runtime.trap("Username must be 3-20 characters, alphanumeric and underscores only");
    };
    if (displayName == "") {
      Runtime.trap("Display name cannot be empty");
    };
    if (displayName.size() > 50) {
      Runtime.trap("Display name must be 50 characters or fewer");
    };
    if (bio.size() > 160) {
      Runtime.trap("Bio must be 160 characters or fewer");
    };

    let lower = toLower(username);

    // Check username availability (allow keeping own username)
    switch (usernameToUser.get(lower)) {
      case (?existingPrincipal) {
        if (existingPrincipal != caller) {
          Runtime.trap("Username is already taken");
        };
      };
      case (null) {};
    };

    // Remove old username mapping if changing username
    switch (userProfiles.get(caller)) {
      case (?existing) {
        let oldLower = toLower(existing.username);
        if (oldLower != lower) {
          usernameToUser.remove(oldLower);
        };
      };
      case (null) {};
    };

    let now = Time.now();
    let existing = userProfiles.get(caller);
    let profile : UserProfile = {
      username;
      displayName;
      bio;
      profilePictureHash = switch (existing) {
        case (?e) { e.profilePictureHash };
        case (null) { null };
      };
      headerImageHash = switch (existing) {
        case (?e) { e.headerImageHash };
        case (null) { null };
      };
      createdAt = switch (existing) {
        case (?e) { e.createdAt };
        case (null) { now };
      };
      updatedAt = now;
    };

    userProfiles.add(caller, profile);
    usernameToUser.add(lower, caller);
  };

  public shared ({ caller }) func updateProfilePicture(pictureHash : ?Storage.ExternalBlob) : async () {
    requireAuth(caller);
    let existing = switch (userProfiles.get(caller)) {
      case (?p) { p };
      case (null) { Runtime.trap("Must create profile first") };
    };
    userProfiles.add(
      caller,
      {
        username = existing.username;
        displayName = existing.displayName;
        bio = existing.bio;
        profilePictureHash = pictureHash;
        headerImageHash = existing.headerImageHash;
        createdAt = existing.createdAt;
        updatedAt = Time.now();
      },
    );
  };

  public shared ({ caller }) func updateHeaderImage(imageHash : ?Storage.ExternalBlob) : async () {
    requireAuth(caller);
    let existing = switch (userProfiles.get(caller)) {
      case (?p) { p };
      case (null) { Runtime.trap("Must create profile first") };
    };
    userProfiles.add(
      caller,
      {
        username = existing.username;
        displayName = existing.displayName;
        bio = existing.bio;
        profilePictureHash = existing.profilePictureHash;
        headerImageHash = imageHash;
        createdAt = existing.createdAt;
        updatedAt = Time.now();
      },
    );
  };

  public shared ({ caller }) func createPost(text : Text, mediaHash : ?Storage.ExternalBlob, mediaType : ?Text) : async PostResponse {
    requireAuth(caller);
    validateMedia(mediaHash, mediaType);
    requirePostCapNotReached(caller);
    switch (userProfiles.get(caller)) {
      case (null) { Runtime.trap("Must create profile before posting") };
      case (?_) {};
    };
    if (text.size() == 0 and mediaHash == null) {
      Runtime.trap("Post must contain text or media");
    };
    if (text.size() > maxPostLength) {
      Runtime.trap("Post text must be 280 characters or fewer");
    };

    let now = Time.now();
    let id = nextPostId;
    nextPostId += 1;

    let post : Post = {
      id;
      author = caller;
      text;
      mediaHash;
      mediaType;
      postType = #original;
      createdAt = now;
      editedAt = null;
    };

    posts.add(id, post);
    incrementPostCount(caller);
    indexPostHashtags(id, text);
    notifyMentions(text, id, caller);

    toPostResponse(post, ?caller);
  };

  public query ({ caller }) func getPost(postId : Nat) : async ?PostResponse {
    let isAnon = caller.isAnonymous();
    let c = if (isAnon) { null } else { ?caller };
    switch (posts.get(postId)) {
      case (?post) {
        if (not isAnon and isBlockedBidirectional(caller, post.author)) {
          null;
        } else {
          ?toPostResponse(post, c);
        };
      };
      case (null) { null };
    };
  };

  public shared ({ caller }) func editPost(postId : Nat, text : Text) : async PostResponse {
    requireAuth(caller);
    if (text.size() > maxPostLength) {
      Runtime.trap("Post text must be 280 characters or fewer");
    };

    let post = switch (posts.get(postId)) {
      case (?p) { p };
      case (null) { Runtime.trap("Post not found") };
    };
    if (text.size() == 0 and post.mediaHash == null) {
      Runtime.trap("Post must contain text or media");
    };
    if (post.author != caller) {
      Runtime.trap("Cannot edit another user's post");
    };
    let now = Time.now();
    if (now - post.createdAt > editDeleteWindowNanos) {
      Runtime.trap("Edit window has expired (15 minutes)");
    };

    let updated : Post = {
      id = post.id;
      author = post.author;
      text;
      mediaHash = post.mediaHash;
      mediaType = post.mediaType;
      postType = post.postType;
      createdAt = post.createdAt;
      editedAt = ?now;
    };

    removePostHashtags(postId, post.text);
    posts.add(postId, updated);
    indexPostHashtags(postId, text);
    toPostResponse(updated, ?caller);
  };

  public shared ({ caller }) func deletePost(postId : Nat) : async () {
    requireAuth(caller);

    let post = switch (posts.get(postId)) {
      case (?p) { p };
      case (null) { Runtime.trap("Post not found") };
    };
    if (post.author != caller) {
      Runtime.trap("Cannot delete another user's post");
    };
    let now = Time.now();
    if (now - post.createdAt > editDeleteWindowNanos) {
      Runtime.trap("Delete window has expired (15 minutes)");
    };

    posts.remove(postId);
    decrementPostCount(caller);
    removePostHashtags(postId, post.text);
    postLikes.remove(postId);

    // Clean up type-specific indexes
    switch (post.postType) {
      case (#repost(originalId)) {
        switch (postReposts.get(originalId)) {
          case (?m) { m.remove(caller) };
          case (null) {};
        };
        let userReposts = getMap(repostIndex, caller);
        userReposts.remove(originalId);
      };
      case (#reply(parentId)) {
        switch (postReplies.get(parentId)) {
          case (?m) { m.remove(postId) };
          case (null) {};
        };
      };
      case (_) {};
    };
  };

  public query ({ caller }) func getGlobalFeed(cursor : ?Nat, limit : Nat) : async PaginatedPosts {
    let effectiveLimit = if (limit == 0 or limit > 50) { 20 } else { limit };
    let start = switch (cursor) {
      case (?c) { c };
      case (null) { nextPostId };
    };
    let isAnon = caller.isAnonymous();
    let c = if (isAnon) { null } else { ?caller };
    paginatePosts(
      start,
      effectiveLimit,
      c,
      func(post) {
        if (isAnon) { true } else {
          not isBlockedBidirectional(caller, post.author);
        };
      },
    );
  };

  public query ({ caller }) func getPostsByUser(user : Principal, cursor : ?Nat, limit : Nat) : async PaginatedPosts {
    if (not caller.isAnonymous() and hasBlocked(user, caller)) {
      return { posts = []; nextCursor = null; hasMore = false };
    };
    let effectiveLimit = if (limit == 0 or limit > 50) { 20 } else { limit };
    let start = switch (cursor) {
      case (?c) { c };
      case (null) { nextPostId };
    };
    let c = if (caller.isAnonymous()) { null } else { ?caller };
    paginatePosts(start, effectiveLimit, c, func(post) { post.author == user });
  };

  public query ({ caller }) func getHomeFeed(cursor : ?Nat, limit : Nat) : async PaginatedPosts {
    requireAuth(caller);
    let effectiveLimit = if (limit == 0 or limit > 50) { 20 } else { limit };
    let start = switch (cursor) {
      case (?c) { c };
      case (null) { nextPostId };
    };

    let callerFollowing = following.get(caller);
    let callerMutes = mutes.get(caller);
    let followsAnyone = switch (callerFollowing) {
      case (?m) { m.size() > 0 };
      case (null) { false };
    };

    paginatePosts(
      start,
      effectiveLimit,
      ?caller,
      func(post) {
        if (hasBlocked(caller, post.author) or hasBlocked(post.author, caller)) {
          false;
        } else {
          let isMuted = switch (callerMutes) {
            case (?m) { m.get(post.author) != null };
            case (null) { false };
          };
          if (isMuted) {
            false;
          } else if (post.author == caller) {
            true;
          } else if (followsAnyone) {
            switch (callerFollowing) {
              case (?m) { m.get(post.author) != null };
              case (null) { false };
            };
          } else {
            true;
          };
        };
      },
    );
  };

  public query ({ caller }) func getPostsByHashtag(tag : Text, cursor : ?Nat, limit : Nat) : async PaginatedPosts {
    let effectiveLimit = if (limit == 0 or limit > 50) { 20 } else { limit };
    let lower = toLower(tag);
    let tagPosts = switch (hashtagIndex.get(lower)) {
      case (?m) { m };
      case (null) {
        return { posts = []; nextCursor = null; hasMore = false };
      };
    };
    paginatePostIds(tagPosts, caller, cursor, effectiveLimit);
  };

  public query ({ caller }) func getUserProfile(user : Principal) : async ?UserProfileResponse {
    buildProfileResponse(user, caller);
  };

  public query ({ caller }) func getProfileByUsername(username : Text) : async ?UserProfileResponse {
    let lower = toLower(username);
    switch (usernameToUser.get(lower)) {
      case (null) { null };
      case (?user) { buildProfileResponse(user, caller) };
    };
  };

  public query ({ caller }) func getFollowers(username : Text, offset : Nat, limit : Nat) : async PaginatedFollows {
    let effectiveLimit = if (limit == 0 or limit > 50) { 20 } else { limit };
    let lower = toLower(username);
    let user = switch (usernameToUser.get(lower)) {
      case (null) { return { users = []; nextOffset = null; hasMore = false } };
      case (?u) { u };
    };
    let followerMap = switch (followers.get(user)) {
      case (null) { return { users = []; nextOffset = null; hasMore = false } };
      case (?m) { m };
    };
    paginateFollows(followerMap, caller, offset, effectiveLimit);
  };

  public query ({ caller }) func getFollowing(username : Text, offset : Nat, limit : Nat) : async PaginatedFollows {
    let effectiveLimit = if (limit == 0 or limit > 50) { 20 } else { limit };
    let lower = toLower(username);
    let user = switch (usernameToUser.get(lower)) {
      case (null) { return { users = []; nextOffset = null; hasMore = false } };
      case (?u) { u };
    };
    let followingMap = switch (following.get(user)) {
      case (null) { return { users = []; nextOffset = null; hasMore = false } };
      case (?m) { m };
    };
    paginateFollows(followingMap, caller, offset, effectiveLimit);
  };

  public query ({ caller }) func getPostsByUsername(username : Text, cursor : ?Nat, limit : Nat) : async PaginatedPosts {
    let lower = toLower(username);
    switch (usernameToUser.get(lower)) {
      case (null) { { posts = []; nextCursor = null; hasMore = false } };
      case (?user) {
        if (not caller.isAnonymous() and hasBlocked(user, caller)) {
          return { posts = []; nextCursor = null; hasMore = false };
        };
        let effectiveLimit = if (limit == 0 or limit > 50) { 20 } else { limit };
        let start = switch (cursor) {
          case (?c) { c };
          case (null) { nextPostId };
        };
        let c = if (caller.isAnonymous()) { null } else { ?caller };
        paginatePosts(start, effectiveLimit, c, func(post) { post.author == user });
      };
    };
  };

  public shared ({ caller }) func followUser(user : Principal) : async () {
    requireAuth(caller);
    if (caller == user) {
      Runtime.trap("Cannot follow yourself");
    };
    switch (userProfiles.get(user)) {
      case (null) { Runtime.trap("User not found") };
      case (?_) {};
    };
    if (isBlockedBidirectional(caller, user)) {
      Runtime.trap("Cannot interact with this user");
    };
    let callerFollowing = getPrincipalMap(following, caller);
    let alreadyFollowing = callerFollowing.get(user) != null;
    callerFollowing.add(user, true);
    getPrincipalMap(followers, user).add(caller, true);
    if (not alreadyFollowing) {
      addNotification(user, caller, #follow);
    };
  };

  public shared ({ caller }) func unfollowUser(user : Principal) : async () {
    requireAuth(caller);
    getPrincipalMap(following, caller).remove(user);
    getPrincipalMap(followers, user).remove(caller);
  };

  public shared ({ caller }) func blockUser(user : Principal) : async () {
    requireAuth(caller);
    if (caller == user) {
      Runtime.trap("Cannot block yourself");
    };
    switch (userProfiles.get(user)) {
      case (null) { Runtime.trap("User not found") };
      case (?_) {};
    };
    getPrincipalMap(blocks, caller).add(user, true);
    // Remove follow relationships in both directions
    getPrincipalMap(following, caller).remove(user);
    getPrincipalMap(followers, user).remove(caller);
    getPrincipalMap(following, user).remove(caller);
    getPrincipalMap(followers, caller).remove(user);
  };

  public shared ({ caller }) func unblockUser(user : Principal) : async () {
    requireAuth(caller);
    getPrincipalMap(blocks, caller).remove(user);
  };

  public shared ({ caller }) func muteUser(user : Principal) : async () {
    requireAuth(caller);
    if (caller == user) {
      Runtime.trap("Cannot mute yourself");
    };
    switch (userProfiles.get(user)) {
      case (null) { Runtime.trap("User not found") };
      case (?_) {};
    };
    getPrincipalMap(mutes, caller).add(user, true);
  };

  public shared ({ caller }) func unmuteUser(user : Principal) : async () {
    requireAuth(caller);
    getPrincipalMap(mutes, caller).remove(user);
  };

  public shared ({ caller }) func likePost(postId : Nat) : async () {
    requireAuth(caller);
    let post = switch (posts.get(postId)) {
      case (?p) { p };
      case (null) { Runtime.trap("Post not found") };
    };
    if (isBlockedBidirectional(caller, post.author)) {
      Runtime.trap("Cannot interact with this user");
    };
    let likes = getNatPrincipalMap(postLikes, postId);
    let alreadyLiked = likes.get(caller) != null;
    likes.add(caller, true);
    if (not alreadyLiked) {
      addNotification(post.author, caller, #like(postId));
    };
  };

  public shared ({ caller }) func unlikePost(postId : Nat) : async () {
    requireAuth(caller);
    switch (postLikes.get(postId)) {
      case (?m) { m.remove(caller) };
      case (null) {};
    };
  };

  public shared ({ caller }) func createReply(parentPostId : Nat, text : Text, mediaHash : ?Storage.ExternalBlob, mediaType : ?Text) : async PostResponse {
    requireAuth(caller);
    validateMedia(mediaHash, mediaType);
    requirePostCapNotReached(caller);
    switch (userProfiles.get(caller)) {
      case (null) { Runtime.trap("Must create profile before replying") };
      case (?_) {};
    };
    let parentPost = switch (posts.get(parentPostId)) {
      case (?p) { p };
      case (null) { Runtime.trap("Parent post not found") };
    };
    if (isBlockedBidirectional(caller, parentPost.author)) {
      Runtime.trap("Cannot interact with this user");
    };
    if (text.size() == 0 and mediaHash == null) {
      Runtime.trap("Reply must contain text or media");
    };
    if (text.size() > maxPostLength) {
      Runtime.trap("Reply text must be 280 characters or fewer");
    };

    let now = Time.now();
    let id = nextPostId;
    nextPostId += 1;

    let reply : Post = {
      id;
      author = caller;
      text;
      mediaHash;
      mediaType;
      postType = #reply(parentPostId);
      createdAt = now;
      editedAt = null;
    };

    posts.add(id, reply);
    incrementPostCount(caller);
    getPostReplies(parentPostId).add(id, true);
    indexPostHashtags(id, text);
    addNotification(parentPost.author, caller, #reply(parentPostId));
    notifyMentions(text, id, caller);

    toPostResponse(reply, ?caller);
  };

  public query ({ caller }) func getReplies(postId : Nat, cursor : ?Nat, limit : Nat) : async PaginatedPosts {
    let effectiveLimit = if (limit == 0 or limit > 50) { 20 } else { limit };
    let replyIds = switch (postReplies.get(postId)) {
      case (?m) { m };
      case (null) {
        return { posts = []; nextCursor = null; hasMore = false };
      };
    };
    paginatePostIds(replyIds, caller, cursor, effectiveLimit);
  };

  public shared ({ caller }) func repostPost(postId : Nat) : async PostResponse {
    requireAuth(caller);
    requirePostCapNotReached(caller);
    switch (userProfiles.get(caller)) {
      case (null) { Runtime.trap("Must create profile before reposting") };
      case (?_) {};
    };
    let originalPost = switch (posts.get(postId)) {
      case (?p) { p };
      case (null) { Runtime.trap("Post not found") };
    };
    if (isBlockedBidirectional(caller, originalPost.author)) {
      Runtime.trap("Cannot interact with this user");
    };
    // Prevent duplicate repost
    switch (postReposts.get(postId)) {
      case (?m) {
        if (m.get(caller) != null) {
          Runtime.trap("Already reposted this post");
        };
      };
      case (null) {};
    };

    let now = Time.now();
    let id = nextPostId;
    nextPostId += 1;

    let repost : Post = {
      id;
      author = caller;
      text = "";
      mediaHash = null;
      mediaType = null;
      postType = #repost(postId);
      createdAt = now;
      editedAt = null;
    };

    posts.add(id, repost);
    incrementPostCount(caller);
    getNatPrincipalMap(postReposts, postId).add(caller, true);
    getMap(repostIndex, caller).add(postId, id);
    addNotification(originalPost.author, caller, #repost(postId));

    toPostResponse(repost, ?caller);
  };

  public shared ({ caller }) func undoRepost(postId : Nat) : async () {
    requireAuth(caller);
    switch (posts.get(postId)) {
      case (null) { Runtime.trap("Post not found") };
      case (?_) {};
    };
    // Remove from repost tracking
    switch (postReposts.get(postId)) {
      case (?m) { m.remove(caller) };
      case (null) {};
    };
    // Remove the repost post entry via reverse index
    let userReposts = getMap(repostIndex, caller);
    switch (userReposts.get(postId)) {
      case (?repostId) {
        posts.remove(repostId);
        decrementPostCount(caller);
        userReposts.remove(postId);
      };
      case (null) {};
    };
  };

  public shared ({ caller }) func quotePost(postId : Nat, text : Text, mediaHash : ?Storage.ExternalBlob, mediaType : ?Text) : async PostResponse {
    requireAuth(caller);
    validateMedia(mediaHash, mediaType);
    requirePostCapNotReached(caller);
    switch (userProfiles.get(caller)) {
      case (null) { Runtime.trap("Must create profile before quoting") };
      case (?_) {};
    };
    let originalPost = switch (posts.get(postId)) {
      case (?p) { p };
      case (null) { Runtime.trap("Post not found") };
    };
    if (isBlockedBidirectional(caller, originalPost.author)) {
      Runtime.trap("Cannot interact with this user");
    };
    if (text.size() == 0 and mediaHash == null) {
      Runtime.trap("Quote must contain text or media");
    };
    if (text.size() > maxPostLength) {
      Runtime.trap("Quote text must be 280 characters or fewer");
    };

    let now = Time.now();
    let id = nextPostId;
    nextPostId += 1;

    let quote : Post = {
      id;
      author = caller;
      text;
      mediaHash;
      mediaType;
      postType = #quote(postId);
      createdAt = now;
      editedAt = null;
    };

    posts.add(id, quote);
    incrementPostCount(caller);
    indexPostHashtags(id, text);
    addNotification(originalPost.author, caller, #quote(postId));
    notifyMentions(text, id, caller);

    toPostResponse(quote, ?caller);
  };

  public query ({ caller }) func searchPosts(searchText : Text, cursor : ?Nat, limit : Nat) : async PaginatedPosts {
    if (searchText == "") {
      return { posts = []; nextCursor = null; hasMore = false };
    };
    let effectiveLimit = if (limit == 0 or limit > 50) { 20 } else { limit };
    let start = switch (cursor) {
      case (?c) { c };
      case (null) { nextPostId };
    };
    let isAnon = caller.isAnonymous();
    let c = if (isAnon) { null } else { ?caller };
    paginatePosts(
      start,
      effectiveLimit,
      c,
      func(post) {
        if (not isAnon and isBlockedBidirectional(caller, post.author)) {
          false;
        } else {
          textContains(post.text, searchText);
        };
      },
    );
  };

  public query ({ caller }) func searchUsers(searchText : Text, limit : Nat) : async [UserProfileResponse] {
    if (searchText == "") {
      return [];
    };
    let effectiveLimit = if (limit == 0 or limit > 50) { 20 } else { limit };
    let results = List.empty<UserProfileResponse>();

    let isAnon = caller.isAnonymous();
    for ((principal, profile) in userProfiles.entries()) {
      if (results.size() >= effectiveLimit) {
        return results.toArray();
      };
      if (not isAnon and isBlockedBidirectional(caller, principal)) {
        // skip
      } else if (textContains(profile.username, searchText) or textContains(profile.displayName, searchText)) {
        switch (buildProfileResponse(principal, caller)) {
          case (?response) { results.add(response) };
          case (null) {};
        };
      };
    };
    results.toArray();
  };

  public query func getTrendingHashtags(limit : Nat) : async [TrendingHashtag] {
    let effectiveLimit = if (limit == 0 or limit > 50) { 10 } else { limit };
    let now = Time.now();
    let windowNanos : Int = 86_400_000_000_000; // 24 hours

    let trending = List.empty<TrendingHashtag>();

    for ((tag, postIds) in hashtagIndex.entries()) {
      var count : Nat = 0;
      for ((postId, _) in postIds.entries()) {
        switch (posts.get(postId)) {
          case (?post) {
            if (now - post.createdAt <= windowNanos) {
              count += 1;
            };
          };
          case (null) {};
        };
      };
      if (count > 0) {
        trending.add({ tag; count });
      };
    };

    trending.sortInPlace(
      func(a, b) {
        if (a.count > b.count) { #less } else if (a.count < b.count) {
          #greater;
        } else { #equal };
      }
    );

    let result = List.empty<TrendingHashtag>();
    for (item in trending.values()) {
      if (result.size() < effectiveLimit) {
        result.add(item);
      };
    };
    result.toArray();
  };

  public query ({ caller }) func getNotifications(cursor : ?Nat, limit : Nat) : async PaginatedNotifications {
    requireAuth(caller);
    let effectiveLimit = if (limit == 0 or limit > 50) { 20 } else { limit };

    let notifs = switch (userNotifications.get(caller)) {
      case (?m) { m };
      case (null) {
        return { notifications = []; nextCursor = null; hasMore = false };
      };
    };

    let idList = List.empty<Nat>();
    for ((id, _) in notifs.entries()) {
      idList.add(id);
    };
    idList.sortInPlace(
      func(a, b) {
        if (a > b) { #less } else if (a < b) { #greater } else { #equal };
      }
    );

    let start = switch (cursor) {
      case (?c) { c };
      case (null) { nextNotificationId };
    };

    let resultBuf = List.empty<Notification>();
    var foundExtra = false;
    for (id in idList.values()) {
      if (not foundExtra and id < start) {
        switch (notifs.get(id)) {
          case (?notif) {
            if (resultBuf.size() < effectiveLimit) {
              resultBuf.add(notif);
            } else {
              foundExtra := true;
            };
          };
          case (null) {};
        };
      };
    };

    let arr = resultBuf.toArray();
    let nextCursor : ?Nat = if (foundExtra and arr.size() > 0) {
      ?arr[arr.size() - 1].id;
    } else {
      null;
    };
    { notifications = arr; nextCursor; hasMore = foundExtra };
  };

  public shared ({ caller }) func markNotificationRead(notifId : Nat) : async () {
    requireAuth(caller);
    markNotifRead(getMap(userNotifications, caller), notifId);
  };

  public shared ({ caller }) func markAllNotificationsRead() : async () {
    requireAuth(caller);
    let notifs = getMap(userNotifications, caller);
    for ((id, _) in notifs.entries()) {
      markNotifRead(notifs, id);
    };
  };

  public query ({ caller }) func getUnreadNotificationCount() : async Nat {
    requireAuth(caller);
    switch (userNotifications.get(caller)) {
      case (null) { 0 };
      case (?notifs) {
        var count : Nat = 0;
        for ((_, notif) in notifs.entries()) {
          if (not notif.isRead) {
            count += 1;
          };
        };
        count;
      };
    };
  };
};
