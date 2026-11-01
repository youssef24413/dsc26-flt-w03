# AI usage: dsc26-flt-w03

AI tools are allowed in this task. Fill in every section in your own words. This file is read by your Track Mentor, not by the grader.

## 1. Tools I used

Claude (Anthropic) for drafting the code; fvm + `flutter test` to check it.

## 2. The prompts that helped most

1. I pasted the whole task text and the template repo and asked for the data layer, the repository and the screen, following every rule in the README.
2. I asked it to list the hidden-test areas (H01-H13) and check each one against the code before I ran the tests.

## 3. Where the assistant's code would have failed a hidden-test area, and how I noticed

The assistant's code passed the 5 public tests on the first run, so I did not hit a real failure. Instead I read the code against the hidden-test rows (H01-H13) and checked the places where a "normal" first draft usually breaks:

- **H03 / H04 (Arabic text):** the easy way is `response.body`, which decodes by the Content-Type header. The tests send Arabic with no header and with a wrong Latin-1 header, so it would come out garbled. The code uses `utf8.decode(response.bodyBytes)` instead.
- **H01 (URL):** building the URL with string concatenation breaks on a base URL with a path or a studentId like `a b/c`. The code uses `baseUrl.replace(pathSegments: ...)`, which encodes each segment.
- **H09 / H10 (retries):** a loop that counts calls instead of checking the failure type would retry a 401 or 404. The code checks `failure.isTransient`. For a 429 it waits `retryAfter` (capped at 30 s) and the backoff index still counts every retry, so 429 then 503 waits 7 s then 2 s.
- **H12 / H13 (screen):** without a guard, a double tap sends two requests, and `notifyListeners()` after the page is removed throws. The view model has an `_inFlight` guard and a `_disposed` flag that is checked after the await.

I checked these by reading the code against the README, running `flutter test` (all passed), and running `flutter analyze` (only style infos, no errors).

## 4. My state-management choice

ChangeNotifier (a `PracticeViewModel` with `ListenableBuilder`), because this screen has one small state and it needs no extra package; a `_disposed` flag stops updates after the page is removed.
