import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar";
import { Button } from "@/components/ui/button";
import { Skeleton } from "@/components/ui/skeleton";
import { Textarea } from "@/components/ui/textarea";
import { cn } from "@/lib/utils";
import { useInternetIdentity } from "@caffeineai/core-infrastructure";
import { Principal } from "@icp-sdk/core/principal";
import { Link, getRouteApi } from "@tanstack/react-router";
import { format, formatDistanceToNow } from "date-fns";
import { Loader2, Lock, Send, UserX } from "lucide-react";
import type { KeyboardEvent } from "react";
import { useEffect, useMemo, useRef, useState } from "react";
import { toast } from "sonner";
import { useInfiniteScroll } from "../hooks/useInfiniteScroll";
import {
  useConversations,
  useMarkConversationRead,
  useMessages,
  useMutualFollowStatus,
  useSendMessage,
} from "../hooks/useMessaging";
import { useProfileByUsername } from "../hooks/useQueries";
import { fromNanoseconds, getInitials } from "../utils/formatting";
import type { Message } from "../utils/types";
import { BackButton } from "./BackButton";

const routeApi = getRouteApi("/messages/$username");

function buildConversationId(a: string, b: string): string {
  // Match the backend's canonical ordering (Principal.compare, raw bytes)
  // rather than lexicographic string comparison.
  const principalA = Principal.fromText(a);
  const principalB = Principal.fromText(b);
  return principalA.compareTo(principalB) === "gt" ? `${b}:${a}` : `${a}:${b}`;
}

