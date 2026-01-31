/**
 * Integration layer between Better Auth and Backend API
 * Syncs Better Auth users with backend for task management
 */

import { api } from "./api";
import { saveToken, saveUser } from "./auth";

/**
 * After Better Auth registration, create corresponding backend user
 */
export async function syncUserWithBackend(betterAuthUser: {
  id: string;
  email: string;
  name: string;
}) {
  try {
    // Try to register user in backend
    // Use Better Auth ID as username for consistency
    const backendUser = await api.register({
      username: betterAuthUser.name || betterAuthUser.email.split("@")[0],
      email: betterAuthUser.email,
      password: `betterauth_${betterAuthUser.id}`, // Dummy password, won't be used
    });

    console.log("Backend user created:", backendUser);
    return backendUser;
  } catch (error: any) {
    // If user already exists (409), try to login
    if (error.response?.status === 409 || error.response?.status === 400) {
      console.log("User already exists in backend, attempting login...");
      try {
        const loginData = await api.login({
          username: betterAuthUser.name || betterAuthUser.email.split("@")[0],
          password: `betterauth_${betterAuthUser.id}`,
        });
        
        const userData = await api.getCurrentUser(loginData.access_token);
        saveToken(loginData.access_token);
        saveUser(userData);
        
        return userData;
      } catch (loginError) {
        console.error("Backend login failed:", loginError);
        throw loginError;
      }
    }
    throw error;
  }
}

/**
 * Get backend JWT token for Better Auth session
 */
export async function getBackendToken(betterAuthUser: {
  id: string;
  email: string;
  name: string;
}) {
  try {
    const loginData = await api.login({
      username: betterAuthUser.name || betterAuthUser.email.split("@")[0],
      password: `betterauth_${betterAuthUser.id}`,
    });

    saveToken(loginData.access_token);
    
    const userData = await api.getCurrentUser(loginData.access_token);
    saveUser(userData);
    
    return {
      token: loginData.access_token,
      user: userData,
    };
  } catch (error) {
    console.error("Failed to get backend token:", error);
    throw error;
  }
}
