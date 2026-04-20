/** Shared shape for `privacy`, `support`, and `terms` `*.sections` in message JSON. */
export type LegalSection = {
  id: string;
  title: string;
  paragraphs: string[];
};
