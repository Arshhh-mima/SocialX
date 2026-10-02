import Storage "mo:caffeineai-object-storage/Storage";
import Time "mo:core/Time";

module {
  /// Canonical, order-independent key for a two-party conversation.
  /// `a` and `b` are always stored with `a` sorting before `b` by principal
  /// comparison, so the same pair of users always maps to one conversation.
  public type ConversationKey = {
    a : Principal;
    b : Principal;
  };

  /// Stable, URL-safe identifier for a conversation, derived from the two
  /// participant principals. Used by the frontend for direct-URL threads.
  public type ConversationId = Text;

  /// A single direct message between two mutually-following users.
  public type Message = {
    id : Nat;
    conversationId : ConversationId;
    sender : Principal;
    recipient : Principal;
    text : Text;
    createdAt : Time.Time;
  };

  /// Inbox row: one per conversation, from the caller's perspective.
  public type ConversationSummary = {
    conversationId : ConversationId;
    otherParticipant : Principal;
    otherUsername : Text;
    otherDisplayName : Text;
    otherProfilePictureHash : ?Storage.ExternalBlob;
    lastMessagePreview : Text;
    lastMessageAt : Time.Time;
    lastMessageFromCaller : Bool;
    unreadCount : Nat;
  };

  /// Cursor-paginated message history. `nextCursor` is the id to pass as the
  /// `before` cursor for the next (older) page; `null` means no older messages.
  public type PaginatedMessages = {
    messages : [Message];
    nextCursor : ?Nat;
    hasMore : Bool;
  };

  /// Whether the caller and `other` follow each other, plus the two directions
  /// so the UI can explain what is missing.
  public type MutualFollowStatus = {
    isMutual : Bool;
    callerFollowsOther : Bool;
    otherFollowsCaller : Bool;
  };

  /// Caller-actionable failure reasons for sending a message.
  public type MessagingError = {
    #notMutual;
    #blocked;
    #selfMessage;
    #emptyMessage;
    #messageTooLong : { maxLength : Nat };
    #recipientNotFound;
  };
};
