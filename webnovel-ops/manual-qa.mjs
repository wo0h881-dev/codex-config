import fs from "node:fs";
import { createRequire } from "node:module";

const require = createRequire(import.meta.url);
const { JSDOM } = require("../Lovable_Dashboard/node_modules/jsdom");

const ROOT = "D:/Agent/Codex";
const WATCHLIST = `${ROOT}/webnovel-ops/watchlist.md`;

const headers = {
  "user-agent":
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36",
};

function clean(text) {
  return String(text ?? "").replace(/\s+/g, " ").trim();
}

function isMissing(value) {
  const text = clean(value);
  return !text || text === "-" || text === "#ERROR!" || text === "null" || text === "undefined";
}

function urlsByPlatform() {
  const text = fs.readFileSync(WATCHLIST, "utf8");
  const result = { kakao: [], naver: [], ridi: [] };
  let section = "";

  for (const line of text.split(/\r?\n/)) {
    const heading = line.match(/^##\s+(Kakao|Naver|Ridi)\s*$/i);
    if (heading) {
      section = heading[1].toLowerCase();
      continue;
    }

    const url = line.match(/^-\s+(https?:\/\/\S+)/)?.[1];
    if (url && result[section]) result[section].push(url);
  }

  return result;
}

async function fetchDocument(url) {
  const res = await fetch(url, { headers });
  const html = await res.text();
  return {
    status: res.status,
    htmlLength: html.length,
    document: new JSDOM(html, { url }).window.document,
  };
}

function validateRecord(record, fields) {
  return fields.filter((field) => isMissing(record[field]));
}

async function checkRidi(url) {
  const { status, htmlLength, document } = await fetchDocument(url);
  const cards = [...document.querySelectorAll("li.fig-1m9tqaj")];
  const samples = cards.slice(0, 5).map((item, idx) => {
    const rankText = clean(item.querySelector("div.fig-ty289v")?.textContent);
    return {
      rank: /^\d+$/.test(rankText) ? rankText : String(idx + 1),
      title: clean(item.querySelector("a.fig-w1hthz")?.textContent),
      author: clean(item.querySelector("a.fig-103urjl.e1s6unbg0")?.textContent),
      publisher: clean(item.querySelector("a.fig-103urjl.efs2tg41")?.textContent),
      episodeCount: clean(item.querySelector("span.fig-w746bu span")?.textContent),
      rating: clean(item.querySelector("span.fig-mhc4m4.enp6wb0")?.textContent),
      ratingCount: clean(item.querySelector("span.fig-1d0qko5.enp6wb2")?.textContent),
      promotion: clean(item.querySelector("ul.fig-1i4k0g9")?.textContent),
    };
  });

  return {
    platform: "ridi",
    url,
    status,
    htmlLength,
    itemCount: cards.length,
    samples,
    failures: samples.flatMap((sample, idx) =>
      validateRecord(sample, ["rank", "title", "author", "publisher", "episodeCount", "ratingCount"]).map(
        (field) => ({ index: idx + 1, field }),
      ),
    ),
  };
}

async function checkNaver(url) {
  const { status, htmlLength, document } = await fetchDocument(url);
  const items = [...document.querySelectorAll("#content > div > ul > li")];
  const samples = [];
  const failures = [];

  for (const [idx, item] of items.slice(0, 5).entries()) {
    const link = item.querySelector("div.comic_cont h3 a, h3 a");
    const detailUrl = link?.href || "";
    const sample = {
      rank: String(idx + 1),
      title: clean(link?.textContent),
      detailUrl,
      author: "",
      publisher: "",
      views: "",
      commentCount: "",
      episodeCount: "",
      promotion: clean(item.querySelector(".comic_cont .info, .info")?.textContent),
    };

    if (detailUrl) {
      try {
        const detail = await fetchDocument(detailUrl);
        const d = detail.document;
        sample.views = clean(d.querySelector("a.btn_download span")?.textContent);
        sample.commentCount = clean(d.querySelector("span#commentCount")?.textContent);
        sample.episodeCount = clean(d.querySelector("h5.end_total_episode strong")?.textContent);
        sample.author = clean(
          [...d.querySelectorAll("span")]
            .find((span) => clean(span.textContent) === "글")
            ?.nextElementSibling?.textContent || d.querySelector(".writer")?.textContent,
        );
        sample.publisher = clean(
          [...d.querySelectorAll("span")]
            .find((span) => clean(span.textContent) === "출판사")
            ?.nextElementSibling?.textContent,
        );
      } catch (error) {
        failures.push({ index: idx + 1, field: "detailFetch", error: String(error.message || error) });
      }
    }

    samples.push(sample);
    failures.push(
      ...validateRecord(sample, ["rank", "title", "author", "publisher", "views", "commentCount", "episodeCount"]).map(
        (field) => ({ index: idx + 1, field }),
      ),
    );
  }

  return {
    platform: "naver",
    url,
    status,
    htmlLength,
    itemCount: items.length,
    samples,
    failures,
  };
}

async function checkKakao(url) {
  const { status, htmlLength, document } = await fetchDocument(url);
  const links = [...document.querySelectorAll('a[href*="/content/"]')]
    .map((a) => a.href)
    .filter((href, idx, list) => href && list.indexOf(href) === idx);
  const samples = [];
  const failures = [];

  for (const [idx, detailUrl] of links.slice(0, 5).entries()) {
    const sample = {
      rank: String(idx + 1),
      title: "",
      detailUrl,
      author: "",
      publisher: "",
      views: "",
      commentCount: "",
      episodeCount: "",
      promotion: "",
    };

    try {
      const detail = await fetchDocument(detailUrl);
      const d = detail.document;
      sample.title = clean(d.querySelector('meta[property="og:title"]')?.getAttribute("content"));
      sample.author = clean(d.querySelector("span.font-small2.mb-6pxr.text-ellipsis")?.textContent);
      const body = clean(d.body.textContent);
      sample.views = body.match(/\d[\d,.]*\s*(?:만|억)/)?.[0] || "";
      sample.episodeCount = body.match(/\d[\d,]*\s*화/)?.[0] || "";
      sample.commentCount = body.match(/댓글\s*[\d,.]+(?:만)?/)?.[0] || "";
      sample.publisher = body.match(/발행자\s*([^\s]+(?:\s+[^\s]+){0,2})/)?.[1] || "";
      sample.promotion = body.match(/(?:기다리면 무료|기다무|3다무|무료)/)?.[0] || "";
    } catch (error) {
      failures.push({ index: idx + 1, field: "detailFetch", error: String(error.message || error) });
    }

    samples.push(sample);
    failures.push(
      ...validateRecord(sample, ["rank", "title", "author", "publisher", "views", "commentCount", "episodeCount"]).map(
        (field) => ({ index: idx + 1, field }),
      ),
    );
  }

  return {
    platform: "kakao",
    url,
    status,
    htmlLength,
    itemCount: links.length,
    samples,
    failures,
  };
}

async function main() {
  const urls = urlsByPlatform();
  const reports = [];

  for (const url of urls.ridi) reports.push(await checkRidi(url));
  for (const url of urls.naver) reports.push(await checkNaver(url));
  for (const url of urls.kakao) reports.push(await checkKakao(url));

  const summary = reports.map((report) => ({
    platform: report.platform,
    url: report.url,
    status: report.status,
    itemCount: report.itemCount,
    failureCount: report.failures.length,
    failures: report.failures.slice(0, 12),
  }));

  console.log(JSON.stringify({ generatedAt: new Date().toISOString(), summary, reports }, null, 2));
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
