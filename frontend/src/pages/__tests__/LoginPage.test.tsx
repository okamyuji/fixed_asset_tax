import { render, screen, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { BrowserRouter } from 'react-router-dom';
import { beforeEach, describe, expect, it, vi } from 'vitest';
import { authApi } from '../../api/auth';
import { LoginPage } from '../LoginPage';

vi.mock('../../api/auth');
vi.mock('react-router-dom', async () => {
    const actual = await vi.importActual('react-router-dom');
    return {
        ...actual,
        useNavigate: () => vi.fn(),
    };
});

describe('LoginPage', () => {
    beforeEach(() => {
        vi.clearAllMocks();
    });

    it('renders login form', () => {
        render(
            <BrowserRouter>
                <LoginPage />
            </BrowserRouter>
        );

        expect(screen.getByText('固定資産税計算システム')).toBeInTheDocument();
        expect(screen.getByPlaceholderText('your@email.com')).toBeInTheDocument();
        expect(screen.getByPlaceholderText('パスワードを入力')).toBeInTheDocument();
        expect(screen.getByRole('button', { name: 'ログイン' })).toBeInTheDocument();
    });

    it('shows validation errors for empty fields', async () => {
        const user = userEvent.setup();
        render(
            <BrowserRouter>
                <LoginPage />
            </BrowserRouter>
        );

        const submitButton = screen.getByRole('button', { name: 'ログイン' });
        await user.click(submitButton);

        await waitFor(() => {
            expect(screen.getByText('有効なメールアドレスを入力してください')).toBeInTheDocument();
            expect(screen.getByText('パスワードを入力してください')).toBeInTheDocument();
        });
    });

    it('calls login API with correct credentials', async () => {
        const user = userEvent.setup();
        const mockLogin = vi.mocked(authApi.login);
        mockLogin.mockResolvedValue({ token: 'test-token' });

        render(
            <BrowserRouter>
                <LoginPage />
            </BrowserRouter>
        );

        const emailInput = screen.getByPlaceholderText('your@email.com');
        const passwordInput = screen.getByPlaceholderText('パスワードを入力');
        const submitButton = screen.getByRole('button', { name: 'ログイン' });

        await user.type(emailInput, 'test@example.com');
        await user.type(passwordInput, 'password123');
        await user.click(submitButton);

        await waitFor(() => {
            expect(mockLogin).toHaveBeenCalledWith({
                email: 'test@example.com',
                password: 'password123',
            });
        });
    });

    it('shows error message on login failure', async () => {
        const user = userEvent.setup();
        const mockLogin = vi.mocked(authApi.login);
        mockLogin.mockRejectedValue(new Error('Login failed'));

        render(
            <BrowserRouter>
                <LoginPage />
            </BrowserRouter>
        );

        const emailInput = screen.getByPlaceholderText('your@email.com');
        const passwordInput = screen.getByPlaceholderText('パスワードを入力');
        const submitButton = screen.getByRole('button', { name: 'ログイン' });

        await user.type(emailInput, 'test@example.com');
        await user.type(passwordInput, 'wrong-password');
        await user.click(submitButton);

        await waitFor(() => {
            expect(screen.getByText(/ログインに失敗しました/)).toBeInTheDocument();
        });
    });
});
