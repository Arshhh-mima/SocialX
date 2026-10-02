import { cn } from "@/lib/utils";
import { useInternetIdentity } from "@caffeineai/core-infrastructure";
import { Heart, Loader2, MessageCircle, Repeat2 } from "lucide-react";
import { ThemeToggle } from "./ThemeToggle";

interface MockPostData {
  initials: string;
  name: string;
  handle: string;
  time: string;
  text: string;
  likes: number;
  replies: number;
  reposts: number;
  color: string;
}

function GoogleIcon() {
  return (
    <svg className="h-4 w-4" viewBox="0 0 24 24" aria-hidden="true">
      <path
        fill="#4285F4"
        d="M23.52 12.27c0-.85-.08-1.66-.22-2.45H12v4.63h6.46a5.52 5.52 0 0 1-2.4 3.62v3h3.88c2.27-2.09 3.58-5.17 3.58-8.8z"
      />
      <path
        fill="#34A853"
        d="M12 24c3.24 0 5.96-1.07 7.94-2.91l-3.88-3.01c-1.07.72-2.45 1.15-4.06 1.15-3.13 0-5.78-2.11-6.72-4.95H1.27v3.11A12 12 0 0 0 12 24z"
      />
      <path
        fill="#FBBC05"
        d="M5.28 14.28A7.2 7.2 0 0 1 4.9 12c0-.79.14-1.56.38-2.28V6.61H1.27a12 12 0 0 0 0 10.78l4.01-3.11z"
      />
      <path
        fill="#EA4335"
        d="M12 4.77c1.76 0 3.35.61 4.6 1.8l3.44-3.44A11.97 11.97 0 0 0 12 0 12 12 0 0 0 1.27 6.61l4.01 3.11C6.22 6.88 8.87 4.77 12 4.77z"
      />
    </svg>
  );
}

function InternetIdentityIcon({ className }: { className?: string }) {
  return (
    <svg
      className={className}
      viewBox="0 0 24 12"
      fill="none"
      aria-hidden="true"
    >
      <path
        d="M23.9996 5.73913C23.9996 2.57459 21.3805 0 18.1664 0C16.8264 0 15.3672 0.69587 13.8214 2.06778C13.0906 2.71638 12.4569 3.41014 11.981 3.96802C10.3102 2.08297 8.06944 0 5.83323 0C3.13036 0 0.77332 1.8956 0.159997 4.40731C0.160831 4.4052 0.161664 4.40225 0.162497 4.3993C0.161664 4.40225 0.160831 4.40478 0.159997 4.40731C0.0554157 4.83522 0 5.28127 0 5.73913C0 8.90367 2.57746 11.4783 5.79157 11.4783C7.13154 11.4783 8.63235 10.7824 10.1782 9.41049C10.909 8.76188 11.5427 8.06812 12.0185 7.51024C13.6893 9.39529 15.9306 11.4783 18.1668 11.4783C20.8696 11.4783 23.2267 9.58266 23.84 7.07137C23.9446 6.64347 24 6.19742 24 5.73955L23.9996 5.73913ZM12.4294 3.96211C12.9756 3.33798 13.5173 2.78685 14.0414 2.32182C15.5247 1.00519 16.9126 0.337596 18.1664 0.337596C21.1992 0.337596 23.6663 2.76069 23.6663 5.73913C23.6663 6.15691 23.6167 6.57426 23.5183 6.98022C23.5025 7.02706 23.3004 7.58747 22.7246 8.13226C21.9767 8.83995 20.963 9.19907 19.7113 9.19949C21.0576 8.60701 21.9992 7.27604 21.9992 5.73913C21.9992 3.64983 20.2796 1.95046 18.1664 1.95046C17.3426 1.95046 16.3343 2.475 15.1681 3.51015C14.6435 3.97604 14.1123 4.52379 13.5514 5.1783L13.3314 5.43403L12.2044 4.2132L12.4294 3.96253V3.96211ZM10.4357 5.79568C9.99066 6.33077 9.349 7.05997 8.61152 7.71449C7.23737 8.93448 6.34406 9.1902 5.83323 9.1902C3.90577 9.1902 2.33371 7.64191 2.33371 5.73913C2.33371 3.83636 3.9041 2.29987 5.83323 2.28806C5.90323 2.28806 5.98781 2.29523 6.09031 2.3138C7.08446 2.69992 7.97236 3.31604 8.5086 3.81315C8.93985 4.2132 9.72108 5.03187 10.4352 5.79526L10.4357 5.79568ZM11.5702 7.51615C11.0236 8.14028 10.4823 8.69141 9.95816 9.15644C8.49569 10.4545 7.05488 11.1407 5.79157 11.1407C4.32701 11.1407 2.9537 10.5773 1.92372 9.55439C0.897901 8.53569 0.333328 7.18067 0.333328 5.73913C0.333328 5.32136 0.383327 4.90358 0.481242 4.49804C0.497908 4.44951 0.699988 3.88995 1.27498 3.346C2.02288 2.63831 3.03661 2.27919 4.28826 2.27877C2.94203 2.87125 2.00038 4.20223 2.00038 5.73913C2.00038 7.82843 3.71994 9.5278 5.83323 9.5278C6.65697 9.5278 7.66528 9.00326 8.83151 7.96811C9.35609 7.50223 9.88733 6.95448 10.4482 6.29996L10.6677 6.04381C10.6677 6.04381 11.7781 7.2465 11.7902 7.26L11.5698 7.51615H11.5702ZM13.5639 5.68258C14.0089 5.14749 14.6506 4.41829 15.3881 3.76377C16.7622 2.54379 17.6555 2.28806 18.1664 2.28806C20.0938 2.28806 21.6659 3.83636 21.6659 5.73913C21.6659 7.64191 20.0955 9.17839 18.1664 9.1902C18.0964 9.1902 18.0118 9.18303 17.9089 9.16446C17.9097 9.16446 17.9101 9.16489 17.9109 9.16531C16.916 8.77918 16.0272 8.16265 15.4906 7.66512C15.0593 7.26506 14.2781 6.44639 13.5635 5.683L13.5639 5.68258ZM23.8375 7.07728C23.8383 7.07517 23.8388 7.07263 23.8396 7.07095C23.8392 7.07263 23.8383 7.07517 23.8375 7.07728Z"
        fill="currentColor"
      />
    </svg>
  );
}

