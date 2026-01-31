import { betterAuth } from "better-auth";

// Simple configuration - let Better Auth handle the database connection
export const auth = betterAuth({
  database: {
    connectionString: process.env.DATABASE_URL || "",
    ssl: {
      rejectUnauthorized: false,
    },
  },
  emailAndPassword: {
    enabled: true,
  },
  trustedOrigins: ["http://localhost:3000", "http://127.0.0.1:3000"],
  secret: process.env.BETTER_AUTH_SECRET || "your-secret-key-min-32-chars-long!",
  baseURL: process.env.BETTER_AUTH_BASE_URL || "http://localhost:3000",
  advanced: {
    useSecureCookies: false,
    cookiePrefix: "better-auth",
  },
});
