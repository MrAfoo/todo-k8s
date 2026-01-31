/**
 * Helper functions to bridge Better Auth with our existing API client.
 */

import { authClient } from "./auth-client";

/**
 * Get the JWT token from Better Auth session.
 * This token can be used to authenticate with the FastAPI backend.
 */
export async function getBetterAuthToken(): Promise<string | null> {
  try {
    const session = await authClient.getSession();
    if (!session?.data?.session) {
      return null;
    }
    
    // Better Auth with JWT plugin stores the token in the session
    // We need to call the JWT endpoint to get the token
    const response = await fetch("http://localhost:3000/api/auth/get-session", {
      credentials: "include",
    });
    
    if (!response.ok) {
      return null;
    }
    
    const data = await response.json();
    return data?.session?.token || null;
  } catch (error) {
    console.error("Error getting Better Auth token:", error);
    return null;
  }
}

/**
 * Get the current user from Better Auth session.
 */
export async function getBetterAuthUser() {
  try {
    const session = await authClient.getSession();
    return session?.data?.user || null;
  } catch (error) {
    console.error("Error getting Better Auth user:", error);
    return null;
  }
}
