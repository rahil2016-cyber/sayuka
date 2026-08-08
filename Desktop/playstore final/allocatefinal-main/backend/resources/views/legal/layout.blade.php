<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>{{ $title }} - JobAllocate</title>
    <style>
        * { box-sizing: border-box; }
        body {
            margin: 0;
            font-family: Arial, Helvetica, sans-serif;
            color: #0f172a;
            background: #f8fafc;
            line-height: 1.65;
        }
        .wrap { max-width: 900px; margin: 0 auto; padding: 28px 16px 56px; }
        .header {
            display: flex; flex-wrap: wrap; gap: 12px; align-items: center;
            justify-content: space-between; background: #fff; border: 1px solid #e2e8f0;
            border-radius: 14px; padding: 16px 18px; margin-bottom: 16px;
        }
        .brand { font-weight: 800; font-size: 20px; color: #0f172a; text-decoration: none; }
        .chip {
            display: inline-block; background: #eff6ff; color: #1d4ed8;
            font-size: 12px; font-weight: 700; padding: 4px 10px; border-radius: 999px;
            margin-bottom: 10px;
        }
        .card {
            background: #fff; border: 1px solid #e2e8f0; border-radius: 14px;
            padding: 22px 20px;
        }
        h1 { margin: 0 0 8px; font-size: 28px; line-height: 1.25; }
        .meta { color: #64748b; font-size: 13px; font-weight: 600; margin-bottom: 20px; }
        h2 { font-size: 17px; margin: 22px 0 8px; }
        p, li { font-size: 14px; color: #334155; }
        ul { padding-left: 20px; }
        a { color: #2563eb; }
        .home {
            display: inline-block; background: #2563eb; color: #fff !important;
            text-decoration: none; font-weight: 700; font-size: 13px;
            padding: 10px 14px; border-radius: 10px;
        }
    </style>
</head>
<body>
    <div class="wrap">
        <div class="header">
            <a class="brand" href="https://joballocate.tech">JobAllocate</a>
            <a class="home" href="https://joballocate.tech">Back to Home</a>
        </div>
        <div class="card">
            <div class="chip">{{ $badge }}</div>
            <h1>{{ $title }}</h1>
            <p class="meta">{{ $meta }}</p>
            @yield('content')
        </div>
    </div>
</body>
</html>
