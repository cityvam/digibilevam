import { NextRequest, NextResponse } from 'next/server';

export function middleware(req: NextRequest) {
  const { pathname } = req.nextUrl;
  if ((pathname.startsWith('/app') || pathname.startsWith('/admin')) && !req.cookies.get('dp_t')) {
    return new NextResponse(null, { status: 303, headers: { Location: '/login' } });
  }
  const nonce = btoa(crypto.randomUUID());
  const dev = process.env.NODE_ENV !== 'production';
  const csp = [
    "default-src 'self'", `script-src 'self' 'nonce-${nonce}' 'strict-dynamic'${dev ? " 'unsafe-eval'" : ''}`, "style-src 'self' 'unsafe-inline'",
    "img-src 'self' data: blob:", "font-src 'self'", "connect-src 'self'", "frame-src 'self'", "form-action 'self'", "base-uri 'none'", "object-src 'none'", "frame-ancestors 'none'",
  ].join('; ');
  const h = new Headers(req.headers); h.set('x-nonce', nonce); h.set('x-pathname', pathname); h.set('Content-Security-Policy', csp);
  const res = NextResponse.next({ request: { headers: h } });
  res.headers.set('Content-Security-Policy', csp); res.headers.set('Cache-Control', 'no-store');
  // پیام یک‌بارمصرف: پس از نمایش (نه روی prefetch) پاک شود
  if (req.cookies.get('dp_f') && req.method === 'GET' && !req.headers.get('next-router-prefetch')) { res.cookies.delete('dp_f'); }
  if (req.cookies.get('dp_o') && req.method === 'GET' && !req.headers.get('next-router-prefetch')) res.cookies.delete('dp_o');
  return res;
}
// فایل‌های /files خودشان CSP می‌گذارند (قرارداد داخل iframe)
export const config = { matcher: ['/((?!_next/static|_next/image|favicon.ico|fonts/|files/|healthz|session-expired).*)'] };
