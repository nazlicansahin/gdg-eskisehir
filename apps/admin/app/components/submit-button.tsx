"use client";

import { useFormStatus } from "react-dom";

type Props = {
  idleLabel: string;
  pendingLabel?: string;
  className?: string;
  name?: string;
  value?: string;
  disabled?: boolean;
  title?: string;
};

export default function SubmitButton({
  idleLabel,
  pendingLabel = "Saving...",
  className,
  name,
  value,
  disabled = false,
  title,
}: Props) {
  const { pending } = useFormStatus();
  return (
    <button
      type="submit"
      name={name}
      value={value}
      className={className}
      disabled={disabled || pending}
      title={title}
    >
      {pending ? pendingLabel : idleLabel}
    </button>
  );
}
