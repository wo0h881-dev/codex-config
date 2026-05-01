# Web Novel Field Contract

Crawler output must keep the existing downstream schema used by Lovable and include these required fields.

## Required Fields

- `title`: non-empty work title.
- `author`: non-empty author name.
- `publisher`: non-empty publisher/provider name when visible.
- `rank`: numeric current rank when the source is a ranking/list page.
- `views` or platform equivalent:
  - Kakao/Naver: view/read count when available.
  - Ridi: rating/review/evaluation count when used as the platform activity metric.
- `commentCount`: numeric comment count when visible.
- `episodeCount`: numeric total episode count when visible.
- `promotion`: wait-free/free episodes/event banner/event notice data when visible.

## Failure Values

Treat these as parse failures unless the source truly has no value:

- empty string
- `null` or `undefined`
- `0` caused by missing selector
- `#ERROR!`
- `-`
- values clearly copied from the wrong field

## Platform Priority

1. Kakao parser stability and fallback selectors.
2. Naver required fields.
3. Ridi required fields and promotion/free episode metadata.
4. Lovable UI/scoring only when explicitly requested.
