/**
 * api.js — Shared API utility for QR Attendance System
 * Loaded via <script src="/api.js"></script> on every page.
 * Exposes a global `window.API` object.
 */

const API_BASE = '/api/v1';

/* ─── Token helpers ─────────────────────────────────────────────────────── */

function getToken() {
  return localStorage.getItem('access_token');
}

function getRefreshToken() {
  return localStorage.getItem('refresh_token');
}

function setTokens(access, refresh) {
  localStorage.setItem('access_token', access);
  if (refresh !== undefined) {
    localStorage.setItem('refresh_token', refresh);
  }
}

function clearTokens() {
  localStorage.removeItem('access_token');
  localStorage.removeItem('refresh_token');
  localStorage.removeItem('current_user');
}

/* ─── Token refresh ─────────────────────────────────────────────────────── */

let _refreshPromise = null;

async function refreshAccessToken() {
  if (_refreshPromise) return _refreshPromise;

  _refreshPromise = (async () => {
    const refresh = getRefreshToken();
    if (!refresh) throw new Error('No refresh token');

    const res = await fetch(`${API_BASE}/auth/refresh/`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ refresh }),
    });

    if (!res.ok) throw new Error('Refresh failed');

    const data = await res.json();
    setTokens(data.access);
    return data.access;
  })();

  _refreshPromise.finally(() => { _refreshPromise = null; });
  return _refreshPromise;
}

/* ─── Core fetch wrapper ────────────────────────────────────────────────── */

async function apiFetch(path, options = {}) {
  const url = path.startsWith('http') ? path : `${API_BASE}${path}`;

  const makeRequest = async (token) => {
    const headers = {
      'Content-Type': 'application/json',
      ...(options.headers || {}),
    };
    if (token) headers['Authorization'] = `Bearer ${token}`;

    // Allow overriding Content-Type (e.g. for FormData)
    if (options.body instanceof FormData) {
      delete headers['Content-Type'];
    }

    return fetch(url, { ...options, headers });
  };

  let token = getToken();
  let res = await makeRequest(token);

  // 401 → try refresh once, then redirect
  if (res.status === 401) {
    try {
      token = await refreshAccessToken();
      res = await makeRequest(token);
    } catch {
      clearTokens();
      window.location.href = '/login/';
      throw new Error('Unauthenticated');
    }
    if (res.status === 401) {
      clearTokens();
      window.location.href = '/login/';
      throw new Error('Unauthenticated');
    }
  }

  if (!res.ok) {
    let errMsg = `HTTP ${res.status}`;
    try {
      const errData = await res.json();
      errMsg = errData.detail || errData.message || JSON.stringify(errData);
    } catch {}
    throw new Error(errMsg);
  }

  // 204 No Content
  if (res.status === 204) return null;

  const contentType = res.headers.get('Content-Type') || '';
  if (contentType.includes('application/json')) {
    return res.json();
  }
  return res.blob();
}

/* ─── Auth helpers ──────────────────────────────────────────────────────── */

async function login(email, password) {
  const res = await fetch(`${API_BASE}/auth/login/`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ email, password }),
  });

  if (!res.ok) {
    let msg = 'Login failed';
    try {
      const d = await res.json();
      msg = d.detail || d.message || msg;
    } catch {}
    throw new Error(msg);
  }

  const data = await res.json();
  setTokens(data.access, data.refresh);
  localStorage.setItem('current_user', JSON.stringify(data.user));
  return data;
}

function getEffectiveRole(user) {
  return user?.active_role || user?.role;
}

async function switchRole(role) {
  const data = await apiFetch('/auth/switch-role/', {
    method: 'POST',
    body: JSON.stringify({ role }),
  });
  setTokens(data.access, data.refresh);
  localStorage.setItem('current_user', JSON.stringify(data.user));
  return data;
}

function canSwitchRoles(user) {
  const roles = user?.available_roles;
  return Array.isArray(roles) && roles.includes('admin') && roles.includes('teacher');
}

