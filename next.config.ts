import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  // "standalone" is for local/Docker-style hosting. Netlify's Next.js runtime
  // needs the default output, so disable it when building on Netlify.
  output: process.env.NETLIFY ? undefined : "standalone",
  typescript: {
    ignoreBuildErrors: true,
  },
  reactStrictMode: false,
};

export default nextConfig;
