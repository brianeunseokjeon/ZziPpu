import { Header } from "@/shared/components/layout/Header";
import { BottomTabBar } from "@/shared/components/layout/BottomTabBar";
import { PageContainer } from "@/shared/components/layout/PageContainer";
import { QuickActionFAB } from "@/shared/components/QuickActionFAB";

export default function MainLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <>
      <Header />
      <PageContainer>{children}</PageContainer>
      <BottomTabBar />
      <QuickActionFAB />
    </>
  );
}
