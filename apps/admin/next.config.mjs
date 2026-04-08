/** @type {import('next').NextConfig} */
const nextConfig = {
  reactStrictMode: true,
  // Keep development output separate from production build output to avoid
  // stale chunk/module resolution when switching between `next dev` and `next build`.
  distDir: process.env.NODE_ENV === "development" ? ".next-dev" : ".next",
  webpack: (config, { dev }) => {
    if (dev) {
      // More stable dev behavior in environments that occasionally hit
      // webpack cache pack rename/race issues.
      config.cache = false;
    }
    return config;
  },
};

export default nextConfig;
