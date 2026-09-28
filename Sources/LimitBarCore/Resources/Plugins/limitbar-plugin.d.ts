/** A secret header bound to one declared origin; reject with its opaque ID to advance safely. */
interface LimitBarCookieSession {
  readonly id: string;
  readonly header: string;
  readonly source: string;
  readonly origin: string;
  readonly cachedAt?: number;
}

type LimitBarJSONPrimitive = boolean | number | string | null;
type LimitBarJSONValue = LimitBarJSONPrimitive | LimitBarJSONValue[] | { [key: string]: LimitBarJSONValue };

type LimitBarEndpoint =
  | string
  | {
      setting: string;
      policy: "https" | "https-or-loopback-http" | "https-or-private-network-http";
    };

type LimitBarAuth =
  | { type: "bearer" | "x-api-key"; secret: string }
  | { type: "header"; header: string; secret: string }
  | { type: "authorization-scheme"; scheme: string; secret: string };

interface LimitBarSetting {
  key: string;
  title: string;
  subtitle?: string;
  type?: "plain" | "secure";
}

interface LimitBarRateWindow {
  usedPercent: number;
  windowMinutes?: number | null;
  resetsAt?: Date | string | null;
  resetDescription?: string | null;
  nextRegenPercent?: number | null;
}

type LimitBarNamedRateWindow = {
  id: string;
  title: string;
  /** False keeps reset metadata visible without presenting unknown usage as a measured percentage. Defaults to true. */
  usageKnown?: boolean;
} & (LimitBarRateWindow | { window: LimitBarRateWindow });

interface LimitBarCostSnapshot {
  used: number;
  limit?: number | null;
  currency: string;
  period?: string | null;
  resetsAt?: Date | string | null;
  nextRegenAmount?: number | null;
  balance?: number | null;
}

interface LimitBarCostUsageEntry {
  date: string;
  inputTokens: number;
  outputTokens: number;
  /** Independent reported count; may exceed outputTokens and is not added to input + output totals. */
  reasoningTokens?: number | null;
  requests: number;
  cost: number;
  /** Portion of cost that is estimated rather than deducted by the provider. */
  estimatedCost?: number | null;
  model?: string | null;
}

interface LimitBarCostUsageSnapshot {
  currency: string;
  historyDays: number;
  historyLabel?: string | null;
  /** Inclusive YYYY-MM-DD end of the reported window. */
  windowEnd: string;
  entries: LimitBarCostUsageEntry[];
}

interface LimitBarIdentitySnapshot {
  email?: string | null;
  organization?: string | null;
  loginMethod?: string | null;
  accountID?: string | null;
}

interface LimitBarDetailRow {
  label: string;
  value: string;
  secondaryValue?: string | null;
  /** Finite consumed fraction, from 0 through 1 inclusive. */
  progress?: number | null;
  /** Finite raw usage, independent of the display string and progress. */
  usageValue?: number | null;
}

interface LimitBarDetailChart {
  kind: "bars" | "line";
  title?: string | null;
  unit?: string | null;
  points: Array<{ label: string; value: number }>;
}

interface LimitBarDetailSection {
  title?: string | null;
  rows: LimitBarDetailRow[];
  chart?: LimitBarDetailChart | null;
}

interface LimitBarUsageSnapshot {
  /** Explicitly declares a successful response with no displayable usage or identity. Other fields are still validated. */
  empty?: boolean;
  /** Without empty: true, at least one window, cost, non-empty detail section, or identity field is required. */
  primary?: LimitBarRateWindow | null;
  secondary?: LimitBarRateWindow | null;
  tertiary?: LimitBarRateWindow | null;
  extraWindows?: LimitBarNamedRateWindow[] | null;
  cost?: LimitBarCostSnapshot | null;
  /** Exact provider-reported daily spend. The host validates and sums every numeric row. */
  costUsage?: LimitBarCostUsageSnapshot | null;
  identity?: LimitBarIdentitySnapshot | null;
  subscriptionRenewsAt?: Date | string | null;
  subscriptionExpiresAt?: Date | string | null;
  dataConfidence?: "exact" | "estimated" | "percentOnly" | "unknown";
  details?: LimitBarDetailSection[] | null;
}

/** Result metadata is validated by the host; card and persistence require a descriptor-owned allowlist. */
interface LimitBarFetchResult {
  usage: LimitBarUsageSnapshot;
  sourceLabel?: string;
  card?: {
    openAIAPIUsage: {
      historyDays: number;
      projectID?: string | null;
      daily: Array<{
        startTime: number;
        endTime: number;
        costUSD: number;
        requests: number;
        inputTokens: number;
        cachedInputTokens: number;
        outputTokens: number;
        totalTokens: number;
        lineItems: Array<{ name: string; costUSD: number }>;
        models: Array<{
          name: string;
          requests: number;
          inputTokens: number;
          cachedInputTokens: number;
          outputTokens: number;
          totalTokens: number;
        }>;
      }>;
    };
  };
  persist?: Record<string, string>;
}

interface LimitBarHTTPRequestOptions {
  headers?: Readonly<Record<string, string>>;
  /** Hard deadline from transport start, 1–90 seconds (default 15); also bounded by the overall fetch deadline. */
  timeoutSeconds?: number;
  /** One native delayed retry for transient GET failures; POST is never retried. */
  retryPolicy?: "transientIdempotent";
}

