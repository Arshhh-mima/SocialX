import Map "mo:core/Map";
import Principal "mo:core/Principal";
import Result "mo:core/Result";
import Time "mo:core/Time";
import Types "../types/messaging";

module {
  /// Maximum length of a direct message, in characters.
  public let maxMessageLength : Nat = 1000;

  /// Default page size for message history when the caller passes 0 or an
  /// out-of-range limit.
  public let defaultPageSize : Nat = 30;

  /// Build the canonical conversation key for two principals, ordering them so
  /// the same pair always yields the same key.
  public func conversationKey(x : Principal, y : Principal) : Types.ConversationKey {
    if (Principal.compare(x, y) == #less) {
      { a = x; b = y };
    } else {
      { a = y; b = x };
    };
  };

  /// Derive the stable conversation id from a canonical key.
  public func conversationId(key : Types.ConversationKey) : Types.ConversationId {
    key.a.toText() # ":" # key.b.toText();
  };

  /// Derive the conversation id directly from two principals.
  public func conversationIdFor(x : Principal, y : Principal) : Types.ConversationId {
    conversationId(conversationKey(x, y));
  };

  /// True when `a` follows `b` and `b` follows `a`.
  public func isMutualFollow(
    following : Map.Map<Principal, Map.Map<Principal, Bool>>,
    a : Principal,
    b : Principal,
  ) : Bool {
    let aFollowsB = switch (following.get(a)) {
      case (?m) { m.get(b) != null };
      case (null) { false };
    };
    let bFollowsA = switch (following.get(b)) {
      case (?m) { m.get(a) != null };
      case (null) { false };
    };
    aFollowsB and bFollowsA;
  };

  /// Mutual-follow status for the caller relative to `other`.
  public func mutualFollowStatus(
    following : Map.Map<Principal, Map.Map<Principal, Bool>>,
    caller : Principal,
    other : Principal,
  ) : Types.MutualFollowStatus {
    let callerFollowsOther = switch (following.get(caller)) {
      case (?m) { m.get(other) != null };
      case (null) { false };
    };
    let otherFollowsCaller = switch (following.get(other)) {
      case (?m) { m.get(caller) != null };
      case (null) { false };
    };
    {
      isMutual = callerFollowsOther and otherFollowsCaller;
      callerFollowsOther;
      otherFollowsCaller;
    };
  };

  /// True when either principal has blocked the other.
  public func isBlockedBidirectional(
    blocks : Map.Map<Principal, Map.Map<Principal, Bool>>,
    a : Principal,
    b : Principal,
  ) : Bool {
    let aBlockedB = switch (blocks.get(a)) {
      case (?m) { m.get(b) != null };
      case (null) { false };
    };
    let bBlockedA = switch (blocks.get(b)) {
      case (?m) { m.get(a) != null };
      case (null) { false };
    };
    aBlockedB or bBlockedA;
  };

  /// Trim leading and trailing whitespace from a message body.
  public func trim(text : Text) : Text {
    text.trim(#predicate(func(c) { c == ' ' or c == '\t' or c == '\n' or c == '\r' }));
  };

  /// Validate a message body and the caller/recipient relationship, returning
  /// the caller-actionable error when the send must be rejected.
  public func validateSend(
    following : Map.Map<Principal, Map.Map<Principal, Bool>>,
    blocks : Map.Map<Principal, Map.Map<Principal, Bool>>,
    caller : Principal,
    recipient : Principal,
    text : Text,
  ) : Result.Result<(), Types.MessagingError> {
    if (caller == recipient) {
      return #err(#selfMessage);
    };
    let body = trim(text);
    if (body.size() == 0) {
      return #err(#emptyMessage);
    };
    if (body.size() > maxMessageLength) {
      return #err(#messageTooLong({ maxLength = maxMessageLength }));
    };
    if (isBlockedBidirectional(blocks, caller, recipient)) {
      return #err(#blocked);
    };
    if (not isMutualFollow(following, caller, recipient)) {
      return #err(#notMutual);
    };
    #ok(());
  };

  /// Build a preview of a message body for the inbox row.
  func preview(text : Text) : Text {
    let body = trim(text);
    if (body.size() > 80) {
      let chars = body.toArray();
      var out = "";
      var i = 0;
      while (i < 80) {
        out #= chars[i].toText();
        i += 1;
      };
      out # "…";
    } else {
      body;
    };
  };

  /// Append a message to a conversation and update the per-participant
  /// conversation index (last-message metadata and unread counters).
  public func sendMessage(
    messages : Map.Map<Types.ConversationId, Map.Map<Nat, Types.Message>>,
    conversations : Map.Map<Principal, Map.Map<Types.ConversationId, Types.ConversationSummary>>,
    nextMessageId : { var value : Nat },
    caller : Principal,
    recipient : Principal,
    text : Text,
  ) : Types.Message {
    let body = trim(text);
    let conversationId = conversationIdFor(caller, recipient);
    let id = nextMessageId.value;
    nextMessageId.value += 1;
    let now = Time.now();

    let message : Types.Message = {
      id;
      conversationId;
      sender = caller;
      recipient;
      text = body;
      createdAt = now;
    };

    let thread = switch (messages.get(conversationId)) {
      case (?m) { m };
      case (null) {
        let m = Map.empty<Nat, Types.Message>();
        messages.add(conversationId, m);
        m;
      };
    };
    thread.add(id, message);

    let previewText = preview(body);

    // Sender's summary: last message is from the caller, unread unchanged.
    let senderSummary = switch (conversations.get(caller)) {
      case (?m) { m };
      case (null) {
        let m = Map.empty<Types.ConversationId, Types.ConversationSummary>();
        conversations.add(caller, m);
        m;
      };
    };
    let senderUnread = switch (senderSummary.get(conversationId)) {
      case (?s) { s.unreadCount };
      case (null) { 0 };
    };
    senderSummary.add(
      conversationId,
      {
        conversationId;
        otherParticipant = recipient;
        otherUsername = "";
        otherDisplayName = "";
        otherProfilePictureHash = null;
        lastMessagePreview = previewText;
        lastMessageAt = now;
        lastMessageFromCaller = true;
        unreadCount = senderUnread;
      },
    );

    // Recipient's summary: last message is from the other party, unread + 1.
    let recipientSummary = switch (conversations.get(recipient)) {
      case (?m) { m };
      case (null) {
        let m = Map.empty<Types.ConversationId, Types.ConversationSummary>();
        conversations.add(recipient, m);
        m;
      };
    };
    let recipientUnread = switch (recipientSummary.get(conversationId)) {
      case (?s) { s.unreadCount };
      case (null) { 0 };
    };
    recipientSummary.add(
      conversationId,
      {
        conversationId;
        otherParticipant = caller;
        otherUsername = "";
        otherDisplayName = "";
        otherProfilePictureHash = null;
        lastMessagePreview = previewText;
        lastMessageAt = now;
        lastMessageFromCaller = false;
        unreadCount = recipientUnread + 1;
      },
    );

    message;
  };

  /// List the caller's conversations, most recent first.
  public func listConversations(
    conversations : Map.Map<Principal, Map.Map<Types.ConversationId, Types.ConversationSummary>>,
    caller : Principal,
  ) : [Types.ConversationSummary] {
    let summaries = switch (conversations.get(caller)) {
      case (?m) { m };
      case (null) { return [] };
    };
    let list = summaries.values().toArray();
    list.sort(
      func(a, b) {
        if (a.lastMessageAt > b.lastMessageAt) { #less } else if (a.lastMessageAt < b.lastMessageAt) {
          #greater;
        } else { #equal };
      }
    );
  };

  /// Fetch a page of a conversation's history, newest first. `before` is an
  /// exclusive cursor on message id; `null` starts from the newest message.
  public func getMessages(
    messages : Map.Map<Types.ConversationId, Map.Map<Nat, Types.Message>>,
    conversations : Map.Map<Principal, Map.Map<Types.ConversationId, Types.ConversationSummary>>,
    caller : Principal,
    conversationId : Types.ConversationId,
    before : ?Nat,
    limit : Nat,
  ) : Types.PaginatedMessages {
    // Caller must participate in the conversation.
    let participates = switch (conversations.get(caller)) {
      case (?m) { m.get(conversationId) != null };
      case (null) { false };
    };
    if (not participates) {
      return { messages = []; nextCursor = null; hasMore = false };
    };

    let thread = switch (messages.get(conversationId)) {
      case (?m) { m };
      case (null) { return { messages = []; nextCursor = null; hasMore = false } };
    };

    let effectiveLimit = if (limit == 0 or limit > 100) { defaultPageSize } else { limit };

    // Newest-first ordering of every message in the thread.
    let ordered = thread.values().toArray().sort(
      func(a, b) {
        if (a.id > b.id) { #less } else if (a.id < b.id) { #greater } else { #equal };
      }
    );

    // `before` is an exclusive cursor; null starts from the newest message.
    let collected = switch (before) {
      case (?cur) { ordered.filter(func(m) { m.id < cur }) };
      case (null) { ordered };
    };

    let hasMore = collected.size() > effectiveLimit;
    let pageSize = if (hasMore) { effectiveLimit } else { collected.size() };
    let slice = collected.sliceToArray(0, pageSize.toInt());
    let nextCursor : ?Nat = if (hasMore and slice.size() > 0) {
      ?slice[slice.size() - 1].id;
    } else {
      null;
    };
    { messages = slice; nextCursor; hasMore };
  };

  /// Mark every message in a conversation as read for the caller and clear the
  /// conversation's unread count.
  public func markConversationRead(
    conversations : Map.Map<Principal, Map.Map<Types.ConversationId, Types.ConversationSummary>>,
    caller : Principal,
    conversationId : Types.ConversationId,
  ) : () {
    switch (conversations.get(caller)) {
      case (?m) {
        switch (m.get(conversationId)) {
          case (?s) {
            if (s.unreadCount != 0) {
              m.add(conversationId, { s with unreadCount = 0 });
            };
          };
          case (null) {};
        };
      };
      case (null) {};
    };
  };

  /// Total unread messages across all of the caller's conversations.
  public func totalUnreadCount(
    conversations : Map.Map<Principal, Map.Map<Types.ConversationId, Types.ConversationSummary>>,
    caller : Principal,
  ) : Nat {
    switch (conversations.get(caller)) {
      case (null) { 0 };
      case (?m) {
        var total : Nat = 0;
        for ((_, s) in m.entries()) {
          total += s.unreadCount;
        };
        total;
      };
    };
  };
};
