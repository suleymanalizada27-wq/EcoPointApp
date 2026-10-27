/**
 * Who is an admin?
 *  1. a Firebase custom claim `admin: true`, or
 *  2. a **verified** e-mail address listed in the ADMIN_EMAILS env var
 *     (comma-separated). Unverified e-mail/password sign-ups never qualify, so
 *     nobody can become admin by registering someone else's address; Google
 *     sign-in returns verified e-mails.
 */
export function parseAdminEmails(raw: string | undefined): Set<string> {
  return new Set(
    (raw ?? '')
      .split(',')
      .map((s) => s.trim().toLowerCase())
      .filter((s) => s.includes('@')),
  );
}

export function isAdminToken(
  decoded: { admin?: unknown; email?: unknown; email_verified?: unknown },
  allowed: Set<string>,
): boolean {
  if (decoded.admin === true) return true;
  const email = typeof decoded.email === 'string' ? decoded.email.trim().toLowerCase() : '';
  return decoded.email_verified === true && email !== '' && allowed.has(email);
}
