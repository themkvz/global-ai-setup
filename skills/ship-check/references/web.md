# Web checks (websites, web apps, internal tools)

Useful commands on a URL (local or one the user gave):

- `curl -sI <url>`: status, redirects, security and cache headers.
- `npx lighthouse <url> --chrome-flags="--headless" --output=json --output-path=<scratch>/lh.json --only-categories=performance,accessibility,best-practices,seo`
- `npx @axe-core/cli <url>`: accessibility scan.

## Performance

- Core Web Vitals at the 75th percentile: LCP ≤ 2.5 s, INP ≤ 200 ms, CLS ≤ 0.1. Lighthouse lab data is a proxy; field data (CrUX, RUM) wins when it exists.
- First load ≤ ~3 s on throttled 4G (DevTools "Slow 4G" or Lighthouse mobile).
- JS bundle: check build output for large chunks. Routes are code-split. No huge library for a small job (check with bundlephobia or the build analyzer).
- Images: modern formats (AVIF, WebP), right size for the slot, `width`/`height` set, `loading="lazy"` below the fold, LCP image not lazy.
- No render-blocking CSS or JS in `<head>` without a reason. Fonts use `font-display: swap` or optional; key fonts preloaded.
- Static assets with hashed names get `Cache-Control: public, max-age=31536000, immutable`. HTML gets a short or no-cache policy.
- Text compressed (Brotli or gzip). Static assets served from a CDN for public sites.

## Security

- HTTPS everywhere, HTTP redirects to HTTPS, no mixed content, `Strict-Transport-Security` set.
- Certificate is valid, not close to expiry, and covers every domain and subdomain in use: `openssl s_client -connect <host>:443 -servername <host> </dev/null 2>/dev/null | openssl x509 -noout -enddate -ext subjectAltName`. Without a URL, list DNS and certificate under Needs confirmation.
- Headers: `Content-Security-Policy` (at least a sane baseline), `X-Content-Type-Options: nosniff`, `frame-ancestors` or `X-Frame-Options`, `Referrer-Policy`.
- Session cookies: `HttpOnly`, `Secure`, `SameSite=Lax` or `Strict`. Tokens are not in `localStorage` when a cookie session is possible.
- CSRF protection on state-changing requests that use cookie auth.
- XSS: user content is escaped. Check every `dangerouslySetInnerHTML`, `innerHTML`, `v-html`, `{@html}`, and markdown renderer for unsanitized input.
- No secrets, internal URLs, or admin routes exposed in the client bundle. Public source maps are a choice, not an accident.
- Open redirects: redirect targets from query params are checked against an allowlist.

## Best practices

SEO and sharing apply to **public pages only**. For internal tools and pages behind login, check instead that they are not indexed (`noindex` or auth on every route, `robots.txt` blocks them) and skip the rest of this list.

- Every page has a unique, descriptive `<title>` (≤ ~60 chars) and meta description (~120–160 chars).
- `<link rel="canonical">` on every page. `<html lang>` set.
- Open Graph: `og:title`, `og:description`, `og:image` (1200×630, absolute URL). `twitter:card` = `summary_large_image`.
- `robots.txt` allows public pages and blocks admin and API routes. `sitemap.xml` lists public URLs.
- Structured data (JSON-LD) where it fits the content; valid in Google's Rich Results Test.
- Moved URLs return 301 to the new URL. No redirect chains.
- No errors in the browser console on main pages. Favicon and web manifest present.
- Analytics installed if the team needs traffic data, with consent where required.

## UX

- Accessibility (WCAG 2.2 AA):
  - Content images have useful `alt`; decorative images have `alt=""`.
  - All actions work by keyboard; focus is always visible; focus order makes sense; modals trap and return focus.
  - Every input has a label. Errors are linked to their field and announced.
  - Contrast ≥ 4.5:1 for text, ≥ 3:1 for large text and UI parts.
  - Semantic HTML: one `h1`, headings in order, buttons are `<button>`, links are `<a>`.
- Responsive: viewport meta tag present; no horizontal scroll at 320 px width; tap targets ≥ 44×44 px (24 px is the WCAG AA minimum).
- Custom 404 page with a way back. 500 page is generic and friendly, without a stack trace.
- Loading, empty, and error states exist for every data view. Forms prevent double submit and keep input after a server error.
- Navigation state lives in the URL: back button, refresh, and shared links work.

## Maintainability

- Framework build shows no warnings that hide real problems (hydration mismatch, missing keys, deprecated APIs).
- An end-to-end smoke test covers the main user flow.
