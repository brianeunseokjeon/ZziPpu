import { cn } from "@/lib/utils";

interface PageContainerProps {
  children: React.ReactNode;
  className?: string;
}

export function PageContainer({ children, className }: PageContainerProps) {
  return (
    <main
      className={cn(
        "max-w-md mx-auto w-full px-4 py-4 pb-24 min-h-screen",
        className
      )}
    >
      {children}
    </main>
  );
}
