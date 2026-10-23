/*
 * Code.gs Ridi comment update.
 *
 * Apply these edits to the operating Apps Script Code.gs pasted in the chat.
 * api.gs does not need changes.
 */

// 1) Add this helper near normalizeEpisodeCount.
function normalizeCommentCount(val) {
  if (val === 0) return 0;
  if (!val) return "-";

  var s = String(val).trim();
  if (!s || s === "-") return "-";

  if (s.endsWith("\uB9CC")) {
    var n = parseFloat(s.replace("\uB9CC", "").replace(/,/g, ""));
    return isNaN(n) ? "-" : Math.round(n * 10000);
  }

  var m = s.match(/(\d[\d,]*)/);
  return m ? m[1].replace(/,/g, "") : "-";
}

// 2) In the source === "ridi" rows map, add this after ratingCount.
const comments = normalizeCommentCount(
  item.comments || item.commentCount || item.ridi_comment_count || "-"
);

// 3) Include comments in the object returned from the rows map.
/*
return {
  dateStr: todayStr,
  source: "ridi",
  category,
  is_promotion,
  rankNum,
  title,
  author,
  genre,
  publisher,
  totalEpisodes: item.totalEpisodes || "-",
  rating,
  ratingCount,
  comments,
  thumbnail,
  url
};
*/

// 4) In ridiSheet.setValues, replace the K column "-" with comments.
/*
ridiSheet
  .getRange(2, 1, rows.length, 12)
  .setValues(rows.map(r => [
    r.dateStr,
    "ridi",
    r.rankNum || "",
    r.title,
    r.author,
    r.genre,
    r.ratingCount || "-",
    r.thumbnail || "-",
    r.publisher || "-",
    r.rating || "-",
    r.comments || "-",
    normalizeEpisodeCount(r.totalEpisodes)
  ]));
*/

// 5) In historyRows, replace the K column "-" with comments.
/*
const historyRows = rows.map(r => [
  r.dateStr,
  "ridi",
  r.rankNum || "",
  r.title,
  r.author,
  r.genre,
  r.ratingCount || "-",
  r.thumbnail || "-",
  r.publisher || "-",
  r.rating || "-",
  r.comments || "-",
  normalizeEpisodeCount(r.totalEpisodes),
]);
*/
