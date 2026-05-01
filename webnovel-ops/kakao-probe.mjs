import { createRequire } from "node:module";

const require = createRequire(import.meta.url);
const { chromium } = require("../Lovable_Dashboard/node_modules/playwright");

const LIST_URL = "https://page.kakao.com/menu/10011/screen/94";

async function text(locator) {
  try {
    if ((await locator.count()) <= 0) return "";
    return (await locator.first().innerText()).trim();
  } catch {
    return "";
  }
}

async function main() {
  const browser = await chromium.launch({ headless: true });
  const context = await browser.newContext({
    userAgent:
      "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36",
  });

  const page = await context.newPage();
  await page.goto(LIST_URL, { waitUntil: "networkidle", timeout: 45000 });
  await page.waitForTimeout(3000);

  const links = await page.$$eval('a[href*="/content/"]', (items) =>
    [...new Set(items.map((a) => a.href))].slice(0, 3),
  );

  const samples = [];
  for (const [idx, url] of links.entries()) {
    const detail = await context.newPage();
    await detail.goto(url, { waitUntil: "networkidle", timeout: 45000 });
    await detail.waitForTimeout(2500);

    const title = await detail.locator('meta[property="og:title"]').getAttribute("content").catch(() => "");
    const author = await text(detail.locator("span.font-small2.mb-6pxr.text-ellipsis"));

    const homeText = await detail.locator("body").innerText().catch(() => "");
    const beforeInfo = {
      episodeLike: [...homeText.matchAll(/\d[\d,]*\s*화/g)].slice(0, 8).map((m) => m[0]),
      commentLike: [...homeText.matchAll(/댓글\s*[\d,.]+(?:만)?/g)].slice(0, 8).map((m) => m[0]),
      viewLike: [...homeText.matchAll(/\d[\d,.]*\s*(?:만|억)/g)].slice(0, 8).map((m) => m[0]),
    };
    const commentIndex = homeText.indexOf("댓글");
    const episodeIndex = homeText.indexOf("전체");
    const totals = [...homeText.matchAll(/전체\s*([\d,]+)/g)].map((m) => m[1].replace(/,/g, ""));

    const infoTab = detail.locator("span.font-small1", { hasText: "정보" }).first();
    if ((await infoTab.count()) > 0) {
      await infoTab.click();
      await detail.waitForTimeout(1000);
    }

    const infoText = await detail.locator("body").innerText().catch(() => "");
    const publisherMatches = [
      ...infoText.matchAll(/(?:발행자|출판사|제공)\s*\n?\s*([^\n]+)/g),
    ].map((m) => m[1].trim());

    samples.push({
      index: idx + 1,
      url,
      title,
      author,
      beforeInfo,
      parsedByNewFallback: {
        totalEpisodes: totals[0] ? `${totals[0]}화` : "",
        commentCount: totals[1] || "",
      },
      commentSnippet:
        commentIndex >= 0 ? homeText.slice(Math.max(0, commentIndex - 120), commentIndex + 180) : "",
      episodeSnippet:
        episodeIndex >= 0 ? homeText.slice(Math.max(0, episodeIndex - 120), episodeIndex + 220) : "",
      publisherMatches,
      currentPublisherRowCount: await detail.locator("div.font-small1").filter({ hasText: "발행자" }).count(),
      bodyIncludesComment: homeText.includes("댓글"),
    });

    await detail.close();
  }

  await browser.close();
  console.log(JSON.stringify({ listUrl: LIST_URL, linkCount: links.length, samples }, null, 2));
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