const FEED_POSTS: MockPostData[] = [
  {
    initials: "AK",
    name: "Anna K",
    handle: "dev_anna",
    time: "2h",
    text: "Just deployed my first canister on ICP! The future is decentralized",
    likes: 12,
    replies: 3,
    reposts: 1,
    color: "bg-sky-600",
  },
  {
    initials: "MR",
    name: "Maya R",
    handle: "maya",
    time: "1h",
    text: "Your data should belong to you, not a corporation",
    likes: 45,
    replies: 8,
    reposts: 12,
    color: "bg-rose-600",
  },
  {
    initials: "SD",
    name: "Sam Davis",
    handle: "indie_dev",
    time: "30m",
    text: "Building in public, day 47. Almost ready to launch",
    likes: 7,
    replies: 2,
    reposts: 0,
    color: "bg-emerald-600",
  },
  {
    initials: "CP",
    name: "Chris P",
    handle: "chrisfoto",
    time: "3h",
    text: "Beautiful sunset from my balcony today #photography",
    likes: 19,
    replies: 0,
    reposts: 2,
    color: "bg-violet-600",
  },
];

function MockFeedPost({
  post,
  isLast,
}: {
  post: MockPostData;
  isLast?: boolean;
}) {
  return (
    <div
      className={cn("flex items-start gap-3 px-4 py-3", !isLast && "border-b")}
    >
      <div
        className={`h-10 w-10 rounded-full flex items-center justify-center text-xs font-semibold text-white shrink-0 ${post.color}`}
      >
        {post.initials}
      </div>
      <div className="min-w-0 flex-1">
        <div className="flex items-center gap-1 text-sm">
          <span className="font-semibold text-card-foreground truncate">
            {post.name}
          </span>
          <span className="text-muted-foreground truncate">@{post.handle}</span>
          <span className="text-muted-foreground shrink-0">· {post.time}</span>
        </div>
        <p className="mt-0.5 text-sm text-card-foreground leading-snug">
          {post.text}
        </p>
        <div className="mt-2 flex items-center gap-6 text-muted-foreground">
          <span className="flex items-center gap-1 text-xs">
            <MessageCircle className="h-4 w-4" />
            {post.replies > 0 && post.replies}
          </span>
          <span className="flex items-center gap-1 text-xs">
            <Repeat2 className="h-4 w-4" />
            {post.reposts > 0 && post.reposts}
          </span>
          <span className="flex items-center gap-1 text-xs">
            <Heart className="h-4 w-4" />
            {post.likes > 0 && post.likes}
          </span>
        </div>
      </div>
    </div>
  );
}

