"use client";
import { useEffect } from "react";
import { useParams } from "next/navigation";

const PLAY_STORE =
  "https://play.google.com/store/apps/details?id=com.joballocate.in";

export default function ShareRedirect() {
  const params = useParams();
  const id = params.id;

  useEffect(() => {
    if (!id) return;

    // No package= — opens whichever build handles joballocate://job
    const intentUrl =
      `intent://job/${id}#Intent;scheme=joballocate;` +
      `S.browser_fallback_url=${encodeURIComponent(PLAY_STORE)};end`;

    const isAndroid = /Android/i.test(navigator.userAgent);
    if (isAndroid) {
      window.location.href = intentUrl;
      return;
    }

    window.location.href = `joballocate://job/${id}`;
    const timeout = setTimeout(() => {
      window.location.href = PLAY_STORE;
    }, 1800);

    return () => clearTimeout(timeout);
  }, [id]);

  return (
    <div
      style={{
        display: "flex",
        flexDirection: "column",
        height: "100vh",
        justifyContent: "center",
        alignItems: "center",
        fontFamily: "sans-serif",
        backgroundColor: "#f8fafc",
        color: "#0f172a",
        textAlign: "center",
        padding: 24,
      }}
    >
      <h2 style={{ margin: 0 }}>JobAllocate</h2>
      <p style={{ marginTop: 12, color: "#475569" }}>Opening the app…</p>
      <p style={{ fontSize: 12, color: "#64748b", marginTop: 8 }}>
        If nothing happens, you will be redirected to the Play Store.
      </p>
      <p style={{ marginTop: 20 }}>
        <a
          href={PLAY_STORE}
          style={{
            color: "#174a7e",
            fontWeight: 700,
            textDecoration: "none",
          }}
        >
          Get the app on Play Store
        </a>
      </p>
    </div>
  );
}
