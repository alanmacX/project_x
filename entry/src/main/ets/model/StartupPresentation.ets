// Keep the native starting window until the first complete scene is prepared.
// The deadline is a safety net, not a delay in the normal startup path.
let removeWindow: (() => Promise<void>) | undefined = undefined;
let deadline: number = -1;
export function cancelStartupReveal(): void {
  if (deadline >= 0) clearTimeout(deadline);
  deadline = -1; removeWindow = undefined;
}
export function deferStartupReveal(remove: () => Promise<void>): void {
  cancelStartupReveal(); removeWindow = remove;
  deadline = setTimeout(() => { revealStartup(); }, 2000);
}
export async function revealStartup(): Promise<void> {
  const remove = removeWindow; cancelStartupReveal();
  if (remove === undefined) return;
  try { await remove(); } catch (_) {} // A destroyed/unsupported window must not block the page.
}
