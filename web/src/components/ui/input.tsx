import * as React from "react"
import { cn } from "@/lib/utils"

// React 18: o ref tem de ser reencaminhado (o React Hook Form lê os valores através dele)
const Input = React.forwardRef<HTMLInputElement, React.ComponentProps<"input">>(function Input({ className, type, ...props }, ref) {
  return (
    <input
      ref={ref}
      type={type}
      data-slot="input"
      className={cn(
        "h-9 w-full min-w-0 rounded-lg border border-input bg-card px-3 py-1 text-base shadow-[0_1px_2px_rgb(15_23_42/0.04)] transition-[color,border-color,box-shadow] outline-none hover:border-foreground/20 selection:bg-primary selection:text-primary-foreground file:inline-flex file:h-7 file:border-0 file:bg-transparent file:text-sm file:font-medium file:text-foreground placeholder:text-muted-foreground disabled:pointer-events-none disabled:cursor-not-allowed disabled:opacity-50 md:text-sm dark:bg-input/30",
        "focus-visible:border-primary focus-visible:ring-[3px] focus-visible:ring-primary/15 focus-visible:hover:border-primary",
        "aria-invalid:border-destructive aria-invalid:ring-destructive/20 dark:aria-invalid:ring-destructive/40",
        className
      )}
      {...props}
    />
  )
})

export { Input }