interface LimitBarHTTPError extends Error {
  transportClass?: "timeout" | "dns" | "offline" | "cancelled" | "tls" | "connection" | "other" | "http";
  /** Foundation URLError code, preserved across both engines. */
  transportCode?: number;
  status?: number;
  /** Error-code eligibility for an idempotent retry, not a remaining retry budget. */
  retryable?: boolean;
}

interface LimitBarHTTPResponse {
  readonly url: string;
  /** `http-status` exposes non-2xx responses so the plugin can take over classification from the host. */
  status: number;
  headers: Readonly<Record<string, string>>;
}

interface LimitBarHTTPJSONResponse<T = unknown> extends LimitBarHTTPResponse {
  json: T;
}

interface LimitBarHTTPTextResponse extends LimitBarHTTPResponse {
  bodyText: string;
}

interface LimitBarRetryOptions {
  /** Requests the same one delayed retry used automatically for transient HTTP statuses; the host clamps it to 10 seconds. */
  retryAfterSeconds: number;
}

interface LimitBarFailures {
  authenticationExpired(message: unknown): Error;
  missingCredential(message: unknown): Error;
  permissionDenied(message: unknown): Error;
  rateLimited(message: unknown, options?: LimitBarRetryOptions): Error;
  providerUnavailable(message: unknown, options?: LimitBarRetryOptions): Error;
  parseFailure(message: unknown): Error;
  networkFailure(message: unknown, options?: LimitBarRetryOptions): Error;
  apiFailure(message: unknown, options?: LimitBarRetryOptions): Error;
}

type LimitBarPOSTOptions = LimitBarHTTPRequestOptions &
  ({ body: LimitBarJSONValue; form?: never } | { form: Readonly<Record<string, string>>; body?: never });

interface LimitBarPluginContext {
  readonly http: {
    getWithOptional(
      url: string,
      optional: string | (LimitBarPOSTOptions & { url: string; method: "POST" }),
      opts?: LimitBarHTTPRequestOptions & { optionalBudgetSeconds?: number },
    ): Promise<LimitBarHTTPTextResponse & { optional: LimitBarHTTPTextResponse | null }>;
    getJSON<T = unknown>(url: string, options?: LimitBarHTTPRequestOptions): Promise<LimitBarHTTPJSONResponse<T>>;
    get(url: string, options?: LimitBarHTTPRequestOptions): Promise<LimitBarHTTPTextResponse>;
    /** POST a JSON body or a host-encoded form and retain the response text. */
    post(url: string, options: LimitBarPOSTOptions): Promise<LimitBarHTTPTextResponse>;
    postJSON<T = unknown>(
      url: string,
      options: LimitBarHTTPRequestOptions & { body: LimitBarJSONValue },
    ): Promise<LimitBarHTTPJSONResponse<T>>;
  };
  readonly settings: {
    get(key: string): string | null;
    getSecret(key: string): string | null;
  };
  readonly browser: {
    availability(domain: string): "available" | "off" | "manual";
    rejectCookie(domain: string, session?: LimitBarCookieSession): void;
    sessions(domain: string, options?: { cachedOnly?: boolean }): AsyncIterable<LimitBarCookieSession>;
    cookieHeader(domain: string): Promise<string>;
  };
  readonly html: {
    metaContent(html: string, name: string): string | null;
    matchFirst(html: string, regexSource: string, flags?: string): string | null;
  };
  readonly date: {
    now(): Date;
    iso(value: string): Date;
    unixSeconds(value: number): Date;
    unixMillis(value: number): Date;
    nextDailyReset(timeZone: string, hour: number): Date;
    /** Gregorian calendar arithmetic with Foundation end-of-month clamping, in the given IANA zone. */
    addMonths(date: Date, months: number, timeZone: string): Date;
  };
  readonly format: {
    /** Native en_US currency formatting, including decimal half-even rounding and signed zero. */
    currency(value: number, currencyCode: string): string;
    number(value: number, options?: { minimumFractionDigits?: number; maximumFractionDigits?: number }): string;
    usd(value: number): string;
    monthDay(value: Date | number | string): string;
  };
  readonly fail: Readonly<LimitBarFailures>;
  readonly env: {
    readonly timeZone: string;
  };
  readonly cache: {
    get<T = unknown>(key: string): T | undefined;
    set(key: string, value: unknown, ttlSeconds: number): void;
  };
  readonly storage: {
    get(key: string): string | null;
    set(key: string, value: string): void;
    remove(key: string): void;
  };
  readonly jwt: {
    decode<T = unknown>(token: string): T;
  };
  log(...values: unknown[]): void;
  pct(used: number, limit: number): number;
  amountFromPercent(percent: number, limit: number): number;
  isDetailLabel(value: unknown): boolean;
}

interface LimitBarProviderDefinition {
  id: string;
  name: string;
  icon?: { monogram?: string; tint?: string };
  /** Shows this plugin as its own provider-switcher tab. */
  topLevel?: boolean;
  endpoints: LimitBarEndpoint[];
  auth?: LimitBarAuth;
  settings: LimitBarSetting[];
  /** Grants declared cookie access, HTTP status handling, or bounded non-secret persistent state. */
  capabilities?: Array<"browser-cookies" | "http-status" | "persistent-storage">;
  cookieDomains?: string[];
  fetchUsage(
    ctx: LimitBarPluginContext,
  ): LimitBarUsageSnapshot | LimitBarFetchResult | Promise<LimitBarUsageSnapshot | LimitBarFetchResult>;
}

declare function defineProvider(definition: LimitBarProviderDefinition): void;
