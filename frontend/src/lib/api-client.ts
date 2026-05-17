import { getAccessToken } from "@/features/auth/store/authStore";

const API_BASE_URL = process.env.NEXT_PUBLIC_API_URL ?? "http://localhost:8081";

function headers(): Record<string, string> {
  const h: Record<string, string> = { "Content-Type": "application/json" };
  const token = getAccessToken();
  if (token) h.Authorization = `Bearer ${token}`;
  return h;
}

function snakeToCamel(s: string): string {
  return s.replace(/_([a-z])/g, (_, c) => c.toUpperCase());
}

function camelizeKeys(obj: unknown): unknown {
  if (Array.isArray(obj)) return obj.map(camelizeKeys);
  if (obj !== null && typeof obj === "object") {
    return Object.fromEntries(
      Object.entries(obj as Record<string, unknown>).map(([k, v]) => [
        snakeToCamel(k),
        camelizeKeys(v),
      ])
    );
  }
  return obj;
}

function snakelizeKeys(obj: unknown): unknown {
  if (Array.isArray(obj)) return obj.map(snakelizeKeys);
  if (obj !== null && typeof obj === "object") {
    return Object.fromEntries(
      Object.entries(obj as Record<string, unknown>).map(([k, v]) => [
        k.replace(/([A-Z])/g, "_$1").toLowerCase(),
        snakelizeKeys(v),
      ])
    );
  }
  return obj;
}

async function handleResponse<T>(res: Response): Promise<T> {
  if (!res.ok) {
    let detail: string = res.statusText;
    try {
      const j = await res.json();
      // FastAPI 응답: { detail: "..." } 또는 검증 오류 배열
      if (typeof j?.detail === "string") detail = j.detail;
      else if (Array.isArray(j?.detail) && j.detail[0]?.msg) detail = j.detail[0].msg;
      else detail = JSON.stringify(j);
    } catch {
      try {
        detail = await res.text();
      } catch {
        // keep statusText
      }
    }
    throw new Error(detail || `HTTP ${res.status}`);
  }
  if (res.status === 204) return undefined as T;
  const json = await res.json();
  return camelizeKeys(json) as T;
}

function toBody(body: unknown): string | undefined {
  if (body === undefined) return undefined;
  return JSON.stringify(snakelizeKeys(body));
}

export const apiClient = {
  get<T>(path: string): Promise<T> {
    return fetch(`${API_BASE_URL}${path}`, { headers: headers() }).then((r) => handleResponse<T>(r));
  },

  post<T>(path: string, body?: unknown): Promise<T> {
    return fetch(`${API_BASE_URL}${path}`, {
      method: "POST",
      headers: headers(),
      body: toBody(body),
    }).then((r) => handleResponse<T>(r));
  },

  put<T>(path: string, body?: unknown): Promise<T> {
    return fetch(`${API_BASE_URL}${path}`, {
      method: "PUT",
      headers: headers(),
      body: toBody(body),
    }).then((r) => handleResponse<T>(r));
  },

  patch<T>(path: string, body?: unknown): Promise<T> {
    return fetch(`${API_BASE_URL}${path}`, {
      method: "PATCH",
      headers: headers(),
      body: toBody(body),
    }).then((r) => handleResponse<T>(r));
  },

  delete<T>(path: string): Promise<T> {
    return fetch(`${API_BASE_URL}${path}`, {
      method: "DELETE",
      headers: headers(),
    }).then((r) => handleResponse<T>(r));
  },
};
