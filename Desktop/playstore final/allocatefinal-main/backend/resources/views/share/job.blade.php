<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>JobAllocate — Opening job</title>
  <style>
    body {
      margin: 0;
      min-height: 100vh;
      display: flex;
      flex-direction: column;
      align-items: center;
      justify-content: center;
      font-family: system-ui, -apple-system, Segoe UI, Roboto, sans-serif;
      background: #f8fafc;
      color: #0f172a;
      text-align: center;
      padding: 24px;
    }
    h1 { font-size: 1.35rem; margin: 0 0 8px; }
    p { color: #475569; margin: 0 0 16px; max-width: 28rem; line-height: 1.45; }
    a.btn {
      display: inline-block;
      margin: 6px;
      padding: 12px 20px;
      border-radius: 10px;
      text-decoration: none;
      font-weight: 700;
      font-size: 0.95rem;
    }
    a.primary { background: #174a7e; color: #fff; }
    a.secondary { background: #fff; color: #174a7e; border: 1px solid #cbd5e1; }
  </style>
</head>
<body>
  <h1>JobAllocate</h1>
  <p>Opening this job in the app. If you don’t have JobAllocate installed, get it on the Play Store.</p>
  <p>
    <a class="btn primary" id="open-app" href="{{ $intentUrl }}">Open in app</a>
    <a class="btn secondary" href="{{ $playStoreUrl }}">Get the app</a>
  </p>

  <script>
    (function () {
      var intentUrl = @json($intentUrl);
      var deepLink = @json($deepLink);
      var playStore = @json($playStoreUrl);
      var isAndroid = /Android/i.test(navigator.userAgent);

      function go(url) {
        window.location.href = url;
      }

      if (isAndroid) {
        go(intentUrl);
      } else {
        // iOS / desktop: try custom scheme, then Play Store.
        go(deepLink);
        setTimeout(function () {
          go(playStore);
        }, 1800);
      }
    })();
  </script>
</body>
</html>
