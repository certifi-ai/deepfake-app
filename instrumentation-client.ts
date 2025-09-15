// This file configures the initialization of Sentry on the client.
// The config you add here will be used whenever a users loads a page in their browser.
// https://docs.sentry.io/platforms/javascript/guides/nextjs/
export const ANONYMOUS_USER_ID = "anonymousanonymousanonymo"
export const ANONYMOUS_USER_NAME = "All Anonymous Users"

import * as Sentry from "@sentry/nextjs"


Sentry.init({
  dsn: "https://04ae800f4566c2161260c6681398b3c5@o4507567500296192.ingest.us.sentry.io/4507567501475840",

  // Adjust this value in production, or use tracesSampler for greater control
  tracesSampleRate: 1,

  // Setting this option to true will print useful information to the console while you're setting up Sentry.
  debug: false,

  replaysOnErrorSampleRate: 1.0,

  // This sets the sample rate to be 10%. You may want this to be 100% while
  // in development and sample at a lower rate in production
  replaysSessionSampleRate: 0.1,

  // You can remove this option if you're not planning to use the Sentry Session Replay feature:
  integrations: [
    // eslint-disable-next-line import/namespace
    Sentry.replayIntegration({
      // Additional Replay configuration goes in here, for example:
      maskAllText: true,
      blockAllMedia: true,
    }),
  ],

  ignoreErrors: ["ClerkJS: Token refresh failed (error='ClerkJS: Network error"],
})

export async function register() {
  if (process.env.NEXT_RUNTIME === "nodejs") {
    await import("./sentry.server.config")
  }

  if (process.env.NEXT_RUNTIME === "edge") {
    await import("./sentry.edge.config")
  }
}
import * as Sentry from "@sentry/nextjs";

export const onRequestError = Sentry.captureRequestError;
export const onRouterTransitionStart = Sentry.captureRouterTransitionStart;

