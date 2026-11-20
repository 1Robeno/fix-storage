import { homedir } from "node:os";

const GB = 1e9;
const MB = 1e6;

/** Decimal gigabytes with one decimal, the way macOS reports storage. */
export function gb(bytes: number): string {
  return `${(Math.max(0, bytes) / GB).toFixed(1)} GB`;
}

/** Whole gigabytes for the disk's capacity ("512 GB"). */
export function capacity(bytes: number): string {
  return `${Math.round(bytes / GB)} GB`;
}

/** Picks GB or MB, for lists where small items matter. */
export function size(bytes: number): string {
  if (bytes >= GB) return gb(bytes);
  if (bytes >= MB) return `${Math.round(bytes / MB)} MB`;
  return `${Math.max(0, Math.round(bytes / 1e3))} KB`;
}

/** Replaces the home directory with ~ so paths stay short. */
export function tilde(path: string, home: string = homedir()): string {
  return path === home || path.startsWith(home + "/") ? "~" + path.slice(home.length) : path;
}
