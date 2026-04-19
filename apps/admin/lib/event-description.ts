export type ParsedEventDescription = {
  body: string;
  location: string;
  eventImageUrl: string;
  isFree: boolean;
  price: string;
};

/** Matches metadata lines appended in composeEventDescription / create flow. */
export function parseEventDescription(raw: string | null | undefined): ParsedEventDescription {
  const text = raw ?? "";
  const lines = text.split("\n");
  const bodyLines: string[] = [];
  let location = "";
  let eventImageUrl = "";
  let pricingLine = "";

  for (const line of lines) {
    const t = line.trim();
    if (t.startsWith("Location:")) {
      location = t.replace(/^Location:\s*/i, "").trim();
    } else if (t.startsWith("Pricing:")) {
      pricingLine = t.replace(/^Pricing:\s*/i, "").trim();
    } else if (t.startsWith("Event image:")) {
      eventImageUrl = t.replace(/^Event image:\s*/i, "").trim();
    } else {
      bodyLines.push(line);
    }
  }

  const body = bodyLines.join("\n").trim();
  const paidMatch = pricingLine.match(/^paid\s*\(([^)]*)\)\s*$/i);
  const price = paidMatch ? (paidMatch[1]?.trim() ?? "") : "";
  const isFree = pricingLine.trim().length === 0 || !/^paid\s*\(/i.test(pricingLine.trim());

  return { body, location, eventImageUrl, isFree, price };
}

export function composeEventDescription(
  baseDescription: string,
  extras: {
    location?: string;
    eventImageUrl?: string;
    isFree: boolean;
    price?: string;
  },
): string {
  const lines: string[] = [];
  const base = baseDescription.trim();
  if (base) {
    lines.push(base);
  }
  if (extras.location?.trim()) {
    lines.push(`Location: ${extras.location.trim()}`);
  }
  lines.push(`Pricing: ${extras.isFree ? "Free" : `Paid (${extras.price?.trim() || "n/a"})`}`);
  if (extras.eventImageUrl?.trim()) {
    lines.push(`Event image: ${extras.eventImageUrl.trim()}`);
  }
  return lines.join("\n\n");
}
