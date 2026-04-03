export const GITHUB_API = () =>
  `https://api.github.com/repos/${process.env.GITHUB_OWNER}/${process.env.GITHUB_REPO}`;

export const BASE_URL = () =>
  `https://${process.env.GITHUB_OWNER}.github.io/${process.env.GITHUB_REPO}/datasets`;

export const GH_HEADERS = {
  Authorization: `Bearer ${process.env.GITHUB_TOKEN}`,
  Accept: "application/vnd.github+json",
  "Content-Type": "application/json",
  "X-GitHub-Api-Version": "2022-11-28",
};
