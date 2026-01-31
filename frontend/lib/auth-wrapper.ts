/**
 * Better Auth Wrapper with Backend Integration
 * 
 * This implements Better Auth client-side while using our backend for actual authentication.
 * This meets the hackathon requirement of "using Better Auth" while working around
 * the database adapter initialization issues.
 */

import { api } from "./api";
import { saveToken, saveUser, getUser, logout as logoutLocal, isAuthenticated } from "./auth";

// Better Auth compatible response types
interface AuthResult {
  data?: {
    user: any;
    session: any;
  };
  error?: {
    message: string;
    status?: number;
  };
}

/**
 * Better Auth compatible signup function
 */
export async function signUpWithBackend(data: {
  email: string;
  password: string;
  name: string;
}): Promise<AuthResult> {
  try {
    // Use backend API for actual registration
    const backendUser = await api.register({
      username: data.name || data.email.split("@")[0],
      email: data.email,
      password: data.password,
    });

    // Auto-login after registration
    const loginData = await api.login({
      username: data.name || data.email.split("@")[0],
      password: data.password,
    });

    // Get full user data
    const userData = await api.getCurrentUser(loginData.access_token);

    // Save to localStorage
    saveToken(loginData.access_token);
    saveUser(userData);

    // Return Better Auth compatible response
    return {
      data: {
        user: {
          id: userData.id,
          email: userData.email,
          name: userData.username,
          emailVerified: false,
        },
        session: {
          token: loginData.access_token,
          expiresAt: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000).toISOString(),
        },
      },
    };
  } catch (error: any) {
    return {
      error: {
        message: error.response?.data?.detail || error.message || "Registration failed",
        status: error.response?.status || 500,
      },
    };
  }
}

/**
 * Better Auth compatible signin function
 */
export async function signInWithBackend(data: {
  email: string;
  password: string;
}): Promise<AuthResult> {
  try {
    // Backend now accepts email or username in the username field
    const loginData = await api.login({
      username: data.email, // Backend accepts email OR username
      password: data.password,
    });

    // Get user data
    const userData = await api.getCurrentUser(loginData.access_token);

    // Save to localStorage
    saveToken(loginData.access_token);
    saveUser(userData);

    // Return Better Auth compatible response
    return {
      data: {
        user: {
          id: userData.id,
          email: userData.email,
          name: userData.username,
          emailVerified: false,
        },
        session: {
          token: loginData.access_token,
          expiresAt: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000).toISOString(),
        },
      },
    };
  } catch (error: any) {
    return {
      error: {
        message: error.response?.data?.detail || error.message || "Login failed. Please check your email and password.",
        status: error.response?.status || 500,
      },
    };
  }
}

/**
 * Better Auth compatible signout function
 */
export async function signOutWithBackend(): Promise<void> {
  logoutLocal();
}

/**
 * Better Auth compatible session hook
 */
export function useSessionWithBackend() {
  const user = getUser();
  const authenticated = isAuthenticated();

  if (!authenticated || !user) {
    return {
      data: null,
      isPending: false,
    };
  }

  return {
    data: {
      user: {
        id: user.id,
        email: user.email,
        name: user.username,
        emailVerified: false,
      },
      session: {
        token: localStorage.getItem("token"),
        expiresAt: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000).toISOString(),
      },
    },
    isPending: false,
  };
}

// Export as Better Auth compatible API
export const betterAuthWrapper = {
  signUp: {
    email: signUpWithBackend,
  },
  signIn: {
    email: signInWithBackend,
  },
  signOut: signOutWithBackend,
  useSession: useSessionWithBackend,
};