export default function ConversationPage() {
  const { username } = routeApi.useParams();
  const { identity } = useInternetIdentity();
  const callerPrincipal = identity?.getPrincipal() ?? null;

  const {
    data: profile,
    isLoading: isLoadingProfile,
    isError: isProfileError,
  } = useProfileByUsername(username);

  const otherPrincipal = profile?.principal ?? null;

  const { data: mutualStatus, isLoading: isLoadingMutual } =
    useMutualFollowStatus(otherPrincipal);

  const { data: conversations } = useConversations();

  // Prefer the backend-provided conversation id; fall back to the canonical
  // ordering of the two principals for a thread with no messages yet.
  const conversationId = useMemo(() => {
    if (!callerPrincipal || !otherPrincipal) return null;
    const existing = conversations?.find(
      (c) => c.otherUsername.toLowerCase() === username.toLowerCase(),
    );
    if (existing) return existing.conversationId;
    return buildConversationId(
      callerPrincipal.toText(),
      otherPrincipal.toText(),
    );
  }, [callerPrincipal, otherPrincipal, conversations, username]);

  const {
    data: messagesData,
    isLoading: isLoadingMessages,
    isError: isMessagesError,
    hasNextPage,
    fetchNextPage,
    isFetchingNextPage,
  } = useMessages(conversationId);

  const { mutate: markRead } = useMarkConversationRead();
  const { mutate: sendMessage, isPending: isSending } = useSendMessage();

  const [draft, setDraft] = useState("");
  const scrollRef = useRef<HTMLDivElement>(null);
  const bottomRef = useRef<HTMLDivElement>(null);
  const didInitialScroll = useRef(false);

  // Newest-first pages flattened, then reversed for chronological display.
  const messages: Message[] = useMemo(() => {
    const flat = messagesData?.pages.flatMap((page) => page.messages) ?? [];
    return [...flat].reverse();
  }, [messagesData]);

  // Mark the conversation read once the thread is open.
  useEffect(() => {
    if (conversationId) {
      markRead(conversationId);
    }
  }, [conversationId, markRead]);

  // Jump to the newest message on first load.
  useEffect(() => {
    if (
      !isLoadingMessages &&
      messages.length > 0 &&
      !didInitialScroll.current
    ) {
      didInitialScroll.current = true;
      bottomRef.current?.scrollIntoView({ block: "end" });
    }
  }, [isLoadingMessages, messages.length]);

  // Load older messages when the user scrolls near the top.
  const topSentinelRef = useInfiniteScroll({
    hasNextPage,
    isFetchingNextPage,
    fetchNextPage,
    rootMargin: "300px",
  });

  const isMutual = mutualStatus?.isMutual ?? false;
  const canMessage = isMutual && !!otherPrincipal;

  const handleSend = () => {
    const text = draft.trim();
    if (!text || !otherPrincipal || isSending) return;
    setDraft("");
    sendMessage(
      { recipient: otherPrincipal, text },
      {
        onError: (error) => {
          setDraft((current) => (current === "" ? text : current));
          toast.error(error.message || "Failed to send message");
        },
      },
    );
  };

  const handleKeyDown = (event: KeyboardEvent<HTMLTextAreaElement>) => {
    if (event.key === "Enter" && !event.shiftKey) {
      event.preventDefault();
      handleSend();
    }
  };

  if (isLoadingProfile) {
    return (
      <div>
        <div className="sticky top-0 z-10 flex items-center gap-3 border-b bg-background/80 px-4 py-2 backdrop-blur-sm">
          <BackButton />
          <Skeleton className="h-9 w-9 rounded-full" />
          <div className="space-y-1.5">
            <Skeleton className="h-4 w-28" />
            <Skeleton className="h-3 w-20" />
          </div>
        </div>
        <div className="space-y-4 p-4">
          <Skeleton className="h-10 w-2/3 rounded-2xl" />
          <Skeleton className="ml-auto h-10 w-1/2 rounded-2xl" />
          <Skeleton className="h-10 w-3/5 rounded-2xl" />
        </div>
      </div>
    );
  }

  if (isProfileError || !profile) {
    return (
      <div className="flex flex-col items-center px-8 py-20 text-center">
        <div className="mb-4 flex h-16 w-16 items-center justify-center rounded-full bg-muted">
          <UserX className="h-8 w-8 text-muted-foreground" />
        </div>
        <p className="text-lg font-semibold">This account doesn't exist</p>
        <p className="mt-1 text-sm text-muted-foreground">
          Try searching for another person.
        </p>
        <BackButton variant="link" label="Go back" className="mt-4" />
      </div>
    );
  }

  const otherInitials = getInitials(profile.displayName);
  const otherPictureUrl = profile.profilePictureHash
    ? profile.profilePictureHash.getDirectURL()
    : null;

  return (
    <div className="flex h-full min-h-0 flex-col">
      {/* Header */}
      <div className="flex shrink-0 items-center gap-3 border-b bg-background/80 px-4 py-2 backdrop-blur-sm">
        <BackButton />
        <Link
          to="/$username"
          params={{ username: profile.username }}
          className="flex min-w-0 items-center gap-3 transition-opacity hover:opacity-80"
        >
          <Avatar className="h-9 w-9 shrink-0">
            {otherPictureUrl && (
              <AvatarImage
                src={otherPictureUrl}
                alt={profile.displayName}
                className="object-cover"
              />
            )}
            <AvatarFallback className="text-xs">{otherInitials}</AvatarFallback>
          </Avatar>
          <div className="min-w-0">
            <p className="truncate text-sm font-semibold leading-tight">
              {profile.displayName}
            </p>
            <p className="truncate text-xs text-muted-foreground">
              @{profile.username}
            </p>
          </div>
        </Link>
      </div>

      {/* Thread */}
      <div
        ref={scrollRef}
        className="min-h-0 flex-1 overflow-y-auto"
        data-ocid="conversation.thread"
      >
        {isLoadingMutual ? (
          <div className="flex justify-center py-10">
            <Loader2 className="h-6 w-6 animate-spin text-muted-foreground" />
          </div>
        ) : !canMessage ? (
          <div
            className="flex flex-col items-center px-8 py-16 text-center"
            data-ocid="conversation.locked_state"
          >
            <div className="mb-4 flex h-16 w-16 items-center justify-center rounded-full bg-primary/10">
              <Lock className="h-8 w-8 text-primary" />
            </div>
            <p className="text-lg font-semibold">
              You can't message @{profile.username} yet
            </p>
            <p className="mx-auto mt-1 max-w-xs text-sm text-muted-foreground">
              {mutualStatus?.callerFollowsOther &&
              !mutualStatus?.otherFollowsCaller
                ? `Waiting for @${profile.username} to follow you back. Messaging unlocks once you follow each other.`
                : `Follow @${profile.username} and have them follow you back to start a conversation.`}
            </p>
            <Link
              to="/$username"
              params={{ username: profile.username }}
              className="mt-4 inline-flex items-center gap-2 rounded-full bg-primary px-4 py-2 text-sm font-medium text-primary-foreground transition-opacity hover:opacity-90"
              data-ocid="conversation.view_profile_link"
            >
              View profile
            </Link>
          </div>
        ) : (
          <>
            <div ref={topSentinelRef} className="h-1" />
            {isFetchingNextPage && (
              <div className="flex justify-center py-3">
                <Loader2 className="h-5 w-5 animate-spin text-muted-foreground" />
              </div>
            )}

            {isLoadingMessages ? (
              <div className="space-y-4 p-4">
                <Skeleton className="h-10 w-2/3 rounded-2xl" />
                <Skeleton className="ml-auto h-10 w-1/2 rounded-2xl" />
                <Skeleton className="h-10 w-3/5 rounded-2xl" />
              </div>
            ) : isMessagesError ? (
              <p
                className="p-4 text-center text-destructive"
                data-ocid="conversation.error_state"
              >
                Failed to load messages.
              </p>
            ) : messages.length === 0 ? (
              <div
                className="flex flex-col items-center px-8 py-16 text-center"
                data-ocid="conversation.empty_state"
              >
                <div className="mb-4 flex h-16 w-16 items-center justify-center rounded-full bg-primary/10">
                  <Send className="h-8 w-8 text-primary" />
                </div>
                <p className="text-lg font-semibold">
                  Say hello to @{profile.username}
                </p>
                <p className="mx-auto mt-1 max-w-xs text-sm text-muted-foreground">
                  This is the beginning of your conversation. Send the first
                  message below.
                </p>
              </div>
            ) : (
              <ul className="flex flex-col gap-2 px-4 py-4">
                {messages.map((message, index) => {
                  const isMine =
                    !!callerPrincipal &&
                    message.sender.toText() === callerPrincipal.toText();
                  const previous = messages[index - 1];
                  const showTimestamp =
                    !previous ||
                    fromNanoseconds(message.createdAt).getTime() -
                      fromNanoseconds(previous.createdAt).getTime() >
                      5 * 60 * 1000;

                  return (
                    <li
                      key={message.id.toString()}
                      className={cn(
                        "flex flex-col",
                        isMine ? "items-end" : "items-start",
                      )}
                      data-ocid={`conversation.message.${index + 1}`}
                    >
                      {showTimestamp && (
                        <span className="mb-1 px-1 text-[11px] text-muted-foreground">
                          {format(
                            fromNanoseconds(message.createdAt),
                            "MMM d, h:mm a",
                          )}
                        </span>
                      )}
                      <div
                        className={cn(
                          "max-w-[80%] whitespace-pre-wrap break-words rounded-2xl px-3.5 py-2 text-sm",
                          isMine
                            ? "rounded-br-sm bg-primary text-primary-foreground"
                            : "rounded-bl-sm bg-muted text-foreground",
                        )}
                        title={formatDistanceToNow(
                          fromNanoseconds(message.createdAt),
                          { addSuffix: true },
                        )}
                      >
                        {message.text}
                      </div>
                    </li>
                  );
                })}
              </ul>
            )}
            <div ref={bottomRef} />
          </>
        )}
      </div>

      {/* Composer */}
      {canMessage && (
        <div className="shrink-0 border-t bg-background px-4 py-3">
          <div className="flex items-end gap-2">
            <Textarea
              value={draft}
              onChange={(event) => setDraft(event.target.value)}
              onKeyDown={handleKeyDown}
              placeholder={`Message @${profile.username}`}
              rows={1}
              className="max-h-32 min-h-10 flex-1 resize-none rounded-2xl"
              aria-label={`Message @${profile.username}`}
              data-ocid="conversation.composer_input"
            />
            <Button
              type="button"
              size="icon"
              className="h-10 w-10 shrink-0 rounded-full"
              onClick={handleSend}
              disabled={isSending || draft.trim().length === 0}
              aria-label="Send message"
              data-ocid="conversation.send_button"
            >
              {isSending ? (
                <Loader2 className="h-4 w-4 animate-spin" />
              ) : (
                <Send className="h-4 w-4" />
              )}
            </Button>
          </div>
        </div>
      )}
    </div>
  );
}