async function bindRoleSwitch(buttonId, targetRole, redirectPath) {
  const btn = document.getElementById(buttonId);
  if (!btn) return;

  let user;
  try {
    user = await apiFetch('/auth/me/');
    localStorage.setItem('current_user', JSON.stringify(user));
  } catch {
    btn.hidden = true;
    return;
  }

  if (!canSwitchRoles(user)) {
    btn.hidden = true;
    return;
  }

  btn.hidden = false;
  btn.addEventListener('click', async () => {
    if (btn.disabled) return;
    btn.disabled = true;
    const label = btn.querySelector('.role-switch-label');
    const original = label ? label.textContent : '';
    if (label) label.textContent = 'Changement…';
    try {
      await switchRole(targetRole);
      window.location.href = redirectPath;
    } catch (err) {
      btn.disabled = false;
      if (label) label.textContent = original;
      alert(err.message || 'Impossible de changer de rôle.');
    }
  });
}

async function getMe() {
  const cached = localStorage.getItem('current_user');
  if (cached) {
    try { return JSON.parse(cached); } catch {}
  }
  const user = await apiFetch('/auth/me/');
  localStorage.setItem('current_user', JSON.stringify(user));
  return user;
}

function logout() {
  clearTokens();
  window.location.href = '/login/';
}

/* ─── Auth guard ────────────────────────────────────────────────────────── */

/**
 * Call at the top of any protected page.
 * @param {string|string[]} [allowedRoles] — if provided, redirect if role not in list
 * @returns {Promise<object>} the current user object
 */
async function requireAuth(allowedRoles) {
  if (!getToken()) {
    window.location.href = '/login/';
    throw new Error('No token');
  }
  try {
    const user = await getMe();
    if (allowedRoles) {
      const roles = Array.isArray(allowedRoles) ? allowedRoles : [allowedRoles];
      const effectiveRole = getEffectiveRole(user);
      if (!roles.includes(effectiveRole)) {
        window.location.href = '/login/';
        throw new Error('Forbidden');
      }
    }
    return user;
  } catch (e) {
    if (e.message === 'Forbidden') throw e;
    window.location.href = '/login/';
    throw e;
  }
}

/* ─── WebSocket helpers ─────────────────────────────────────────────────── */

function getWsBase() {
  const proto = window.location.protocol === 'https:' ? 'wss:' : 'ws:';
  return `${proto}//${window.location.host}`;
}

function connectAttendanceWs(path, onMessage, onStatus) {
  const ws = new WebSocket(`${getWsBase()}${path}`);

  ws.onopen = () => onStatus?.('connected');
  ws.onerror = () => onStatus?.('error');
  ws.onclose = () => onStatus?.('disconnected');
  ws.onmessage = (event) => {
    try {
      const data = JSON.parse(event.data);
      const record = data.data || data;
      if (record && record.id) onMessage(record);
    } catch {}
  };

  return ws;
}

function formatDateTime(value) {
  if (!value) return '—';
  const d = new Date(value);
  if (Number.isNaN(d.getTime())) return '—';
  return d.toLocaleString(undefined, {
    month: 'short',
    day: 'numeric',
    hour: '2-digit',
    minute: '2-digit',
    second: '2-digit',
  });
}

function formatDate(value) {
  if (!value) return '—';
  const d = new Date(value);
  if (Number.isNaN(d.getTime())) return value;
  return d.toLocaleDateString(undefined, {
    year: 'numeric',
    month: 'short',
    day: 'numeric',
  });
}

function esc(str) {
  if (str === null || str === undefined) return '';
  return String(str)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;');
}

/* ─── Expose global window.API ──────────────────────────────────────────── */

window.API = {
  BASE: API_BASE,
  getToken,
  getRefreshToken,
  setTokens,
  clearTokens,
  apiFetch,
  login,
  getMe,
  getEffectiveRole,
  canSwitchRoles,
  switchRole,
  bindRoleSwitch,
  logout,
  requireAuth,
  getWsBase,
  connectAttendanceWs,
  formatDateTime,
  formatDate,
  esc,
};
