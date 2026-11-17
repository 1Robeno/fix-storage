/** What differs between macOS and Linux, in one place. */

export const IS_MAC = process.platform === "darwin";

/** The operating system's name, for messages. */
export const OS_NAME = IS_MAC ? "macOS" : "Linux";

/** What revealing an item opens, for messages: "Showing x in Finder." */
export const FILE_MANAGER = IS_MAC ? "Finder" : "your file manager";

/** Lowercase label for the reveal action. */
export const REVEAL_LABEL = IS_MAC ? "reveal in finder" : "show in file manager";
