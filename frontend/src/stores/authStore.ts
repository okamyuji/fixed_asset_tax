import { create } from 'zustand';
import { persist } from 'zustand/middleware';

interface AuthState {
  token: string | null;
  tenantId: string | null;
  isAuthenticated: boolean;
  setAuth: (token: string, tenantId: string) => void;
  clearAuth: () => void;
}

export const useAuthStore = create<AuthState>()(
  persist(
    (set) => ({
      token: null,
      tenantId: null,
      isAuthenticated: false,
      setAuth: (token, tenantId) => {
        localStorage.setItem('token', token);
        localStorage.setItem('tenantId', tenantId);
        set({ token, tenantId, isAuthenticated: true });
      },
      clearAuth: () => {
        localStorage.removeItem('token');
        localStorage.removeItem('tenantId');
        set({ token: null, tenantId: null, isAuthenticated: false });
      },
    }),
    {
      name: 'auth-storage',
    }
  )
);
