import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar";
import { Skeleton } from "@/components/ui/skeleton";
import { cn } from "@/lib/utils";
import { Link } from "@tanstack/react-router";
import { formatDistanceToNow } from "date-fns";
import { Mail, MessageSquarePlus } from "lucide-react";
import { useConversations } from "../hooks/useMessaging";
import { fromNanoseconds, getInitials } from "../utils/formatting";
import { BackButton } from "./BackButton";

export default function MessagesPage() {
  const { data: conversations, isLoading, isError } = useConversations();

  const sorted = [...(conversations ?? [])].sort((a, b) =>
    a.lastMessageAt === b.lastMessageAt
      ? 0
      : a.lastMessageAt > b.lastMessageAt
        ? -1
        : 1,
  );

  return (
    <div>
      <div className="sticky top-0 z-10 border-b bg-background/80 backdrop-blur-sm">
        <div className="flex items-center gap-2 px-4 py-3">
          <BackButton className="shrink-0" />
          <h1 className="flex-1 text-lg font-semibold">Messages</h1>
        </div>
      </div>

      {isLoading ? (
        <div className="space-y-1" data-ocid="messages.loading_state">
          {Array.from({ length: 6 }, (_, i) => `messages-skeleton-${i}`).map(
            (id) => (
              <div key={id} className="flex items-center gap-3 px-4 py-3">
                <Skeleton className="h-12 w-12 shrink-0 rounded-full" />
                <div className="flex-1 space-y-2">
                  <Skeleton className="h-4 w-1/3" />
                  <Skeleton className="h-3 w-2/3" />
                </div>
              </div>
            ),
          )}
        </div>
      ) : isError ? (
        <p
          className="p-4 text-center text-destructive"
          data-ocid="messages.error_state"
        >
          Failed to load conversations.
        </p>
      ) : sorted.length === 0 ? (
        <div
          className="flex flex-col items-center px-8 py-20 text-center"
          data-ocid="messages.empty_state"
        >
          <div className="mb-4 flex h-16 w-16 items-center justify-center rounded-full bg-primary/10">
            <Mail className="h-8 w-8 text-primary" />
          </div>
          <p className="text-lg font-semibold">No conversations yet</p>
          <p className="mx-auto mt-1 max-w-xs text-sm text-muted-foreground">
            Messaging unlocks once you and another person follow each other.
            Follow someone back and start a conversation.
          </p>
          <Link
            to="/search"
            search={{ q: "" }}
            className="mt-4 inline-flex items-center gap-2 rounded-full bg-primary px-4 py-2 text-sm font-medium text-primary-foreground transition-opacity hover:opacity-90"
            data-ocid="messages.find_people_link"
          >
            <MessageSquarePlus className="h-4 w-4" />
            Find people to follow
          </Link>
        </div>
      ) : (
        <ul data-ocid="messages.list">
          {sorted.map((conversation, index) => {
            const timeAgo = formatDistanceToNow(
              fromNanoseconds(conversation.lastMessageAt),
              { addSuffix: true },
            );
            const hasUnread = conversation.unreadCount > 0n;
            const preview = conversation.lastMessageFromCaller
              ? `You: ${conversation.lastMessagePreview}`
              : conversation.lastMessagePreview;
            // The backend leaves otherUsername empty when the other
            // participant has no profile; fall back to the principal text so
            // the row still links to a reachable thread.
            const otherUsername =
              conversation.otherUsername ||
              conversation.otherParticipant.toText();

            return (
              <li key={conversation.conversationId}>
                <Link
                  to="/messages/$username"
                  params={{ username: otherUsername }}
                  className={cn(
                    "flex items-center gap-3 border-b px-4 py-3 transition-colors hover:bg-muted/50",
                    hasUnread && "bg-primary/5",
                  )}
                  data-ocid={`messages.row.${index + 1}`}
                >
                  <Avatar className="h-12 w-12 shrink-0">
                    {conversation.otherProfilePictureHash && (
                      <AvatarImage
                        src={conversation.otherProfilePictureHash.getDirectURL()}
                        alt={conversation.otherDisplayName}
                        className="object-cover"
                      />
                    )}
                    <AvatarFallback className="text-sm">
                      {getInitials(conversation.otherDisplayName)}
                    </AvatarFallback>
                  </Avatar>

                  <div className="min-w-0 flex-1">
                    <div className="flex items-baseline gap-2">
                      <p
                        className={cn(
                          "truncate text-sm",
                          hasUnread ? "font-bold" : "font-semibold",
                        )}
                      >
                        {conversation.otherDisplayName}
                      </p>
                      <span className="shrink-0 text-xs text-muted-foreground">
                        {conversation.otherUsername
                          ? `@${conversation.otherUsername}`
                          : ""}
                      </span>
                      <span className="ml-auto shrink-0 text-xs text-muted-foreground">
                        {timeAgo}
                      </span>
                    </div>
                    <div className="mt-0.5 flex items-center gap-2">
                      <p
                        className={cn(
                          "min-w-0 flex-1 truncate text-sm",
                          hasUnread
                            ? "font-medium text-foreground"
                            : "text-muted-foreground",
                        )}
                      >
                        {preview}
                      </p>
                      {hasUnread && (
                        <span
                          className="flex h-5 min-w-5 shrink-0 items-center justify-center rounded-full bg-primary px-1.5 text-[11px] font-semibold text-primary-foreground"
                          data-ocid={`messages.unread_badge.${index + 1}`}
                        >
                          {conversation.unreadCount > 99n
                            ? "99+"
                            : conversation.unreadCount.toString()}
                        </span>
                      )}
                    </div>
                  </div>
                </Link>
              </li>
            );
          })}
        </ul>
      )}
    </div>
  );
}
