import type { Metadata } from "next";
import "./globals.css";
import { AuthProvider } from "@/lib/auth/AuthContext";
import Navbar from "@/components/Navbar";

export const metadata: Metadata = {
  title: "SvasthyaSetu — SIH 2026 Unified National Healthcare Platform",
  description: "Bridge to Health: Unified clinical AI & resilience ecosystem integrating SIH26181, SIH26047, SIH26186, and SIH26094",
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html
      lang="en"
      className="h-full antialiased dark"
    >
      <body className="min-h-full flex flex-col bg-[#0B0F17] text-slate-100 font-sans selection:bg-teal-500 selection:text-slate-950 bg-mesh-dark">
        <AuthProvider>
          <Navbar />
          <main className="flex-1">{children}</main>
        </AuthProvider>
      </body>
    </html>
  );
}