export function LandingPage() {
  const { login, isInitializing, isLoggingIn, isLoginError, loginError } =
    useInternetIdentity();
  const disabled = isInitializing || isLoggingIn;

  return (
    <div className="h-dvh overflow-hidden bg-landing relative flex flex-col">
      {/* Top bar */}
      <header className="shrink-0 px-6 sm:px-10 lg:px-16 py-5 flex items-center justify-between max-w-7xl mx-auto w-full animate-fade-up">
        <span className="text-xl font-bold text-foreground tracking-tight">
          MicroBlog
        </span>
        <ThemeToggle />
      </header>

      {/* Hero */}
      <main className="flex-1 flex flex-col items-center justify-center text-center px-6 min-h-0">
        <h1 className="font-display text-3xl sm:text-5xl md:text-6xl lg:text-7xl font-extrabold text-foreground leading-[1.05] tracking-[-0.03em] animate-fade-up-delay-1">
          Share what matters.
        </h1>

        <p className="mt-4 sm:mt-6 text-muted-foreground text-sm sm:text-base md:text-lg max-w-sm mx-auto leading-relaxed animate-fade-up-delay-2">
          Share thoughts, spark conversations, and own your content on the
          decentralized web.
        </p>

        <div className="mt-5 sm:mt-8 flex w-full max-w-xs flex-col items-center gap-3 animate-fade-up-delay-3">
          <button
            type="button"
            onClick={() => login({ provider: "google" })}
            disabled={disabled}
            className="flex w-full items-center justify-center whitespace-nowrap rounded-full bg-foreground text-landing px-4 py-3 text-sm font-medium transition-opacity hover:opacity-90 disabled:opacity-50 disabled:cursor-not-allowed"
          >
            {isLoggingIn ? (
              <span className="flex items-center gap-2">
                <Loader2 className="h-4 w-4 animate-spin" />
                Signing in...
              </span>
            ) : (
              <span className="flex items-center gap-2">
                <span className="flex h-6 w-6 shrink-0 items-center justify-center rounded-full bg-white">
                  <GoogleIcon />
                </span>
                Continue with Google
              </span>
            )}
          </button>

          <button
            type="button"
            onClick={() => login()}
            disabled={disabled}
            className="flex w-full items-center justify-center gap-2.5 whitespace-nowrap rounded-full bg-card text-card-foreground border shadow-sm px-4 py-3 text-sm font-semibold transition-colors hover:bg-secondary disabled:opacity-50 disabled:cursor-not-allowed"
          >
            <InternetIdentityIcon className="h-3 w-6 shrink-0" />
            Sign in with Internet Identity
          </button>

          {isLoginError && (
            <p className="text-destructive text-xs">
              {loginError?.message ?? "Sign-in failed. Please try again."}
            </p>
          )}

          <span className="text-muted-foreground text-xs">
            &copy; 2026. Built with ❤️ using{" "}
            <a
              href="https://caffeine.ai"
              target="_blank"
              rel="noopener noreferrer"
              className="underline underline-offset-2 hover:text-foreground transition-colors"
            >
              caffeine.ai
            </a>
          </span>
        </div>
      </main>

      {/* Feed preview */}
      <div className="shrink-0 px-4 sm:px-10 lg:px-16 max-w-3xl mx-auto w-full animate-fade-up-delay-3">
        <div className="rounded-t-2xl border border-b-0 bg-card shadow-2xl overflow-hidden">
          {/* Tab bar */}
          <div className="flex border-b">
            <div className="flex-1 py-3 text-sm font-semibold text-center text-foreground border-b-2 border-primary">
              For You
            </div>
            <div className="flex-1 py-3 text-sm font-medium text-center text-muted-foreground">
              Following
            </div>
          </div>
          {/* Mock posts - show 2 on mobile, all on sm+ */}
          {FEED_POSTS.map((post, i) => (
            <div key={post.handle} className={cn(i >= 2 && "hidden sm:block")}>
              <MockFeedPost post={post} isLast={i === FEED_POSTS.length - 1} />
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}
