import Map "mo:core/Map";
import Principal "mo:core/Principal";
import Result "mo:core/Result";
import Runtime "mo:core/Runtime";
import Storage "mo:caffeineai-object-storage/Storage";
import Types "../types/messaging";
import MessagingLib "../lib/messaging";

mixin (
  userProfiles : Map.Map<Principal, {
    username : Text;
    displayName : Text;
    bio : Text;
    profilePictureHash : ?Storage.ExternalBlob;
    headerImageHash : ?Storage.ExternalBlob;
    createdAt : Int;
    updatedAt : Int;
  }>,
  following : Map.Map<Principal, Map.Map<Principal, Bool>>,
  blocks : Map.Map<Principal, Map.Map<Principal, Bool>>,
  messages : Map.Map<Types.ConversationId, Map.Map<Nat, Types.Message>>,
  conversations : Map.Map<Principal, Map.Map<Types.ConversationId, Types.ConversationSummary>>,
  nextMessageId : { var value : Nat },
) {
  func requireMessagingAuth(caller : Principal) {
    if (caller.isAnonymous()) {
      Runtime.trap("Not authenticated");
    };
  };

  /// Fill in the other participant's profile fields on a stored summary.
  func enrich(summary : Types.ConversationSummary) : Types.ConversationSummary {
    switch (userProfiles.get(summary.otherParticipant)) {
      case (?p) {
        {
          summary with
          otherUsername = p.username;
          otherDisplayName = p.displayName;
          otherProfilePictureHash = p.profilePictureHash;
        };
      };
      case (null) { summary };
    };
  };

  /// Send a direct message to `recipient`. Requires a mutual follow and no
  /// block in either direction. Returns the caller-actionable error otherwise.
  public shared ({ caller }) func sendMessage(recipient : Principal, text : Text) : async Result.Result<Types.Message, Types.MessagingError> {
    requireMessagingAuth(caller);
    switch (userProfiles.get(recipient)) {
      case (null) { return #err(#recipientNotFound) };
      case (?_) {};
    };
    switch (MessagingLib.validateSend(following, blocks, caller, recipient, text)) {
      case (#err(e)) { return #err(e) };
      case (#ok(_)) {};
    };
    #ok(MessagingLib.sendMessage(messages, conversations, nextMessageId, caller, recipient, text));
  };

  /// List the caller's conversations, most recent message first.
  public query ({ caller }) func getConversations() : async [Types.ConversationSummary] {
    requireMessagingAuth(caller);
    MessagingLib.listConversations(conversations, caller).map(enrich);
  };

  /// Fetch a page of a conversation's history, newest first. `before` is an
  /// exclusive cursor on message id; `null` starts from the newest message.
  public query ({ caller }) func getMessages(conversationId : Types.ConversationId, before : ?Nat, limit : Nat) : async Types.PaginatedMessages {
    requireMessagingAuth(caller);
    MessagingLib.getMessages(messages, conversations, caller, conversationId, before, limit);
  };

  /// Mark a conversation's messages as read for the caller.
  public shared ({ caller }) func markConversationRead(conversationId : Types.ConversationId) : async () {
    requireMessagingAuth(caller);
    MessagingLib.markConversationRead(conversations, caller, conversationId);
  };

  /// Total unread messages across all of the caller's conversations.
  public query ({ caller }) func getUnreadMessageCount() : async Nat {
    requireMessagingAuth(caller);
    MessagingLib.totalUnreadCount(conversations, caller);
  };

  /// Whether the caller and `other` follow each other, so the frontend can
  /// decide whether to show the Message button.
  public query ({ caller }) func getMutualFollowStatus(other : Principal) : async Types.MutualFollowStatus {
    if (caller.isAnonymous()) {
      return { isMutual = false; callerFollowsOther = false; otherFollowsCaller = false };
    };
    MessagingLib.mutualFollowStatus(following, caller, other);
  };
};
