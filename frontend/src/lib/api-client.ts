const API_BASE_URL = process.env.NEXT_PUBLIC_API_URL ?? "http://localhost:8000";

async function handleResponse<T>(res: Response): Promise<T> {
  if (!res.ok) {
    const text = await res.text().catch(() => res.statusText);
    throw new Error(text || `HTTP ${res.status}`);
  }
  if (res.status === 204) return undefined as T;
  return res.json();
}

export const apiClient = {
  get<T>(path: string): Promise<T> {
    return fetch(`${API_BASE_URL}${path}`, {
      headers: { "Content-Type": "application/json" },
    }).then((r) => handleResponse<T>(r));
  },

  post<T>(path: string, body?: unknown): Promise<T> {
    return fetch(`${API_BASE_URL}${path}`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: body !== undefined ? JSON.stringify(body) : undefined,
    }).then((r) => handleResponse<T>(r));
  },

  put<T>(path: string, body?: unknown): Promise<T> {
    return fetch(`${API_BASE_URL}${path}`, {
      method: "PUT",
      headers: { "Content-Type": "application/json" },
      body: body !== undefined ? JSON.stringify(body) : undefined,
    }).then((r) => handleResponse<T>(r));
  },

  delete<T>(path: string): Promise<T> {
    return fetch(`${API_BASE_URL}${path}`, {
      method: "DELETE",
      headers: { "Content-Type": "application/json" },
    }).then((r) => handleResponse<T>(r));
  },
};
