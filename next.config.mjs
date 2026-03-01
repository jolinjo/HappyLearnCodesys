/** @type {import('next').NextConfig} */
const nextConfig = {
  reactStrictMode: true,
  output: "export",
  basePath: "/HappyLearnCodesys",
  assetPrefix: "/HappyLearnCodesys",
  env: {
    NEXT_PUBLIC_BASE_PATH: "/HappyLearnCodesys",
  },
};

export default nextConfig;

