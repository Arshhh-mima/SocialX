import { useActor, useInternetIdentity } from "@caffeineai/core-infrastructure";
import type { Principal } from "@icp-sdk/core/principal";
import {
  type InfiniteData,
  useInfiniteQuery,
  useMutation,
  useQuery,
  useQueryClient,
} from "@tanstack/react-query";
import { toast } from "sonner";
import { createActor } from "../backend";
import type {
  ConversationId,
  ConversationSummary,
  Message,
  MessagingError,
  MutualFollowStatus,
  PaginatedMessages,
} from "../utils/types";

const DEFAULT_PAGE_SIZE = 20n;

export function describeMessagingError(error: MessagingError): string {
  switch (error.__kind__) {
    case "notMutual":
      return "You can only message people who follow you back.";
    case "blocked":
      return "You can't message this person.";
    case "selfMessage":
      return "You can't message yourself.";
    case "emptyMessage":
      return "Write a message before sending.";
    case "messageTooLong":
      return `Messages can be at most ${error.messageTooLong.maxLength} characters.`;
    case "recipientNotFound":
      return "That person could not be found.";
    default:
      return "Something went wrong. Please try again.";
  }
}

export function useConversations() {
  const { actor, isFetching } = useActor(createActor);

  return useQuery({
    queryKey: ["conversations"],
    queryFn: async () => {
      if (!actor) throw new Error("Actor not ready");
      return actor.getConversations();
    },
    enabled: !!actor && !isFetching,
    refetchInterval: 15_000,
  });
}

export function useMessages(conversationId: ConversationId | null) {
  const { actor, isFetching } = useActor(createActor);

  return useInfiniteQuery({
    queryKey: ["messages", conversationId],
    queryFn: async ({ pageParam }) => {
      if (!actor || conversationId === null) throw new Error("Actor not ready");
      return actor.getMessages(conversationId, pageParam, DEFAULT_PAGE_SIZE);
    },
    initialPageParam: null as bigint | null,
    getNextPageParam: (lastPage) => lastPage.nextCursor ?? undefined,
    enabled: !!actor && !isFetching && conversationId !== null,
  });
}

export function useSendMessage() {
  const { actor } = useActor(createActor);
  const { identity } = useInternetIdentity();
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async ({
      recipient,
      text,
    }: {
      recipient: Principal;
      text: string;
    }) => {
      if (!actor) throw new Error("Actor not ready");
      const result = await actor.sendMessage(recipient, text);
      if (result.__kind__ === "err") {
        throw new Error(describeMessagingError(result.err));
      }
      return result.ok;
    },
    onMutate: async ({ recipient, text }) => {
      await queryClient.cancelQueries({ queryKey: ["messages"] });
      const snapshots = queryClient.getQueriesData<
        InfiniteData<PaginatedMessages, bigint | null>
      >({ queryKey: ["messages"] });

      const caller = identity?.getPrincipal() ?? recipient;
      const optimistic: Message = {
        id: -BigInt(Date.now()),
        conversationId: "",
        sender: caller,
        recipient,
        text,
        createdAt: BigInt(Date.now()) * 1_000_000n,
      };

      // Scope the optimistic append to the thread for this recipient only.
      // A bare ["messages"] key would match every cached conversation.
      queryClient.setQueriesData<
        InfiniteData<PaginatedMessages, bigint | null>
      >(
        {
          queryKey: ["messages"],
          predicate: (query) => {
            const key = query.queryKey;
            if (key.length < 2 || typeof key[1] !== "string") return false;
            return key[1].includes(recipient.toText());
          },
        },
        (old) => {
          if (!old?.pages?.length) return old;
          // Pages are newest-first, so the newest page is index 0. The
          // thread flattens pages then reverses, so the new message must be
          // prepended to the newest page to land at the bottom of the thread.
          const pages = [...old.pages];
          const newestPage = pages[0];
          pages[0] = {
            ...newestPage,
            messages: [optimistic, ...newestPage.messages],
          };
          return { ...old, pages };
        },
      );

      return { snapshots };
    },
    onError: (error, _variables, context) => {
      if (context?.snapshots) {
        for (const [key, data] of context.snapshots) {
          queryClient.setQueryData(key, data);
        }
      }
      toast.error(error.message || "Failed to send message");
    },
    onSettled: () => {
      queryClient.invalidateQueries({ queryKey: ["messages"] });
      queryClient.invalidateQueries({ queryKey: ["conversations"] });
      queryClient.invalidateQueries({ queryKey: ["unreadMessageCount"] });
    },
  });
}

export function useMarkConversationRead() {
  const { actor } = useActor(createActor);
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async (conversationId: ConversationId) => {
      if (!actor) throw new Error("Actor not ready");
      await actor.markConversationRead(conversationId);
    },
    onSettled: () => {
      queryClient.invalidateQueries({ queryKey: ["conversations"] });
      queryClient.invalidateQueries({ queryKey: ["unreadMessageCount"] });
    },
  });
}

export function useUnreadMessageCount() {
  const { actor, isFetching } = useActor(createActor);

  return useQuery({
    queryKey: ["unreadMessageCount"],
    queryFn: async () => {
      if (!actor) throw new Error("Actor not ready");
      return actor.getUnreadMessageCount();
    },
    enabled: !!actor && !isFetching,
    refetchInterval: 30_000,
  });
}

export function useMutualFollowStatus(other: Principal | null) {
  const { actor, isFetching } = useActor(createActor);

  return useQuery({
    queryKey: ["mutualFollowStatus", other?.toString()],
    queryFn: async () => {
      if (!actor || !other) throw new Error("Actor not ready");
      return actor.getMutualFollowStatus(other);
    },
    enabled: !!actor && !isFetching && !!other,
  });
}

export type {
  ConversationSummary,
  Message,
  MutualFollowStatus,
  PaginatedMessages,
};
