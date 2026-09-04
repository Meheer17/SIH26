import type { Metadata } from "next";
import "./globals.css";
import { AuthProvider } from "@/lib/auth/AuthContext";
import Navbar from "@/components/Navbar";

export const metadata: Metadata = {
  title: "SvasthyaSetu — Smart India Hackathon 2026",
  description: "Bridge to Health: Unified platform for SIH26181, SIH26047, SIH26186, and SIH26094",
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html
      lang="en"
      className="h-full antialiased"
    >
      <body className="min-h-full flex flex-col bg-slate-50 text-slate-900 font-sans selection:bg-teal-700 selection:text-white">
        <AuthProvider>
          <Navbar />
          <main className="flex-1">{children}</main>
        </AuthProvider>
      </body>
    </html>
  );
}

