import { Header } from "@/shared/components/layout/Header";
import { BottomTabBar } from "@/shared/components/layout/BottomTabBar";
import { PageContainer } from "@/shared/components/layout/PageContainer";
import { QuickActionFAB } from "@/shared/components/QuickActionFAB";
import { AuthGuard } from "@/features/auth/components/AuthGuard";
import { ActiveSessionBanner } from "@/features/recording/components/ActiveSessionBanner";

export default function MainLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <AuthGuard>
      <Header />
      <ActiveSessionBanner />
      <PageContainer>{children}</PageContainer>
      <BottomTabBar />
      <QuickActionFAB />
    </AuthGuard>
  );
}
