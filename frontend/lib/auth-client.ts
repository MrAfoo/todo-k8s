import { createAuthClient } from "better-auth/react";

export const authClient = createAuthClient({
  baseURL: "http://localhost:3000", // Better Auth runs on the frontend Next.js server
  plugins: [],
});

export const { signIn, signUp, signOut, useSession } = authClient;
